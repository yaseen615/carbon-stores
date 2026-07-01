import 'package:cloud_firestore/cloud_firestore.dart';

class SupplierPayment {
  final String id;
  final String supplierId;
  final String supplierName;
  final String? expenseId; // Optional: If tied to a specific expense
  final double amount;
  final String paymentMode; // 'cash', 'upi', 'bank_transfer', etc.
  final String remark; // Optional remark
  final DateTime date;
  final DateTime createdAt;

  const SupplierPayment({
    required this.id,
    required this.supplierId,
    required this.supplierName,
    this.expenseId,
    required this.amount,
    required this.paymentMode,
    this.remark = '',
    required this.date,
    required this.createdAt,
  });

  factory SupplierPayment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SupplierPayment(
      id: doc.id,
      supplierId: data['supplier_id'] ?? '',
      supplierName: data['supplier_name'] ?? '',
      expenseId: data['expense_id'],
      amount: (data['amount'] ?? 0).toDouble(),
      paymentMode: data['payment_mode'] ?? 'cash',
      remark: data['remark'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'supplier_id': supplierId,
      'supplier_name': supplierName,
      'expense_id': expenseId,
      'amount': amount,
      'payment_mode': paymentMode,
      'remark': remark,
      'date': Timestamp.fromDate(date),
      'created_at': FieldValue.serverTimestamp(),
    };
  }
}
