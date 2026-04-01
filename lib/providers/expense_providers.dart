import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/expense_repository.dart';
import '../data/models/expense_model.dart';
import 'analytics_providers.dart';

// ─── Filtered Analytics Expenses ───
final filteredExpensesProvider = StreamProvider<List<Expense>>((ref) {
  final repo = ref.watch(expenseRepositoryProvider);
  final dateRange = ref.watch(analyticsResolvedDateRangeProvider);
  if (dateRange == null) return repo.getExpenses();
  return repo.getExpensesByDateRange(dateRange.start, dateRange.end);
});

// ─── Repository Provider ───
final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository();
});

// ─── All Expenses Stream ───
final expensesStreamProvider = StreamProvider<List<Expense>>((ref) {
  final repo = ref.watch(expenseRepositoryProvider);
  return repo.getExpenses();
});

// ─── Filtered Total Expenses ───
final totalFilteredExpensesProvider = Provider<double>((ref) {
  final expensesAsync = ref.watch(filteredExpensesProvider);
  return expensesAsync.when(
    data: (expenses) => expenses.fold(0.0, (sum, e) => sum + e.totalCost),
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
});

// ─── Total Expenses (All Time) ───
final totalExpensesProvider = Provider<double>((ref) {
  final expensesAsync = ref.watch(expensesStreamProvider);
  return expensesAsync.when(
    data: (expenses) => expenses.fold(0.0, (sum, e) => sum + e.totalCost),
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
});
