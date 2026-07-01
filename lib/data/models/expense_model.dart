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
  final String? supplierId;
  final String? supplierName;
  final double paidAmount;
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
    this.supplierId,
    this.supplierName,
    this.paidAmount = 0.0,
    required this.date,
    required this.createdAt,
  });

  double get totalCost => cost * quantity;

  bool get isProductExpense => type == 'product';
  
  bool get isPaid => paidAmount >= totalCost;

  Expense copyWith({
    String? id,
    String? productName,
    String? productId,
    int? quantity,
    double? cost,
    String? section,
    String? type,
    String? remark,
    String? supplierId,
    String? supplierName,
    double? paidAmount,
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
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      paidAmount: paidAmount ?? this.paidAmount,
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
      supplierId: data['supplier_id'],
      supplierName: data['supplier_name'],
      paidAmount: (data['paid_amount'] ?? 0).toDouble(),
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
      'supplier_id': supplierId,
      'supplier_name': supplierName,
      'paid_amount': paidAmount,
      'date': Timestamp.fromDate(date),
      'created_at': FieldValue.serverTimestamp(),
    };
  }
}
