import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/student_repository.dart';
import '../data/models/student_model.dart';

// ─── Repository Provider ───
final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  return StudentRepository();
});

// ─── All Students Stream ───
final studentsStreamProvider = StreamProvider<List<Student>>((ref) {
  final repo = ref.watch(studentRepositoryProvider);
  return repo.getStudents();
});

// ─── Search Query ───
final studentSearchQueryProvider = StateProvider<String>((ref) => '');

// ─── Filtered Students ───
final filteredStudentsProvider = Provider<List<Student>>((ref) {
  final studentsAsync = ref.watch(studentsStreamProvider);
  final searchQuery = ref.watch(studentSearchQueryProvider).toLowerCase().trim();

  return studentsAsync.when(
    data: (students) {
      if (searchQuery.isEmpty) return students;
      return students
          .where((s) =>
              s.name.toLowerCase().contains(searchQuery) ||
              s.id.toLowerCase().contains(searchQuery))
          .toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// ─── Selected Student (for POS billing) ───
final selectedStudentProvider = StateProvider<Student?>((ref) => null);

// ─── Student Stats ───
final totalWalletBalanceProvider = Provider<double>((ref) {
  final studentsAsync = ref.watch(studentsStreamProvider);
  return studentsAsync.when(
    data: (students) => students.fold(0.0, (sum, s) => sum + s.balance),
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
});

final totalDebtProvider = Provider<double>((ref) {
  final studentsAsync = ref.watch(studentsStreamProvider);
  return studentsAsync.when(
    data: (students) => students.fold(0.0, (sum, s) => sum + s.debt),
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
});
