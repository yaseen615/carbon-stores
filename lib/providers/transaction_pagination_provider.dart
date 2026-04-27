import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/transaction_model.dart';
import 'transaction_providers.dart';

class PaginatedTransactionsState {
  final List<StoreTransaction> transactions;
  final bool hasMore;
  final bool isLoadingMore;

  PaginatedTransactionsState({
    required this.transactions,
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  PaginatedTransactionsState copyWith({
    List<StoreTransaction>? transactions,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return PaginatedTransactionsState(
      transactions: transactions ?? this.transactions,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class TransactionFilter {
  final DateTime? startDate;
  final DateTime? endDate;

  TransactionFilter({this.startDate, this.endDate});
}

final transactionFilterProvider = StateProvider<TransactionFilter>((ref) => TransactionFilter());

class PaginatedTransactionsNotifier extends AutoDisposeAsyncNotifier<PaginatedTransactionsState> {
  static const int _limit = 20;

  @override
  Future<PaginatedTransactionsState> build() async {
    final filter = ref.watch(transactionFilterProvider);
    final repo = ref.watch(transactionRepositoryProvider);
    
    final txns = await repo.getPaginatedTransactions(
      limit: _limit,
      startDate: filter.startDate,
      endDate: filter.endDate,
    );
    
    return PaginatedTransactionsState(
      transactions: txns,
      hasMore: txns.length == _limit,
    );
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.hasError) return;
    
    final currentState = state.value;
    if (currentState == null || !currentState.hasMore || currentState.isLoadingMore) return;

    state = AsyncValue.data(currentState.copyWith(isLoadingMore: true));
    
    try {
      final filter = ref.read(transactionFilterProvider);
      final repo = ref.read(transactionRepositoryProvider);
      final lastDoc = currentState.transactions.isNotEmpty ? currentState.transactions.last.snapshot : null;
      
      final moreTxns = await repo.getPaginatedTransactions(
        limit: _limit,
        startDate: filter.startDate,
        endDate: filter.endDate,
        startAfter: lastDoc,
      );
      
      state = AsyncValue.data(currentState.copyWith(
        transactions: [...currentState.transactions, ...moreTxns],
        hasMore: moreTxns.length == _limit,
        isLoadingMore: false,
      ));
    } catch (e) {
      state = AsyncValue.data(currentState.copyWith(isLoadingMore: false));
    }
  }
}

final paginatedTransactionsProvider = AsyncNotifierProvider.autoDispose<PaginatedTransactionsNotifier, PaginatedTransactionsState>(() {
  return PaginatedTransactionsNotifier();
});
