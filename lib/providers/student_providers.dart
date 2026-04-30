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

/// Provider for search results — INSTANT in-memory filtering.
///
/// Since `studentsStreamProvider` already loads all students into memory
/// (used by debt calculations), we filter that list directly.
/// This is ~0ms vs the previous approach of 200-500ms (Firestore round-trips).
final studentSearchResultsProvider = Provider<AsyncValue<List<Student>>>((ref) {
  final query = ref.watch(studentSearchQueryProvider).trim().toLowerCase();
  final studentsAsync = ref.watch(studentsStreamProvider);

  if (query.isEmpty) return const AsyncValue.data([]);

  return studentsAsync.whenData((students) {
    final results = <Student>[];

    for (final s in students) {
      final nameLower = s.name.toLowerCase();
      final idLower = s.id.toLowerCase();

      // Match if query matches the START of any word in the name, or anywhere in ID
      final words = nameLower.split(RegExp(r'\s+'));
      final nameMatch = words.any((word) => word.startsWith(query));

      if (nameMatch || idLower.startsWith(query)) {
        results.add(s);
        if (results.length >= 12) break;
      }
    }

    // Sort: exact name starts first, then ID matches, then contains
    results.sort((a, b) {
      final aName = a.name.toLowerCase();
      final bName = b.name.toLowerCase();
      final aStarts = aName.startsWith(query) ? 0 : 1;
      final bStarts = bName.startsWith(query) ? 0 : 1;
      if (aStarts != bStarts) return aStarts.compareTo(bStarts);
      return aName.compareTo(bName);
    });

    return results;
  });
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
final filteredStudentsProvider = Provider<List<Student>>((ref) {
  final searchResults = ref.watch(studentSearchResultsProvider);
  return searchResults.when(
    data: (students) => students,
    loading: () => [],
    error: (_, __) => [],
  );
});
