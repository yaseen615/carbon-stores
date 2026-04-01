import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/audit_log_model.dart';
import '../../core/constants/app_constants.dart';

class AuditRepository {
  final CollectionReference _collection;

  AuditRepository({FirebaseFirestore? firestore})
      : _collection = (firestore ?? FirebaseFirestore.instance)
            .collection(AppConstants.auditLogsCollection);

  /// Log an action
  Future<void> log({
    required String action,
    required String description,
    String? userId,
    Map<String, dynamic>? metadata,
  }) async {
    await _collection.add({
      'action': action,
      'description': description,
      'user': userId,
      'metadata': metadata,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Stream recent audit logs
  Stream<List<AuditLog>> getRecentLogs({int limit = 50}) {
    return _collection
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(AuditLog.fromFirestore).toList());
  }
}
