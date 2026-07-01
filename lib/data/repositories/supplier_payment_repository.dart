import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/supplier_payment_model.dart';
import '../../core/constants/app_constants.dart';

class SupplierPaymentRepository {
  final CollectionReference _collection;

  SupplierPaymentRepository({FirebaseFirestore? firestore})
      : _collection = (firestore ?? FirebaseFirestore.instance).collection(AppConstants.supplierPaymentsCollection);

  /// Stream payments for a specific supplier
  Stream<List<SupplierPayment>> getPaymentsForSupplier(String supplierId) {
    return _collection
        .where('supplier_id', isEqualTo: supplierId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map(SupplierPayment.fromFirestore).toList();
    });
  }
  
  /// Stream all payments within a date range (useful for Accounts summary)
  Stream<List<SupplierPayment>> getPaymentsByDateRange(DateTime start, DateTime end) {
    return _collection
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map(SupplierPayment.fromFirestore).toList();
    });
  }

  /// Add a new supplier payment
  Future<String> addPayment(SupplierPayment payment) async {
    final doc = await _collection.add(payment.toFirestore());
    return doc.id;
  }
}
