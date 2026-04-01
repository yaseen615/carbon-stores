import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/product_repository.dart';
import '../data/models/product_model.dart';

// ─── Repository Provider ───
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository();
});

// ─── All Products Stream ───
final productsStreamProvider = StreamProvider<List<Product>>((ref) {
  final repo = ref.watch(productRepositoryProvider);
  return repo.getProducts();
});

// ─── Selected Category ───
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

// ─── Search Query ───
final productSearchQueryProvider = StateProvider<String>((ref) => '');

// ─── Categories (derived from products) ───
final categoriesProvider = Provider<List<String>>((ref) {
  final productsAsync = ref.watch(productsStreamProvider);
  return productsAsync.when(
    data: (products) {
      final categories = products
          .map((p) => p.category)
          .where((c) => c.isNotEmpty)
          .toSet()
          .toList();
      categories.sort();
      return categories;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// ─── Filtered Products (by category + search) ───
final filteredProductsProvider = Provider<List<Product>>((ref) {
  final productsAsync = ref.watch(productsStreamProvider);
  final selectedCategory = ref.watch(selectedCategoryProvider);
  final searchQuery = ref.watch(productSearchQueryProvider).toLowerCase().trim();

  return productsAsync.when(
    data: (products) {
      var filtered = products;

      // Filter by category
      if (selectedCategory != null) {
        filtered = filtered.where((p) => p.category == selectedCategory).toList();
      }

      // Filter by search
      if (searchQuery.isNotEmpty) {
        filtered = filtered
            .where((p) => p.name.toLowerCase().contains(searchQuery))
            .toList();
      }

      filtered = filtered.toList()..sort((a, b) {
        int cmp = b.sales.compareTo(a.sales);
        if (cmp != 0) return cmp;
        return a.name.compareTo(b.name);
      });

      return filtered;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// ─── Low Stock Products ───
final lowStockProductsProvider = Provider<List<Product>>((ref) {
  final productsAsync = ref.watch(productsStreamProvider);
  return productsAsync.when(
    data: (products) => products.where((p) => p.isLowStock || p.isOutOfStock).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});
