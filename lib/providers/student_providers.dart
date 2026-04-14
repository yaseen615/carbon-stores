import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/student_repository.dart';
import '../data/models/student_model.dart';
import '../core/services/student_search_index.dart';

// ─── Repository Provider ───
final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  return StudentRepository();
});

// ─── Search Index (singleton) ───
final studentSearchIndexProvider = Provider<StudentSearchIndex>((ref) {
  return StudentSearchIndex();
});

// ─── Search Query ───
final studentSearchQueryProvider = StateProvider<String>((ref) => '');

// ─── Selected Student (for POS billing) ───
final selectedStudentProvider = StateProvider<Student?>((ref) => null);

// ═══════════════════════════════════════════════════════════════
//  PAGINATED STUDENTS (replaces old studentsStreamProvider)
// ═══════════════════════════════════════════════════════════════

/// State for paginated student list
class PaginatedStudentsState {
  final List<Student> students;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;

  const PaginatedStudentsState({
    this.students = const [],
    this.lastDocument,
    this.hasMore = true,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  PaginatedStudentsState copyWith({
    List<Student>? students,
    DocumentSnapshot? lastDocument,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
  }) {
    return PaginatedStudentsState(
      students: students ?? this.students,
      lastDocument: lastDocument ?? this.lastDocument,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
    );
  }
}

/// Manages paginated student loading — 12 per page, cursor-based
class PaginatedStudentsNotifier extends StateNotifier<PaginatedStudentsState> {
  final StudentRepository _repo;

  PaginatedStudentsNotifier(this._repo) : super(const PaginatedStudentsState()) {
    loadInitial();
  }

  /// Load first page (12 students)
  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final page = await _repo.getStudentsPaginated(limit: 12);
      state = PaginatedStudentsState(
        students: page.students,
        lastDocument: page.lastDocument,
        hasMore: page.hasMore,
      );
    } catch (e) {
      state = PaginatedStudentsState(error: e.toString());
    }
  }

  /// Load next page (infinite scroll)
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore || state.isLoading) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final page = await _repo.getStudentsPaginated(
        limit: 12,
        startAfter: state.lastDocument,
      );
      state = state.copyWith(
        students: [...state.students, ...page.students],
        lastDocument: page.lastDocument,
        hasMore: page.hasMore,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  /// Refresh (reload first page — used after sync or add)
  Future<void> refresh() async {
    await loadInitial();
  }
}

final paginatedStudentsProvider =
    StateNotifierProvider<PaginatedStudentsNotifier, PaginatedStudentsState>(
        (ref) {
  final repo = ref.watch(studentRepositoryProvider);
  return PaginatedStudentsNotifier(repo);
});

// ═══════════════════════════════════════════════════════════════
//  STUDENT STATS (aggregate query — 1 read instead of N)
// ═══════════════════════════════════════════════════════════════

final studentStatsProvider = FutureProvider<StudentStats>((ref) async {
  final repo = ref.watch(studentRepositoryProvider);
  return repo.getStudentStats();
});

// ═══════════════════════════════════════════════════════════════
//  SEARCH — local index + targeted Firestore doc fetches
// ═══════════════════════════════════════════════════════════════

/// Provider for search results (Student objects with balance/debt).
/// Flow: local index search → get matched IDs → fetch those docs.
/// Fallback: if local index is empty (never synced), query Firestore directly.
final studentSearchResultsProvider = FutureProvider<List<Student>>((ref) async {
  final query = ref.watch(studentSearchQueryProvider);
  if (query.trim().isEmpty) return [];

  final index = ref.read(studentSearchIndexProvider);
  await index.load();

  // Try local index first (zero Firestore reads)
  final matches = index.search(query, limit: 12);

  if (matches.isNotEmpty) {
    // Fetch those specific docs from Firestore (up to 12 reads)
    final ids = matches.map((m) => m.studentId).toList();
    final repo = ref.read(studentRepositoryProvider);
    return repo.getStudentsByIds(ids);
  }

  // Fallback: if local index is empty or has no matches,
  // try a direct Firestore lookup by document ID (exact match).
  // This handles the case before first sync.
  final repo = ref.read(studentRepositoryProvider);
  final directMatch = await repo.getStudent(query.trim());
  if (directMatch != null) return [directMatch];

  return [];
});

// ═══════════════════════════════════════════════════════════════
//  BACKWARD COMPAT — keep old providers as aliases
//  (used by Analytics CSV export)
// ═══════════════════════════════════════════════════════════════

final totalWalletBalanceProvider = Provider<double>((ref) {
  final statsAsync = ref.watch(studentStatsProvider);
  return statsAsync.when(
    data: (stats) => stats.totalBalance,
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
});

final totalDebtProvider = Provider<double>((ref) {
  final statsAsync = ref.watch(studentStatsProvider);
  return statsAsync.when(
    data: (stats) => stats.totalDebt,
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
});

/// Filtered students — used by POS student search.
/// Now backed by the search index + targeted fetches.
final filteredStudentsProvider = Provider<List<Student>>((ref) {
  final searchResults = ref.watch(studentSearchResultsProvider);
  return searchResults.when(
    data: (students) => students,
    loading: () => [],
    error: (_, __) => [],
  );
});
