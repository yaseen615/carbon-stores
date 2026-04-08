import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/cart_item_model.dart';
import '../data/models/product_model.dart';

// ─── Cart State Notifier ───
class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  /// Add product to cart (or increment quantity if already exists)
  void addProduct(Product product) {
    if (product.isOutOfStock) return;

    final index = state.indexWhere((item) => item.productId == product.id);
    if (index >= 0) {
      // Already in cart - increment
      final currentItem = state[index];
      if (currentItem.quantity >= product.stock) return; // Don't exceed stock

      final updated = List<CartItem>.from(state);
      updated[index] = currentItem.copyWith(quantity: currentItem.quantity + 1);
      state = updated;
    } else {
      // New item
      state = [
        ...state,
        CartItem(
          productId: product.id,
          name: product.name,
          price: product.price,
          quantity: 1,
          imageId: product.imageId,
        ),
      ];
    }
  }

  /// Increment quantity
  void incrementQuantity(String productId, {int maxStock = 999}) {
    final index = state.indexWhere((item) => item.productId == productId);
    if (index < 0) return;

    final item = state[index];
    if (item.quantity >= maxStock) return;

    final updated = List<CartItem>.from(state);
    updated[index] = item.copyWith(quantity: item.quantity + 1);
    state = updated;
  }

  /// Decrement quantity (removes if 0)
  void decrementQuantity(String productId) {
    final index = state.indexWhere((item) => item.productId == productId);
    if (index < 0) return;

    final item = state[index];
    if (item.quantity <= 1) {
      removeItem(productId);
    } else {
      final updated = List<CartItem>.from(state);
      updated[index] = item.copyWith(quantity: item.quantity - 1);
      state = updated;
    }
  }

  /// Remove item from cart
  void removeItem(String productId) {
    state = state.where((item) => item.productId != productId).toList();
  }

  /// Clear entire cart
  void clearCart() {
    state = [];
  }

  /// Update quantity directly
  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }
    final index = state.indexWhere((item) => item.productId == productId);
    if (index < 0) return;

    final updated = List<CartItem>.from(state);
    updated[index] = state[index].copyWith(quantity: quantity);
    state = updated;
  }
}

// ─── Provider ───
final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});

// ─── Computed Providers ───
final cartTotalProvider = Provider<double>((ref) {
  final items = ref.watch(cartProvider);
  return items.fold(0.0, (sum, item) => sum + item.total);
});

final cartItemCountProvider = Provider<int>((ref) {
  final items = ref.watch(cartProvider);
  return items.fold(0, (sum, item) => sum + item.quantity);
});

final isCartEmptyProvider = Provider<bool>((ref) {
  return ref.watch(cartProvider).isEmpty;
});
