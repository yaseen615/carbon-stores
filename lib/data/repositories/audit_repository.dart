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

  /// Get paginated audit logs
  Future<List<AuditLog>> getPaginatedLogs({
    DocumentSnapshot? startAfter,
    int limit = 20,
    String? actionFilter,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    Query query = _collection;

    if (actionFilter != null && actionFilter.isNotEmpty && actionFilter != 'all') {
      query = query.where('action', isEqualTo: actionFilter);
    }

    if (startDate != null) {
      query = query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }

    if (endDate != null) {
      query = query.where('timestamp', isLessThan: Timestamp.fromDate(endDate));
    }

    query = query.orderBy('timestamp', descending: true);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    query = query.limit(limit);

    final snapshot = await query.get();
    return snapshot.docs.map(AuditLog.fromFirestore).toList();
  }
}
