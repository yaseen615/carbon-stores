import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/audit_log_model.dart';
import '../data/repositories/audit_repository.dart';

final auditRepositoryProvider = Provider((ref) => AuditRepository());

class PaginatedAuditState {
  final List<AuditLog> logs;
  final bool hasMore;
  final bool isLoadingMore;

  PaginatedAuditState({
    required this.logs,
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  PaginatedAuditState copyWith({
    List<AuditLog>? logs,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return PaginatedAuditState(
      logs: logs ?? this.logs,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class AuditFilter {
  final DateTime? startDate;
  final DateTime? endDate;

  AuditFilter({this.startDate, this.endDate});
}

final auditFilterProvider = StateProvider<AuditFilter>((ref) => AuditFilter());

class PaginatedAuditNotifier extends AutoDisposeAsyncNotifier<PaginatedAuditState> {
  static const int _limit = 20;

  @override
  Future<PaginatedAuditState> build() async {
    final filter = ref.watch(auditFilterProvider);
    final repo = ref.watch(auditRepositoryProvider);
    
    final logs = await repo.getPaginatedLogs(
      limit: _limit,
      startDate: filter.startDate,
      endDate: filter.endDate,
    );
    
    return PaginatedAuditState(
      logs: logs,
      hasMore: logs.length == _limit,
    );
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.hasError) return;
    
    final currentState = state.value;
    if (currentState == null || !currentState.hasMore || currentState.isLoadingMore) return;

    state = AsyncValue.data(currentState.copyWith(isLoadingMore: true));
    
    try {
      final filter = ref.read(auditFilterProvider);
      final repo = ref.read(auditRepositoryProvider);
      final lastDoc = currentState.logs.isNotEmpty ? currentState.logs.last.snapshot : null;
      
      final moreLogs = await repo.getPaginatedLogs(
        limit: _limit,
        startDate: filter.startDate,
        endDate: filter.endDate,
        startAfter: lastDoc,
      );
      
      state = AsyncValue.data(currentState.copyWith(
        logs: [...currentState.logs, ...moreLogs],
        hasMore: moreLogs.length == _limit,
        isLoadingMore: false,
      ));
    } catch (e) {
      state = AsyncValue.data(currentState.copyWith(isLoadingMore: false));
    }
  }
}

final paginatedAuditProvider = AsyncNotifierProvider.autoDispose<PaginatedAuditNotifier, PaginatedAuditState>(() {
  return PaginatedAuditNotifier();
});
