import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense_model.dart';
import '../../core/constants/app_constants.dart';

class ExpenseRepository {
  final CollectionReference _collection;

  ExpenseRepository({FirebaseFirestore? firestore})
      : _collection = (firestore ?? FirebaseFirestore.instance)
            .collection(AppConstants.expensesCollection);

  /// Stream all expenses (most recent first)
  Stream<List<Expense>> getExpenses() {
    return _collection
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Expense.fromFirestore).toList());
  }

  /// Stream expenses for a specific date range
  Stream<List<Expense>> getExpensesByDateRange(DateTime start, DateTime end) {
    return _collection
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Expense.fromFirestore).toList());
  }

  /// Add an expense
  Future<String> addExpense(Expense expense) async {
    final doc = await _collection.add(expense.toFirestore());
    return doc.id;
  }

  /// Update an expense
  Future<void> updateExpense(String id, Map<String, dynamic> data) async {
    await _collection.doc(id).update(data);
  }

  /// Delete an expense
  Future<void> deleteExpense(String id) async {
    await _collection.doc(id).delete();
  }

  /// Get total expenses for a date range
  Future<double> getTotalExpenses(DateTime start, DateTime end) async {
    final snapshot = await _collection
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .get();

    double total = 0.0;
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final qty = (data['quantity'] ?? 0).toInt();
      final cost = (data['cost'] ?? 0).toDouble();
      total += qty * cost;
    }
    return total;
  }
}
