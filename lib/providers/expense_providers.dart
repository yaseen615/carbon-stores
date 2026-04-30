import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/expense_repository.dart';
import '../data/models/expense_model.dart';
import '../core/constants/store_section.dart';
import 'analytics_providers.dart';
import 'store_section_provider.dart';

// ─── Filtered Analytics Expenses ───
final filteredExpensesProvider = StreamProvider<List<Expense>>((ref) {
  final repo = ref.watch(expenseRepositoryProvider);
  final dateRange = ref.watch(analyticsResolvedDateRangeProvider);
  final section = ref.watch(storeSectionProvider);

  final stream = dateRange == null
      ? repo.getExpenses()
      : repo.getExpensesByDateRange(dateRange.start, dateRange.end);

  if (section == StoreSection.all) return stream;
  return stream.map(
    (list) => list.where((e) => e.section == section.firestoreValue).toList(),
  );
});

// ─── Repository Provider ───
final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository();
});

// ─── Expenses Stream (limited to last 90 days for performance) ───
// Previously fetched ALL expenses ever. Now defaults to 90 days to reduce reads.
final expensesStreamProvider = StreamProvider<List<Expense>>((ref) {
  final repo = ref.watch(expenseRepositoryProvider);
  final section = ref.watch(storeSectionProvider);

  // Limit to last 90 days by default instead of all time
  final now = DateTime.now();
  final start = DateTime(now.year, now.month - 3, now.day);
  final stream = repo.getExpensesByDateRange(
    start,
    now.add(const Duration(days: 1)),
  );

  if (section == StoreSection.all) return stream;
  return stream.map(
    (list) => list.where((e) => e.section == section.firestoreValue).toList(),
  );
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

// ─── Total Expenses (from filtered stream — not all time) ───
final totalExpensesProvider = Provider<double>((ref) {
  final expensesAsync = ref.watch(expensesStreamProvider);
  return expensesAsync.when(
    data: (expenses) => expenses.fold(0.0, (sum, e) => sum + e.totalCost),
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
});
