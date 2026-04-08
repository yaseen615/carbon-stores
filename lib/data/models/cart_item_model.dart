class CartItem {
  final String productId;
  final String name;
  final double price;
  final int quantity;
  final String? imageId;

  const CartItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    this.imageId,
  });

  double get total => price * quantity;

  CartItem copyWith({
    String? productId,
    String? name,
    double? price,
    int? quantity,
    String? imageId,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      imageId: imageId ?? this.imageId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'product_id': productId,
      'name': name,
      'price': price,
      'qty': quantity,
      'imageId': imageId,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      productId: map['product_id'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      quantity: (map['qty'] ?? 0).toInt(),
      imageId: map['imageId'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CartItem && productId == other.productId;

  @override
  int get hashCode => productId.hashCode;
}
