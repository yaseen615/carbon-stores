import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final double price; // Retail price — shown on POS for billing
  final double wholesalePrice; // Cost/purchase price — your expense
  final int stock;
  final String category;
  final String section; // 'cafe' or 'store'
  final String supplier; // Supplier name
  final int sales;
  final DateTime updatedAt;
  final String? imageId;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    this.wholesalePrice = 0,
    required this.stock,
    required this.category,
    this.section = 'store',
    this.supplier = '',
    this.sales = 0,
    required this.updatedAt,
    this.imageId,
  });

  bool get isOutOfStock => stock <= 0;
  bool get isLowStock => stock > 0 && stock <= 10;
  bool get isCriticalStock => stock > 0 && stock <= 3;

  Product copyWith({
    String? id,
    String? name,
    double? price,
    double? wholesalePrice,
    int? stock,
    String? category,
    String? section,
    String? supplier,
    int? sales,
    DateTime? updatedAt,
    String? imageId,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      wholesalePrice: wholesalePrice ?? this.wholesalePrice,
      stock: stock ?? this.stock,
      category: category ?? this.category,
      section: section ?? this.section,
      supplier: supplier ?? this.supplier,
      sales: sales ?? this.sales,
      updatedAt: updatedAt ?? this.updatedAt,
      imageId: imageId ?? this.imageId,
    );
  }

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      wholesalePrice: (data['wholesale_price'] ?? 0).toDouble(),
      stock: (data['stock'] ?? 0).toInt(),
      category: data['category'] ?? 'General',
      section: data['section'] ?? 'store',
      supplier: data['supplier'] ?? '',
      sales: (data['sales'] ?? 0).toInt(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageId: data['imageId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'price': price,
      'wholesale_price': wholesalePrice,
      'stock': stock,
      'category': category,
      'section': section,
      'supplier': supplier,
      'sales': sales,
      'updated_at': FieldValue.serverTimestamp(),
      if (imageId != null) 'imageId': imageId,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Product && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
