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
    if (transaction.isVoided) {
      throw Exception('Transaction is already voided');
    }

    await _firestore.runTransaction((tx) async {
      final txnRef = _firestore.collection(AppConstants.transactionsCollection).doc(transaction.id);
      
      // 1. PERFORM ALL READS FIRST
      DocumentSnapshot? studentDoc;
      DocumentReference? studentRef;
      
      if (transaction.studentId != null) {
        studentRef = _firestore.collection(AppConstants.studentsCollection).doc(transaction.studentId);
        studentDoc = await tx.get(studentRef);
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

      // 3. REVERSE WALLET AND DEBT
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
