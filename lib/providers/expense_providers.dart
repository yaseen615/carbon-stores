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
  return stream.map((list) => list.where((e) => e.section == section.firestoreValue).toList());
});

// ─── Repository Provider ───
final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository();
});

// ─── All Expenses Stream ───
final expensesStreamProvider = StreamProvider<List<Expense>>((ref) {
  final repo = ref.watch(expenseRepositoryProvider);
  final section = ref.watch(storeSectionProvider);
  final stream = repo.getExpenses();
  if (section == StoreSection.all) return stream;
  return stream.map((list) => list.where((e) => e.section == section.firestoreValue).toList());
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
