import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/transaction_repository.dart';
import '../data/models/transaction_model.dart';
import '../core/constants/store_section.dart';
import 'analytics_providers.dart';
import 'store_section_provider.dart';

// ─── Filtered Analytics Transactions ───
final filteredTransactionsProvider = StreamProvider<List<StoreTransaction>>((ref) {
  final repo = ref.watch(transactionRepositoryProvider);
  final dateRange = ref.watch(analyticsResolvedDateRangeProvider);
  final section = ref.watch(storeSectionProvider);
  
  final stream = dateRange == null
      ? repo.getTransactions()
      : repo.getTransactionsByDateRange(dateRange.start, dateRange.end);
  
  if (section == StoreSection.all) return stream;
  // combined transactions appear in BOTH cafe and store filters
  return stream.map((list) => list.where((t) {
    if (t.section == 'combined') return true;
    return t.section == section.firestoreValue;
  }).toList());
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

// ─── Today's Sales Total ───
final todaySalesProvider = Provider<double>((ref) {
  final txns = ref.watch(todayTransactionsProvider);
  final section = ref.watch(storeSectionProvider);
  return txns.maybeWhen(
    data: (list) {
      var filtered = list.where((t) => !t.isVoided);
      if (section != StoreSection.all) {
        // combined bills count in both cafe and store
        filtered = filtered.where((t) =>
            t.section == section.firestoreValue || t.section == 'combined');
      }
      return filtered.fold(0.0, (sum, t) => sum + t.paidAmount);
    },
    orElse: () => 0.0,
  );
});

// ─── Today's Transaction Count ───
final todayTransactionCountProvider = Provider<int>((ref) {
  final txns = ref.watch(todayTransactionsProvider);
  final section = ref.watch(storeSectionProvider);
  return txns.maybeWhen(
    data: (list) {
      var filtered = list.where((t) => !t.isVoided);
      if (section != StoreSection.all) {
        filtered = filtered.where((t) =>
            t.section == section.firestoreValue || t.section == 'combined');
      }
      return filtered.length;
    },
    orElse: () => 0,
  );
});
