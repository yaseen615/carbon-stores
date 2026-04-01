import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  final String id;
  final String productName;
  final String? productId;
  final int quantity;
  final double cost;
  final DateTime date;
  final DateTime createdAt;

  const Expense({
    required this.id,
    required this.productName,
    this.productId,
    required this.quantity,
    required this.cost,
    required this.date,
    required this.createdAt,
  });

  double get totalCost => cost * quantity;

  Expense copyWith({
    String? id,
    String? productName,
    String? productId,
    int? quantity,
    double? cost,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return Expense(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      cost: cost ?? this.cost,
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
      quantity: (data['quantity'] ?? 0).toInt(),
      cost: (data['cost'] ?? 0).toDouble(),
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
      'date': Timestamp.fromDate(date),
      'created_at': FieldValue.serverTimestamp(),
    };
  }
}
