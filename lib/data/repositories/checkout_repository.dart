import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/constants/app_constants.dart';
import '../models/transaction_model.dart';
import '../models/cart_item_model.dart';
import 'audit_repository.dart';

class CheckoutRepository {
  final FirebaseFirestore _firestore;

  CheckoutRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<StoreTransaction> processCheckout({
    required List<CartItem> cartItems,
    required double cartTotal,
    required String paymentMode,
    required String receiptId,
    String? studentId,
    String? studentName,
    required String userId, // For audit
    double? mixedWalletAmount,
    double? mixedCashAmount,
  }) async {
    late StoreTransaction savedTransaction;

    await _firestore.runTransaction((tx) async {
      double walletDeducted = 0;
      double cashAmount = cartTotal;
      double debtAmount = 0;

      // 1. PERFORM ALL READS FIRST
      DocumentSnapshot? studentDoc;
      DocumentReference? studentRef;
      
      if (paymentMode != AppConstants.paymentCash && studentId != null) {
        studentRef = _firestore.collection(AppConstants.studentsCollection).doc(studentId);
        studentDoc = await tx.get(studentRef);

        if (!studentDoc.exists) {
          throw Exception('Student not found');
        }
      }

      final productRefs = <CartItem, DocumentReference>{};
      final productDocs = <CartItem, DocumentSnapshot>{};
      
      for (final item in cartItems) {
        final ref = _firestore.collection(AppConstants.productsCollection).doc(item.productId);
        productRefs[item] = ref;
        productDocs[item] = await tx.get(ref);
      }

      // 2. COMPUTE AND PERFORM WRITES
      if (studentDoc != null && studentRef != null) {
        final data = studentDoc.data() as Map<String, dynamic>;
        final currentBalance = (data['balance'] ?? 0).toDouble();
        final currentDebt = (data['debt'] ?? 0).toDouble();

        if (paymentMode == AppConstants.paymentWallet) {
          if (currentBalance >= cartTotal) {
            walletDeducted = cartTotal;
            tx.update(studentRef, {
              'balance': currentBalance - cartTotal,
              'updated_at': FieldValue.serverTimestamp(),
            });
          } else {
            walletDeducted = currentBalance;
            debtAmount = cartTotal - currentBalance;
            tx.update(studentRef, {
              'balance': 0.0,
              'debt': currentDebt + debtAmount,
              'updated_at': FieldValue.serverTimestamp(),
            });
          }
          cashAmount = 0;
        } else if (paymentMode == AppConstants.paymentMixed) {
          // Explicit mixed amounts provided by user input
          walletDeducted = mixedWalletAmount ?? 0.0;
          cashAmount = mixedCashAmount ?? 0.0;
          
          if (walletDeducted > currentBalance) {
            throw Exception('Wallet deduction exceeds current balance.');
          }

          debtAmount = cartTotal - (walletDeducted + cashAmount);
          if (debtAmount < 0) debtAmount = 0; // Negative debt not allowed, would signify change given.

          tx.update(studentRef, {
            'balance': currentBalance - walletDeducted,
            'debt': currentDebt + debtAmount,
            'updated_at': FieldValue.serverTimestamp(),
          });
        }
      }

      for (final item in cartItems) {
        final doc = productDocs[item]!;
        final ref = productRefs[item]!;
        
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          final currentStock = data['stock'] as int;
          final currentSales = (data['sales'] ?? 0) as int;

          tx.update(ref, {
            'stock': currentStock - item.quantity,
            'sales': currentSales + item.quantity,
            'updated_at': FieldValue.serverTimestamp(),
          });
        }
      }

      // 3. Create Transaction Record
      final txnRef = _firestore.collection(AppConstants.transactionsCollection).doc();
      final transaction = StoreTransaction(
        id: txnRef.id,
        receiptId: receiptId,
        items: cartItems,
        totalAmount: cartTotal,
        paymentMode: paymentMode,
        paidAmount: walletDeducted + cashAmount,
        walletAmount: walletDeducted,
        cashAmount: cashAmount,
        debtAmount: debtAmount,
        studentId: studentId,
        studentName: studentName,
        createdAt: DateTime.now(), // will be overwritten by serverTimestamp in toFirestore
      );

      savedTransaction = transaction;
      tx.set(txnRef, transaction.toFirestore());

      // 4. Log Audit inside the core logic, although we do it after
    });

    // Fire-and-forget audit
    await AuditRepository(firestore: _firestore).log(
      action: AppConstants.auditSale,
      description: 'Sale: $receiptId — ${CurrencyFormatter.format(cartTotal)} ($paymentMode)',
      metadata: {
        'receipt_id': receiptId,
        'total': cartTotal,
        'payment_mode': paymentMode,
      },
    );

    return savedTransaction;
  }
}
