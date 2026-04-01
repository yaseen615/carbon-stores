import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/transaction_repository.dart';
import '../data/models/transaction_model.dart';
import 'analytics_providers.dart';

// ─── Filtered Analytics Transactions ───
final filteredTransactionsProvider = StreamProvider<List<StoreTransaction>>((ref) {
  final repo = ref.watch(transactionRepositoryProvider);
  final dateRange = ref.watch(analyticsResolvedDateRangeProvider);
  if (dateRange == null) return repo.getTransactions();
  return repo.getTransactionsByDateRange(dateRange.start, dateRange.end);
});

// ─── Repository Provider ───
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository();
});

// ─── All Transactions Stream ───
final transactionsStreamProvider = StreamProvider<List<StoreTransaction>>((ref) {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getTransactions();
});

// ─── Today's Transactions ───
final todayTransactionsProvider = StreamProvider<List<StoreTransaction>>((ref) {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getTransactionsByDate(DateTime.now());
});

// ─── Selected Month Transactions ───
final selectedMonthProvider = StateProvider<DateTime>((ref) => DateTime.now());

final monthlyTransactionsProvider = StreamProvider<List<StoreTransaction>>((ref) {
  final repo = ref.watch(transactionRepositoryProvider);
  final month = ref.watch(selectedMonthProvider);
  return repo.getTransactionsByMonth(month.year, month.month);
});
