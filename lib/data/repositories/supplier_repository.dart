import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/supplier_model.dart';
import '../../core/constants/app_constants.dart';

class SupplierRepository {
  final FirebaseFirestore _firestore;
  final CollectionReference _collection;

  SupplierRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _collection = (firestore ?? FirebaseFirestore.instance).collection(AppConstants.suppliersCollection);

  /// Stream all suppliers ordered by name
  Stream<List<Supplier>> getSuppliers() {
    return _collection.orderBy('name').snapshots().map((snapshot) {
      return snapshot.docs.map(Supplier.fromFirestore).toList();
    });
  }

  /// Get a single supplier
  Future<Supplier?> getSupplier(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return Supplier.fromFirestore(doc);
  }

  /// Stream a single supplier
  Stream<Supplier?> getSupplierStream(String id) {
    return _collection.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Supplier.fromFirestore(doc);
    });
  }

  /// Add a new supplier
  Future<String> addSupplier(Supplier supplier) async {
    final doc = await _collection.add(supplier.toFirestore());
    return doc.id;
  }

  /// Update a supplier
  Future<void> updateSupplier(String id, Map<String, dynamic> data) async {
    data['updated_at'] = FieldValue.serverTimestamp();
    await _collection.doc(id).update(data);
  }

  /// Delete a supplier
  Future<void> deleteSupplier(String id) async {
    await _collection.doc(id).delete();
  }

  /// Update supplier balance transactionally
  Future<void> updateSupplierBalance(String id, double delta) async {
    await _firestore.runTransaction((transaction) async {
      final docRef = _collection.doc(id);
      final snapshot = await transaction.get(docRef);

      if (!snapshot.exists) {
        throw Exception('Supplier not found');
      }

      final currentBalance = (snapshot.data() as Map<String, dynamic>)['balance'] as double? ?? 0.0;
      final newBalance = currentBalance + delta;

      transaction.update(docRef, {
        'balance': newBalance,
        'updated_at': FieldValue.serverTimestamp(),
      });
    });
  }
}
