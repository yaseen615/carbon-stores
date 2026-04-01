import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../../core/constants/app_constants.dart';

class ProductRepository {
  final FirebaseFirestore _firestore;
  final CollectionReference _collection;

  ProductRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _collection = (firestore ?? FirebaseFirestore.instance)
            .collection(AppConstants.productsCollection);

  /// Stream all products ordered by name
  Stream<List<Product>> getProducts() {
    return _collection
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Product.fromFirestore).toList());
  }

  /// Stream products by category
  Stream<List<Product>> getProductsByCategory(String category) {
    return _collection
        .where('category', isEqualTo: category)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Product.fromFirestore).toList());
  }

  /// Get a single product
  Future<Product?> getProduct(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return Product.fromFirestore(doc);
  }

  /// Add a new product
  Future<String> addProduct(Product product) async {
    final doc = await _collection.add(product.toFirestore());
    return doc.id;
  }

  /// Update a product
  Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    data['updated_at'] = FieldValue.serverTimestamp();
    await _collection.doc(id).update(data);
  }

  /// Delete a product
  Future<void> deleteProduct(String id) async {
    await _collection.doc(id).delete();
  }

  /// Atomic stock update (used during sales)
  Future<void> updateStock(String productId, int delta) async {
    await _firestore.runTransaction((transaction) async {
      final docRef = _collection.doc(productId);
      final snapshot = await transaction.get(docRef);

      if (!snapshot.exists) throw Exception('Product not found');

      final currentStock = (snapshot.data() as Map<String, dynamic>)['stock'] as int;
      final newStock = currentStock + delta;

      if (newStock < 0) throw Exception('Insufficient stock');

      final data = snapshot.data() as Map<String, dynamic>;
      final currentSales = (data['sales'] ?? 0) as int;
      final salesDelta = delta < 0 ? -delta : 0;
      final newSales = currentSales + salesDelta;

      transaction.update(docRef, {
        'stock': newStock,
        'sales': newSales,
        'updated_at': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Batch stock update for multiple products (used during sales)
  Future<void> batchUpdateStock(Map<String, int> stockChanges) async {
    await _firestore.runTransaction((transaction) async {
      // Read all products first
      final snapshots = <String, DocumentSnapshot>{};
      for (final productId in stockChanges.keys) {
        final snapshot = await transaction.get(_collection.doc(productId));
        if (!snapshot.exists) throw Exception('Product $productId not found');
        snapshots[productId] = snapshot;
      }

      // Then update all
      for (final entry in stockChanges.entries) {
        final data = snapshots[entry.key]!.data() as Map<String, dynamic>;
        final currentStock = data['stock'] as int;
        final newStock = currentStock + entry.value;

        if (newStock < 0) {
          throw Exception('Insufficient stock for ${data['name']}');
        }

        final currentSales = (data['sales'] ?? 0) as int;
        final salesDelta = entry.value < 0 ? -entry.value : 0;
        final newSales = currentSales + salesDelta;

        transaction.update(_collection.doc(entry.key), {
          'stock': newStock,
          'sales': newSales,
          'updated_at': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  /// Get all unique categories
  Future<List<String>> getCategories() async {
    final snapshot = await _collection.get();
    final categories = snapshot.docs
        .map((doc) => (doc.data() as Map<String, dynamic>)['category'] as String?)
        .where((c) => c != null && c.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();
    categories.sort();
    return categories;
  }
}
