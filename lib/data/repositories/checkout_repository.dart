import 'dart:async';
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
    String section = 'store',
    double? mixedWalletAmount,
    double? mixedCashAmount,
    double? mixedUpiAmount,
    double? mixedDebtAmount,
    String? debtorName, // For external debtors
  }) async {
    late StoreTransaction savedTransaction;

    // Resolve external debtor reference before transaction if needed
    DocumentReference? externalDebtorRef;
    bool isNewExternal = false;

    if (studentId == null && debtorName != null && debtorName.trim().isNotEmpty) {
      final query = await _firestore
          .collection(AppConstants.externalDebtorsCollection)
          .where('name', isEqualTo: debtorName.trim())
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        externalDebtorRef = query.docs.first.reference;
      } else {
        externalDebtorRef = _firestore.collection(AppConstants.externalDebtorsCollection).doc();
        isNewExternal = true;
      }
    }

    await _firestore.runTransaction((tx) async {
      double walletDeducted = 0;
      double cashAmount = cartTotal;
      double upiAmount = 0;
      double debtAmount = 0;

      // 1. PERFORM ALL READS IN PARALLEL FOR SPEED
      DocumentSnapshot? studentDoc;
      DocumentReference? studentRef;
      DocumentSnapshot? ecDoc;

      // Build all product refs up front
      final productRefs = <CartItem, DocumentReference>{};
      for (final item in cartItems) {
        productRefs[item] = _firestore
            .collection(AppConstants.productsCollection)
            .doc(item.productId);
      }

      // Fire all reads concurrently
      final readFutures = <Future<DocumentSnapshot>>[];

      Future<DocumentSnapshot>? studentReadFuture;
      Future<DocumentSnapshot>? ecReadFuture;

      if (studentId != null) {
        studentRef = _firestore
            .collection(AppConstants.studentsCollection)
            .doc(studentId);
        studentReadFuture = tx.get(studentRef);
        readFutures.add(studentReadFuture);
      } else if (externalDebtorRef != null && !isNewExternal) {
        ecReadFuture = tx.get(externalDebtorRef);
        readFutures.add(ecReadFuture);
      }

      final productReadFutures = <CartItem, Future<DocumentSnapshot>>{};
      for (final item in cartItems) {
        final f = tx.get(productRefs[item]!);
        productReadFutures[item] = f;
        readFutures.add(f);
      }

      // Await all reads at once
      await Future.wait(readFutures);

      if (studentReadFuture != null) {
        studentDoc = await studentReadFuture;
        if (!studentDoc.exists) throw Exception('Student not found');
      }
      if (ecReadFuture != null) {
        ecDoc = await ecReadFuture;
      }

      final productDocs = <CartItem, DocumentSnapshot>{};
      for (final item in cartItems) {
        productDocs[item] = await productReadFutures[item]!;
      }

      // 2. COMPUTE AND PERFORM WRITES
      if (paymentMode == AppConstants.paymentUpi) {
        upiAmount = cartTotal;
        cashAmount = 0;
      } else if (paymentMode == AppConstants.paymentDebt) {
        debtAmount = cartTotal;
        cashAmount = 0;

        // Update student's debt in Firestore
        if (studentDoc != null && studentRef != null) {
          final data = studentDoc.data() as Map<String, dynamic>;
          final currentDebt = (data['debt'] ?? 0).toDouble();
          tx.update(studentRef, {
            'debt': currentDebt + debtAmount,
            'updated_at': FieldValue.serverTimestamp(),
          });
        }
        // Handle external debtor — debt write happens in the shared block below (line ~178)
      } else if (paymentMode == AppConstants.paymentWallet && studentDoc != null && studentRef != null) {
        final data = studentDoc.data() as Map<String, dynamic>;
        final currentBalance = (data['balance'] ?? 0).toDouble();
        final currentDebt = (data['debt'] ?? 0).toDouble();

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
        walletDeducted = mixedWalletAmount ?? 0.0;
        cashAmount = mixedCashAmount ?? 0.0;
        upiAmount = mixedUpiAmount ?? 0.0;
        debtAmount = mixedDebtAmount ?? 0.0;

        if (studentDoc != null && studentRef != null) {
          final data = studentDoc.data() as Map<String, dynamic>;
          final currentBalance = (data['balance'] ?? 0).toDouble();
          final currentDebt = (data['debt'] ?? 0).toDouble();

          if (walletDeducted > currentBalance) {
            throw Exception('Wallet deduction exceeds current balance.');
          }

          // In mixed mode, debt amount comes directly from user input.
          // We adjust the cart difference as needed.
          final sum = walletDeducted + cashAmount + upiAmount + debtAmount;
          if (sum < cartTotal) {
            // Uncovered portion falls into debt automatically if appropriate, 
            // but mixed mode expects user to balance it out. We enforce the fallback:
            debtAmount += (cartTotal - sum);
          }

          if (walletDeducted > 0 || debtAmount > 0) {
            tx.update(studentRef, {
              'balance': currentBalance - walletDeducted,
              'debt': currentDebt + debtAmount,
              'updated_at': FieldValue.serverTimestamp(),
            });
          }
        } else {
          // Mixed mode without student
          final sum = cashAmount + upiAmount + debtAmount;
          if (sum < cartTotal) {
            debtAmount += (cartTotal - sum);
          }
        }
      }

      // Handle External Debtor Write
      if (debtAmount > 0 && externalDebtorRef != null && debtorName != null) {
        if (isNewExternal || ecDoc == null || !ecDoc.exists) {
          tx.set(externalDebtorRef, {
            'name': debtorName.trim(),
            'debt': debtAmount,
            'search_terms': _generateSearchTerms(debtorName.trim()),
            'updated_at': FieldValue.serverTimestamp(),
          });
        } else {
          final ecData = ecDoc.data() as Map<String, dynamic>;
          final currentEcDebt = (ecData['debt'] ?? 0).toDouble();
          tx.update(externalDebtorRef, {
            'debt': currentEcDebt + debtAmount,
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
        paidAmount: walletDeducted + cashAmount + upiAmount,
        walletAmount: walletDeducted,
        cashAmount: cashAmount,
        upiAmount: upiAmount,
        debtAmount: debtAmount,
        section: section,
        studentId: studentId,
        studentName: studentName ?? debtorName,
        createdAt: DateTime.now(), // will be overwritten by serverTimestamp in toFirestore
      );

      savedTransaction = transaction;
      tx.set(txnRef, transaction.toFirestore());

      // 4. Log Audit inside the core logic, although we do it after
    });

    // Fire-and-forget audit — do NOT await, so UI unblocks immediately
    unawaited(AuditRepository(firestore: _firestore).log(
      action: AppConstants.auditSale,
      description: 'Sale: $receiptId — ${CurrencyFormatter.format(cartTotal)} ($paymentMode)',
      metadata: {
        'receipt_id': receiptId,
        'total': cartTotal,
        'payment_mode': paymentMode,
      },
    ));

    return savedTransaction;
  }

  List<String> _generateSearchTerms(String name) {
    final words = name.toLowerCase().trim().split(RegExp(r'\s+'));
    final terms = <String>{};
    for (final word in words) {
      for (int i = 1; i <= word.length; i++) {
        terms.add(word.substring(0, i));
      }
    }
    return terms.toList()..sort();
  }
}
