import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction_model.dart';
import '../../core/constants/app_constants.dart';

class TransactionRepository {
  final CollectionReference _collection;

  TransactionRepository({FirebaseFirestore? firestore})
      : _collection = (firestore ?? FirebaseFirestore.instance)
            .collection(AppConstants.transactionsCollection);

  /// Create a new transaction
  Future<String> createTransaction(StoreTransaction transaction) async {
    final doc = await _collection.add(transaction.toFirestore());
    return doc.id;
  }

  /// Stream all transactions (most recent first)
  Stream<List<StoreTransaction>> getTransactions() {
    return _collection
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(StoreTransaction.fromFirestore).toList());
  }

  /// Stream transactions for a specific date
  Stream<List<StoreTransaction>> getTransactionsByDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _collection
        .where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('created_at', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(StoreTransaction.fromFirestore).toList());
  }

  /// Stream transactions for a specific month
  Stream<List<StoreTransaction>> getTransactionsByMonth(int year, int month) {
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 1);
    return getTransactionsByDateRange(startOfMonth, endOfMonth);
  }

  /// Stream transactions for a specific date range
  Stream<List<StoreTransaction>> getTransactionsByDateRange(DateTime start, DateTime end) {
    return _collection
        .where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('created_at', isLessThan: Timestamp.fromDate(end))
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(StoreTransaction.fromFirestore).toList());
  }

  /// Get transactions for a student
  Stream<List<StoreTransaction>> getStudentTransactions(String studentId) {
    return _collection
        .where('student_id', isEqualTo: studentId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(StoreTransaction.fromFirestore).toList());
  }

  /// Get daily revenue (one-shot)
  Future<double> getDailyRevenue(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await _collection
        .where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('created_at', isLessThan: Timestamp.fromDate(endOfDay))
        .get();

    double total = 0.0;
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      total += (data['paid_amount'] ?? 0).toDouble();
    }
    return total;
  }

  /// Get recent transactions (limited)
  Future<List<StoreTransaction>> getRecentTransactions({int limit = 20}) async {
    final snapshot = await _collection
        .orderBy('created_at', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map(StoreTransaction.fromFirestore).toList();
  }

  /// Get paginated transactions
  Future<List<StoreTransaction>> getPaginatedTransactions({
    DocumentSnapshot? startAfter,
    int limit = 20,
    bool? isVoidedFilter,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    Query query = _collection;

    if (isVoidedFilter != null) {
      query = query.where('is_voided', isEqualTo: isVoidedFilter);
    }

    if (startDate != null) {
      query = query.where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }

    if (endDate != null) {
      query = query.where('created_at', isLessThan: Timestamp.fromDate(endDate));
    }

    // Must order by created_at since we might use it in where clauses or generally want sort
    query = query.orderBy('created_at', descending: true);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    query = query.limit(limit);

    final snapshot = await query.get();
    return snapshot.docs.map(StoreTransaction.fromFirestore).toList();
  }
}
