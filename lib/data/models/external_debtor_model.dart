import 'package:cloud_firestore/cloud_firestore.dart';

class ExternalDebtor {
  /// Generate search terms for Firestore array-contains queries.
  static List<String> generateSearchTerms(String name) {
    final words = name.toLowerCase().trim().split(RegExp(r'\s+'));
    final terms = <String>{};
    for (final word in words) {
      for (int i = 1; i <= word.length; i++) {
        terms.add(word.substring(0, i));
      }
    }
    return terms.toList()..sort();
  }

  final String id;
  final String name;
  final double debt;
  final DateTime updatedAt;

  const ExternalDebtor({
    required this.id,
    required this.name,
    required this.debt,
    required this.updatedAt,
  });

  bool get hasDebt => debt > 0;

  ExternalDebtor copyWith({
    String? id,
    String? name,
    double? debt,
    DateTime? updatedAt,
  }) {
    return ExternalDebtor(
      id: id ?? this.id,
      name: name ?? this.name,
      debt: debt ?? this.debt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ExternalDebtor.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ExternalDebtor(
      id: doc.id,
      name: data['name'] ?? '',
      debt: (data['debt'] ?? 0).toDouble(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'debt': debt,
      'search_terms': generateSearchTerms(name),
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ExternalDebtor && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
