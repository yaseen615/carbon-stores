import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/pos_colors.dart';
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
    final cs = Theme.of(context).colorScheme;
    final pos = context.pos;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: pos.fill,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Avatar — circular
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: pos.info.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: pos.info,
                ),
              ),
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
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    // Balance pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: pos.info.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        CurrencyFormatter.formatCompact(student.balance),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: pos.info,
                        ),
                      ),
                    ),
                    if (student.hasDebt) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: pos.error.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '-${CurrencyFormatter.formatCompact(student.debt)}',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: pos.error,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Close
          GestureDetector(
            onTap: onClear,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: cs.onSurfaceVariant.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close_rounded,
                  size: 14, color: cs.onSurfaceVariant),
            ),
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
    final cs = Theme.of(context).colorScheme;
    final pos = context.pos;

    if (!isSearching) {
      return InkWell(
        onTap: () => onSearchToggle(true),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: pos.fill,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.person_add_rounded,
                size: 18,
                color: cs.onSurfaceVariant.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 8),
              Text(
                'Link student (optional)',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
      );
    }


    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search Input
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  style: GoogleFonts.inter(fontSize: 13, color: cs.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Search by ID or name...',
                    hintStyle: GoogleFonts.inter(
                        fontSize: 13, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                    prefixIcon: Icon(Icons.search_rounded,
                        size: 18, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    ref.read(studentSearchQueryProvider.notifier).state = value;
                  },
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () {
                  controller.clear();
                  ref.read(studentSearchQueryProvider.notifier).state = '';
                  onSearchToggle(false);
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close_rounded,
                      size: 16, color: cs.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),

        // Results
        Builder(
          builder: (_) {
            final query = ref.watch(studentSearchQueryProvider);

            if (query.isEmpty) {
              return const SizedBox(height: 4);
            }

            final searchAsync = ref.watch(studentSearchResultsProvider);

            return searchAsync.when(
              loading: () => Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
                ),
              ),
              error: (_, __) => Padding(
                padding: const EdgeInsets.all(12),
                child: Text('Error loading students',
                    style: GoogleFonts.inter(color: pos.error, fontSize: 12)),
              ),
              data: (filtered) {
                if (filtered.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text('No students found',
                        style: GoogleFonts.inter(
                            color: cs.onSurfaceVariant, fontSize: 12)),
                  );
                }

                return ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 120),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: filtered.length.clamp(0, 5),
                    itemBuilder: (context, index) {
                      final student = filtered[index];
                      return InkWell(
                        onTap: () => onStudentSelected(student),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              Icon(Icons.person_rounded,
                                  size: 16, color: pos.info),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(student.name,
                                        style: GoogleFonts.inter(
                                            fontSize: 13, color: cs.onSurface)),
                                    Text('ID: ${student.id}',
                                        style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: cs.onSurfaceVariant)),
                                  ],
                                ),
                              ),
                              Text(
                                CurrencyFormatter.formatCompact(student.balance),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: pos.info,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
