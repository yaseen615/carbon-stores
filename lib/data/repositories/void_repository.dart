import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../models/transaction_model.dart';
import '../models/cart_item_model.dart';
import 'audit_repository.dart';

class VoidRepository {
  final FirebaseFirestore _firestore;

  VoidRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Voids a transaction:
  /// 1. Reverses wallet deduction (if paid via wallet)
  /// 2. Reverses stock changes (adds stock back)
  /// 3. Marks transaction as voided
  Future<void> voidTransaction(StoreTransaction transaction, String reason) async {
    await _firestore.runTransaction((tx) async {
      // H4 FIX: Re-read transaction inside Firestore transaction to prevent double-void
      final txnRef = _firestore.collection(AppConstants.transactionsCollection).doc(transaction.id);
      final freshTxnDoc = await tx.get(txnRef);
      if (!freshTxnDoc.exists) throw Exception('Transaction not found');
      final freshData = freshTxnDoc.data() as Map<String, dynamic>;
      if (freshData['is_voided'] == true) {
        throw Exception('Transaction is already voided');
      }
      
      // 1. PERFORM ALL READS FIRST
      DocumentSnapshot? studentDoc;
      DocumentReference? studentRef;
      
      if (transaction.studentId != null) {
        studentRef = _firestore.collection(AppConstants.studentsCollection).doc(transaction.studentId);
        studentDoc = await tx.get(studentRef);
      }

      // Read external debtor doc if applicable (non-student debt)
      DocumentSnapshot? externalDebtorDoc;
      DocumentReference? externalDebtorRef;
      if (transaction.studentId == null &&
          transaction.debtAmount > 0 &&
          transaction.studentName != null &&
          transaction.studentName!.isNotEmpty) {
        final ecQuery = await _firestore
            .collection(AppConstants.externalDebtorsCollection)
            .where('name', isEqualTo: transaction.studentName!.trim())
            .limit(1)
            .get();
        if (ecQuery.docs.isNotEmpty) {
          externalDebtorRef = ecQuery.docs.first.reference;
          externalDebtorDoc = await tx.get(externalDebtorRef);
        }
      }

      final productRefs = <CartItem, DocumentReference>{};
      final productDocs = <CartItem, DocumentSnapshot>{};
      
      for (final item in transaction.items) {
        final ref = _firestore.collection(AppConstants.productsCollection).doc(item.productId);
        productRefs[item] = ref;
        productDocs[item] = await tx.get(ref);
      }

      // 2. MARK TRANSACTION AS VOIDED
      tx.update(txnRef, {
        'is_voided': true,
        'voided_at': FieldValue.serverTimestamp(),
        'void_reason': reason,
      });

      // 3. REVERSE WALLET AND DEBT (Student)
      double walletDeducted = transaction.walletAmount;
      if (studentDoc != null && studentDoc.exists && studentRef != null) {
        if (walletDeducted > 0 || transaction.debtAmount > 0) {
           final data = studentDoc.data() as Map<String, dynamic>;
           final currentBalance = (data['balance'] ?? 0).toDouble();
           final currentDebt = (data['debt'] ?? 0).toDouble();
           
           double newBalance = currentBalance + walletDeducted;
           double newDebt = currentDebt - transaction.debtAmount;
           if (newDebt < 0) newDebt = 0;

           tx.update(studentRef, {
             'balance': newBalance,
             'debt': newDebt,
             'updated_at': FieldValue.serverTimestamp(),
           });
        }
      }

      // 3b. REVERSE EXTERNAL DEBTOR DEBT
      if (externalDebtorDoc != null && externalDebtorDoc.exists && externalDebtorRef != null) {
        final ecData = externalDebtorDoc.data() as Map<String, dynamic>;
        final currentEcDebt = (ecData['debt'] ?? 0).toDouble();
        double newEcDebt = currentEcDebt - transaction.debtAmount;
        if (newEcDebt < 0) newEcDebt = 0;
        tx.update(externalDebtorRef, {
          'debt': newEcDebt,
          'updated_at': FieldValue.serverTimestamp(),
        });
      }

      // 4. REVERSE STOCK CHANGES
      for (final item in transaction.items) {
        final doc = productDocs[item]!;
        final ref = productRefs[item]!;
        
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          final currentStock = data['stock'] as int;
          final currentSales = (data['sales'] ?? 0) as int;
          
          tx.update(ref, {
            'stock': currentStock + item.quantity,
            'sales': (currentSales - item.quantity) < 0 ? 0 : currentSales - item.quantity,
            'updated_at': FieldValue.serverTimestamp(),
          });
        }
      }
    });

    // Log the void
    await AuditRepository(firestore: _firestore).log(
      action: 'void',
      description: 'Voided transaction ${transaction.receiptId}. Reason: $reason',
      metadata: {
        'transaction_id': transaction.id,
        'receipt_id': transaction.receiptId,
      },
    );
  }
}
