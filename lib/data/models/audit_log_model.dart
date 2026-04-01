import 'package:cloud_firestore/cloud_firestore.dart';

class AuditLog {
  final String id;
  final String action; // sale, recharge, edit, stock_in, expense
  final String description;
  final String? userId;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;

  const AuditLog({
    required this.id,
    required this.action,
    required this.description,
    this.userId,
    this.metadata,
    required this.timestamp,
  });

  factory AuditLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AuditLog(
      id: doc.id,
      action: data['action'] ?? '',
      description: data['description'] ?? '',
      userId: data['user'],
      metadata: data['metadata'] as Map<String, dynamic>?,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'action': action,
      'description': description,
      'user': userId,
      'metadata': metadata,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}
