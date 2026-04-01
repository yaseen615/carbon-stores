import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/student_providers.dart';
import '../../../data/models/student_model.dart';

class StudentInfoCard extends ConsumerStatefulWidget {
  const StudentInfoCard({super.key});

  @override
  ConsumerState<StudentInfoCard> createState() => _StudentInfoCardState();
}

class _StudentInfoCardState extends ConsumerState<StudentInfoCard> {
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedStudent = ref.watch(selectedStudentProvider);

    if (selectedStudent != null && !_isSearching) {
      return _SelectedStudentView(
        student: selectedStudent,
        onClear: () {
          ref.read(selectedStudentProvider.notifier).state = null;
          ref.read(studentSearchQueryProvider.notifier).state = '';
        },
      );
    }

    return _StudentSearch(
      controller: _searchController,
      onStudentSelected: (student) {
        ref.read(selectedStudentProvider.notifier).state = student;
        _searchController.clear();
        ref.read(studentSearchQueryProvider.notifier).state = '';
        setState(() => _isSearching = false);
      },
      onSearchToggle: (searching) {
        setState(() => _isSearching = searching);
      },
      isSearching: _isSearching,
    );
  }
}

class _SelectedStudentView extends StatelessWidget {
  final Student student;
  final VoidCallback onClear;

  const _SelectedStudentView({
    required this.student,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.infoContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.person_rounded,
              size: 20,
              color: AppColors.info,
            ),
          ),
          const SizedBox(width: 10),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      'ID: ${student.id}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.infoContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        CurrencyFormatter.formatCompact(student.balance),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.info,
                        ),
                      ),
                    ),
                    if (student.hasDebt) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.errorContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '-${CurrencyFormatter.formatCompact(student.debt)}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Clear
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            onPressed: onClear,
            color: AppColors.onSurfaceVariant,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

class _StudentSearch extends ConsumerWidget {
  final TextEditingController controller;
  final ValueChanged<Student> onStudentSelected;
  final ValueChanged<bool> onSearchToggle;
  final bool isSearching;

  const _StudentSearch({
    required this.controller,
    required this.onStudentSelected,
    required this.onSearchToggle,
    required this.isSearching,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isSearching) {
      return InkWell(
        onTap: () => onSearchToggle(true),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(
                Icons.person_add_rounded,
                size: 18,
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 8),
              Text(
                'Link student (optional)',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final studentsAsync = ref.watch(studentsStreamProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search Input
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  style: const TextStyle(fontSize: 13, color: AppColors.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Search by ID or name...',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.surfaceContainer,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    ref.read(studentSearchQueryProvider.notifier).state = value;
                  },
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () {
                  controller.clear();
                  ref.read(studentSearchQueryProvider.notifier).state = '';
                  onSearchToggle(false);
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ),

        // Results
        studentsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(12),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
          ),
          error: (_, __) => const Padding(
            padding: EdgeInsets.all(12),
            child: Text('Error loading students', style: TextStyle(color: AppColors.error, fontSize: 12)),
          ),
          data: (_) {
            final filtered = ref.watch(filteredStudentsProvider);
            final query = ref.watch(studentSearchQueryProvider);

            if (query.isEmpty) {
              return const SizedBox(height: 4);
            }

            if (filtered.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(12),
                child: Text('No students found', style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12)),
              );
            }

            return ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 120),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: filtered.length.clamp(0, 5),
                itemBuilder: (context, index) {
                  final student = filtered[index];
                  return ListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    leading: const Icon(Icons.person_rounded, size: 18, color: AppColors.info),
                    title: Text(student.name, style: const TextStyle(fontSize: 13, color: AppColors.onSurface)),
                    subtitle: Text('ID: ${student.id}', style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
                    trailing: Text(
                      CurrencyFormatter.formatCompact(student.balance),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.info),
                    ),
                    onTap: () => onStudentSelected(student),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
