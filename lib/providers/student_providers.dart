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

/// Provider for search results (Student objects with balance/debt).
///
/// Strategy (optimised for speed & minimal Firestore reads):
///   1. Try local index first → zero Firestore reads for the search itself.
///      If index is populated, trust it: no match = genuinely no match.
///      Only fetches full Student docs by ID for the matched entries.
///   2. If local index is empty (fresh device, never synced),
///      fall back to **server-side** Firestore queries:
///      a) array-contains on search_terms (word-prefix match).
///      b) Name prefix query (legacy fallback).
///      c) Exact document-ID lookup (admission number search).
///      This makes search work immediately on a fresh install — no sync required.
final studentSearchResultsProvider = FutureProvider<List<Student>>((ref) async {
  final query = ref.watch(studentSearchQueryProvider);
  if (query.trim().isEmpty) return [];

  final trimmed = query.trim();
  final index = ref.read(studentSearchIndexProvider);

  // Only await load if the index hasn't been loaded yet (avoids an async
  // frame on every keystroke when the index is already in memory).
  if (!index.isLoaded) await index.load();

  // ── 1. Local index is populated → use it exclusively (zero search reads) ──
  if (index.length > 0) {
    final matches = index.search(trimmed, limit: 12);
    if (matches.isEmpty) return []; // Trust the index — no match means no match
    final ids = matches.map((m) => m.studentId).toList();
    final repo = ref.read(studentRepositoryProvider);
    return repo.getStudentsByIds(ids);
  }

  // ── 2. Index empty (fresh install) → fall back to Firestore search ──
  final repo = ref.read(studentRepositoryProvider);
  return repo.searchStudents(trimmed, limit: 12);
});

// ═══════════════════════════════════════════════════════════════
//  BACKWARD COMPAT — keep old providers as aliases
//  (used by Analytics CSV export)
// ═══════════════════════════════════════════════════════════════

final studentsStreamProvider = StreamProvider<List<Student>>((ref) {
  final repo = ref.watch(studentRepositoryProvider);
  return repo.getStudents();
});

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
