import 'package:cloud_firestore/cloud_firestore.dart';
import 'cart_item_model.dart';

class StoreTransaction {
  final String id;
  final String receiptId;
  final List<CartItem> items;
  final double totalAmount;
  final String paymentMode; // 'cash', 'wallet', 'mixed'
  final double paidAmount;
  final double walletAmount;
  final double cashAmount;
  final double upiAmount;
  final double debtAmount;
  final String? studentId;
  final String? studentName;
  final String section; // 'cafe' or 'store'
  final DateTime createdAt;
  final bool isVoided;
  final DateTime? voidedAt;
  final String? voidReason;
  final DocumentSnapshot? snapshot;

  const StoreTransaction({
    required this.id,
    required this.receiptId,
    required this.items,
    required this.totalAmount,
    required this.paymentMode,
    required this.paidAmount,
    this.walletAmount = 0,
    this.cashAmount = 0,
    this.upiAmount = 0,
    required this.debtAmount,
    this.section = 'store',
    this.studentId,
    this.studentName,
    required this.createdAt,
    this.isVoided = false,
    this.voidedAt,
    this.voidReason,
    this.snapshot,
  });

  int get totalItems => items.fold(0, (total, item) => total + item.quantity);

  String get itemsSummary {
    return items.map((i) => '${i.name} x${i.quantity}').join(', ');
  }

  factory StoreTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final itemsList = (data['items'] as List<dynamic>?)
        ?.map((item) => CartItem.fromMap(item as Map<String, dynamic>))
        .toList() ?? [];

    return StoreTransaction(
      id: doc.id,
      receiptId: data['receipt_id'] ?? '',
      items: itemsList,
      totalAmount: (data['total_amount'] ?? 0).toDouble(),
      paymentMode: data['payment_mode'] ?? 'cash',
      paidAmount: (data['paid_amount'] ?? 0).toDouble(),
      walletAmount: (data['wallet_amount'] ?? 0).toDouble(),
      cashAmount: (data['cash_amount'] ?? 0).toDouble(),
      upiAmount: (data['upi_amount'] ?? 0).toDouble(),
      debtAmount: (data['debt_amount'] ?? 0).toDouble(),
      studentId: data['student_id'],
      studentName: data['student_name'],
      section: data['section'] ?? 'store',
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isVoided: data['is_voided'] ?? false,
      voidedAt: (data['voided_at'] as Timestamp?)?.toDate(),
      voidReason: data['void_reason'],
      snapshot: doc,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'receipt_id': receiptId,
      'items': items.map((i) => i.toMap()).toList(),
      'total_amount': totalAmount,
      'payment_mode': paymentMode,
      'paid_amount': paidAmount,
      'wallet_amount': walletAmount,
      'cash_amount': cashAmount,
      'upi_amount': upiAmount,
      'debt_amount': debtAmount,
      'section': section,
      'student_id': studentId,
      'student_name': studentName,
      'created_at': FieldValue.serverTimestamp(),
      'is_voided': isVoided,
      'voided_at': voidedAt != null ? Timestamp.fromDate(voidedAt!) : null,
      'void_reason': voidReason,
    };
  }
}
