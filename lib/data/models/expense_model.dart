import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  final String id;
  final String productName; // Product name or description for 'other' type
  final String? productId;
  final int quantity;
  final double cost; // Wholesale cost per unit (for product type), or total amount (for other type)
  final String section; // 'cafe' or 'store'
  final String type; // 'product' (auto from inventory) or 'other' (manual)
  final String remark; // Optional note/remark
  final DateTime date;
  final DateTime createdAt;

  const Expense({
    required this.id,
    required this.productName,
    this.productId,
    required this.quantity,
    required this.cost,
    this.section = 'store',
    this.type = 'other',
    this.remark = '',
    required this.date,
    required this.createdAt,
  });

  double get totalCost => cost * quantity;

  bool get isProductExpense => type == 'product';

  Expense copyWith({
    String? id,
    String? productName,
    String? productId,
    int? quantity,
    double? cost,
    String? section,
    String? type,
    String? remark,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return Expense(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      cost: cost ?? this.cost,
      section: section ?? this.section,
      type: type ?? this.type,
      remark: remark ?? this.remark,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Expense.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Expense(
      id: doc.id,
      productName: data['product_name'] ?? '',
      productId: data['product_id'],
      quantity: (data['quantity'] ?? 1).toInt(),
      cost: (data['cost'] ?? 0).toDouble(),
      section: data['section'] ?? 'store',
      type: data['type'] ?? 'other',
      remark: data['remark'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'product_name': productName,
      'product_id': productId,
      'quantity': quantity,
      'cost': cost,
      'section': section,
      'type': type,
      'remark': remark,
      'date': Timestamp.fromDate(date),
      'created_at': FieldValue.serverTimestamp(),
    };
  }
}
