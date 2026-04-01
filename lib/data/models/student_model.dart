import 'package:cloud_firestore/cloud_firestore.dart';

class Student {
  final String id; // admission number
  final String name;
  final double balance;
  final double debt;
  final DateTime updatedAt;

  const Student({
    required this.id,
    required this.name,
    required this.balance,
    required this.debt,
    required this.updatedAt,
  });

  bool get hasDebt => debt > 0;
  bool get hasBalance => balance > 0;
  double get netBalance => balance - debt;

  Student copyWith({
    String? id,
    String? name,
    double? balance,
    double? debt,
    DateTime? updatedAt,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      debt: debt ?? this.debt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Student.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Student(
      id: doc.id,
      name: data['name'] ?? '',
      balance: (data['balance'] ?? 0).toDouble(),
      debt: (data['debt'] ?? 0).toDouble(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'balance': balance,
      'debt': debt,
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Student && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
