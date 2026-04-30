import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/pos_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/search_field.dart';
import '../../core/services/student_sync_service.dart';
import '../../core/services/student_search_index.dart';
import '../../data/models/student_model.dart';
import '../../data/repositories/student_repository.dart';
import '../../data/repositories/audit_repository.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/student_providers.dart';
import '../../providers/navigation_provider.dart';
import 'widgets/student_detail_dialog.dart';
import 'widgets/balance_details_dialog.dart';
class StudentsScreen extends ConsumerStatefulWidget {
  const StudentsScreen({super.key});

  @override
  ConsumerState<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends ConsumerState<StudentsScreen> {
  bool _isSyncing = false;
  bool _isRefreshing = false;
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Load and initialize the search index
    final index = ref.read(studentSearchIndexProvider);
    index.load();
    // Infinite scroll — trigger loadMore at 80% scroll
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_searchQuery.isNotEmpty) return; // don't paginate during search
    final maxScroll = _scrollController.position.maxScrollExtent;
    final current = _scrollController.position.pixels;
    if (current >= maxScroll * 0.8) {
      ref.read(paginatedStudentsProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  /// Show confirmation dialog, then run sync with progress overlay
  Future<void> _syncStudents() async {
    if (_isSyncing) return;

    // ─── Step 1: Confirmation Dialog ───
    final confirmed = await _showConfirmationDialog();
    if (confirmed != true || !mounted) return;

    setState(() => _isSyncing = true);

    // ─── Step 2: Show progress dialog ───
    final progressNotifier = ValueNotifier<double>(0.0);
    final statusNotifier = ValueNotifier<String>(
      'Fetching students from server...',
    );

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SyncProgressDialog(
        progress: progressNotifier,
        status: statusNotifier,
      ),
    );

    try {
      final service = StudentSyncService(
        graphqlEndpoint: AppConstants.graphqlEndpoint,
      );

      final result = await service.syncStudents(
        onProgress: (processed, total) {
          if (total == 0) {
            // Still fetching from API
            statusNotifier.value = 'Fetching students from server...';
            progressNotifier.value = 0.0;
          } else {
            final pct = processed / total;
            progressNotifier.value = pct;
            statusNotifier.value =
                'Processing $processed of $total students (${(pct * 100).toInt()}%)';
          }
        },
      );

      // Close progress dialog
      if (mounted) Navigator.of(context).pop();

      if (!mounted) return;

      if (result.hasError) {
        _showSyncSnackBar(
          icon: Icons.error_outline_rounded,
          message: 'Sync failed: ${result.error}',
          isError: true,
        );
      } else {
        await AuditRepository().log(
          action: AppConstants.auditSync,
          description:
              'Synced students from API: ${result.newlyAdded} added, '
              '${result.updated} updated, '
              '${result.alreadyExisted} unchanged',
          metadata: {
            'total_fetched': result.totalFetched,
            'newly_added': result.newlyAdded,
            'updated': result.updated,
            'already_existed': result.alreadyExisted,
          },
        );

        // Rebuild search index after every successful sync
        await _rebuildSearchIndexFromFirestore();

        // Only refresh paginated UI if new students were actually added or updated
        if (result.newlyAdded > 0 || result.updated > 0) {
          ref.read(paginatedStudentsProvider.notifier).refresh();
          ref.invalidate(studentStatsProvider);
        }

        if (!mounted) return;
        _showSyncSnackBar(
          icon: Icons.check_circle_outline_rounded,
          message: (result.newlyAdded > 0 || result.updated > 0)
              ? 'Students synced! '
                    '${result.newlyAdded} new, ${result.updated} updated, ${result.alreadyExisted} unchanged'
              : 'All students are already up to date '
                    '(${result.alreadyExisted} unchanged)',
          isError: false,
        );
      }
    } catch (e) {
      // Close progress dialog if still open
      if (mounted) Navigator.of(context).pop();

      if (!mounted) return;
      _showSyncSnackBar(
        icon: Icons.error_outline_rounded,
        message: 'Unexpected error: ${e.toString()}',
        isError: true,
      );
    } finally {
      progressNotifier.dispose();
      statusNotifier.dispose();
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  /// Shows a styled confirmation dialog. Returns true if user taps OK.
  Future<bool?> _showConfirmationDialog() {
    final cs = Theme.of(context).colorScheme;
    final pos = context.pos;

    return showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        backgroundColor: cs.surface,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: pos.info.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.sync_rounded, color: pos.info, size: 28),
                ),
                const SizedBox(height: 20),
                Text(
                  'Sync Students',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'This will add new students and update the names of existing students. '
                  'Balances and existing debts will never be affected.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: cs.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(
                              color: cs.onSurfaceVariant.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: pos.info,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Sync Now',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSyncSnackBar({
    required IconData icon,
    required String message,
    required bool isError,
  }) {
    final pos = context.pos;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? pos.error : pos.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Rebuilds the local search index from Firestore.
  /// Called ONLY after sync — one full read to populate the cache.
  Future<void> _rebuildSearchIndexFromFirestore() async {
    final repo = ref.read(studentRepositoryProvider);
    final allStudents = await repo.getAllStudentsForExport();
    final index = ref.read(studentSearchIndexProvider);
    await index.rebuild(
      allStudents
          .map((s) => StudentIndexEntry(studentId: s.id, name: s.name))
          .toList(),
    );
  }

  Future<void> _onRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      ref.read(paginatedStudentsProvider.notifier).refresh();
      ref.invalidate(studentStatsProvider);
      ref.invalidate(studentsStreamProvider); // Refresh search data too
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final paginatedState = ref.watch(paginatedStudentsProvider);
    final totalBalance = ref.watch(totalWalletBalanceProvider);
    final totalDebt = ref.watch(totalDebtProvider);
    final searchResults = ref.watch(studentSearchResultsProvider);
    final cs = Theme.of(context).colorScheme;
    final pos = context.pos;

    final isSearching = _searchQuery.isNotEmpty;
    final screenWidth = MediaQuery.of(context).size.width;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header ───
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Students',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                    letterSpacing: -0.4,
                  ),
                ),
                if (screenWidth > 600) const SizedBox(width: 8),
                _StatChip(
                  label: 'Balance',
                  value: CurrencyFormatter.formatCompact(totalBalance),
                  color: pos.info,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => const BalanceDetailsDialog(),
                    );
                  },
                ),
                _StatChip(
                  label: 'Debt',
                  value: CurrencyFormatter.formatCompact(totalDebt),
                  color: pos.error,
                  onTap: () {
                    ref.read(currentPageProvider.notifier).state = AppPage.debts;
                  },
                ),
                _SyncButton(isSyncing: _isSyncing, onPressed: _syncStudents),
                ElevatedButton.icon(
                  onPressed: () => _showAddStudentDialog(context),
                  icon: const Icon(Icons.person_add_rounded, size: 18),
                  label: const Text('Add Student'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search + Refresh
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Row(
                children: [
                  Expanded(
                    child: SearchField(
                      hintText: 'Search by name or ID...',
                      onChanged: (query) {
                        setState(() => _searchQuery = query);
                        // Debounce Firestore queries — 300ms after user stops typing
                        _debounce?.cancel();
                        _debounce = Timer(const Duration(milliseconds: 300), () {
                          ref.read(studentSearchQueryProvider.notifier).state =
                              query;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  _AppleRefreshButton(
                    onPressed: _onRefresh,
                    isRefreshing: _isRefreshing,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ─── Students Grid ───
            Expanded(
              child: _buildStudentGrid(
                context: context,
                isSearching: isSearching,
                paginatedState: paginatedState,
                searchResults: searchResults,
                cs: cs,
                pos: pos,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentGrid({
    required BuildContext context,
    required bool isSearching,
    required PaginatedStudentsState paginatedState,
    required AsyncValue<List<Student>> searchResults,
    required ColorScheme cs,
    required POSColors pos,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 1100 ? 3 : screenWidth > 700 ? 2 : 1;

    // ─── Search Mode ───
    if (isSearching) {
      return searchResults.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: cs.primary, strokeWidth: 2.5),
        ),
        error: (error, _) => Center(
          child: Text('Error: $error', style: TextStyle(color: pos.error)),
        ),
        data: (students) {
          if (students.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 56,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No students found',
                    style: GoogleFonts.inter(
                      color: cs.onSurfaceVariant,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }
          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              mainAxisExtent: 130,
            ),
            itemCount: students.length,
            itemBuilder: (context, index) {
              return _StudentCard(
                student: students[index],
                onRechargeSuccess: _onRefresh,
              );
            },
          );
        },
      );
    }

    // ─── Paginated Mode (default) ───
    if (paginatedState.isLoading) {
      return Center(
        child: CircularProgressIndicator(color: cs.primary, strokeWidth: 2.5),
      );
    }

    if (paginatedState.error != null) {
      return Center(
        child: Text(
          'Error: ${paginatedState.error}',
          style: TextStyle(color: pos.error),
        ),
      );
    }

    if (paginatedState.students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 56,
              color: cs.onSurfaceVariant.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'No students found',
              style: GoogleFonts.inter(
                color: cs.onSurfaceVariant,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    final students = paginatedState.students;
    // +1 for loading indicator when loadingMore
    final itemCount = students.length + (paginatedState.hasMore ? 1 : 0);

    return GridView.builder(
      controller: _scrollController,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        mainAxisExtent: 130,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index >= students.length) {
          // Loading indicator at the end
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: paginatedState.isLoadingMore
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.primary,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          );
        }
        return _StudentCard(
          student: students[index],
          onRechargeSuccess: _onRefresh,
        );
      },
    );
  }

  void _showAddStudentDialog(BuildContext context) {
    final idController = TextEditingController();
    final nameController = TextEditingController();
    final balanceController = TextEditingController(text: '0');
    final pos = context.pos;
    final cs = Theme.of(context).colorScheme;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        backgroundColor: Theme.of(ctx).colorScheme.surface,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Add Student',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: idController,
                  decoration: const InputDecoration(
                    labelText: 'Admission Number',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: balanceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Initial Balance (₹)',
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : () async {
                      if (idController.text.isEmpty ||
                          nameController.text.isEmpty) {
                        return;
                      }
                      setState(() => isSaving = true);
                      final student = Student(
                        id: idController.text.trim(),
                        name: nameController.text.trim(),
                        balance: double.tryParse(balanceController.text) ?? 0,
                        debt: 0,
                        updatedAt: DateTime.now(),
                      );
                      try {
                        await StudentRepository().addStudent(student);
                        await AuditRepository().log(
                          action: AppConstants.auditEdit,
                          description:
                              'Added student: ${student.name} (${student.id})',
                        );
                        // Update local search index
                        final index = ref.read(studentSearchIndexProvider);
                        await index.addEntry(
                          StudentIndexEntry(
                            studentId: student.id,
                            name: student.name,
                          ),
                        );
                        // Refresh paginated list & stats
                        ref.read(paginatedStudentsProvider.notifier).refresh();
                        ref.invalidate(studentStatsProvider);
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        setState(() => isSaving = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text(
                                e.toString().replaceAll('Exception: ', ''),
                              ),
                              backgroundColor: pos.error,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Add Student',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}

/// Animated sync button with loading state
class _SyncButton extends StatelessWidget {
  final bool isSyncing;
  final VoidCallback onPressed;

  const _SyncButton({required this.isSyncing, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pos = context.pos;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: ElevatedButton.icon(
        onPressed: isSyncing ? null : onPressed,
        icon: isSyncing
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(
                    cs.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ),
              )
            : Icon(Icons.sync_rounded, size: 18, color: pos.info),
        label: Text(
          isSyncing ? 'Syncing...' : 'Sync Students',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSyncing
                ? cs.onSurfaceVariant.withValues(alpha: 0.5)
                : pos.info,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: pos.info.withValues(alpha: 0.08),
          foregroundColor: pos.info,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSyncing
                  ? Colors.transparent
                  : pos.info.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}

/// Progress dialog shown during sync — animated circular progress + percentage
class _SyncProgressDialog extends StatelessWidget {
  final ValueNotifier<double> progress;
  final ValueNotifier<String> status;

  const _SyncProgressDialog({required this.progress, required this.status});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pos = context.pos;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: cs.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ─── Circular Progress with Percentage ───
              ValueListenableBuilder<double>(
                valueListenable: progress,
                builder: (_, value, __) {
                  final pct = (value * 100).toInt();
                  return SizedBox(
                    width: 100,
                    height: 100,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: CircularProgressIndicator(
                            value: value > 0 ? value : null,
                            strokeWidth: 6,
                            backgroundColor: pos.info.withValues(alpha: 0.12),
                            valueColor: AlwaysStoppedAnimation(pos.info),
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        if (value > 0)
                          Text(
                            '$pct%',
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: pos.info,
                            ),
                          )
                        else
                          Icon(Icons.sync_rounded, color: pos.info, size: 28),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // ─── Title ───
              Text(
                'Syncing Students',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 10),

              // ─── Status Text ───
              ValueListenableBuilder<String>(
                valueListenable: status,
                builder: (_, text, __) => Text(
                  text,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: cs.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ─── Linear Progress Bar ───
              ValueListenableBuilder<double>(
                valueListenable: progress,
                builder: (_, value, __) => ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: value > 0 ? value : null,
                    minHeight: 6,
                    backgroundColor: pos.info.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation(pos.info),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StudentCard extends StatefulWidget {
  final Student student;
  final VoidCallback onRechargeSuccess;

  const _StudentCard({
    required this.student,
    required this.onRechargeSuccess,
  });

  @override
  State<_StudentCard> createState() => _StudentCardState();
}

class _StudentCardState extends State<_StudentCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleCtrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pos = context.pos;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => _scaleCtrl.forward(),
      onTapUp: (_) {
        _scaleCtrl.reverse();
        showDialog(
          context: context,
          builder: (ctx) => StudentDetailDialog(student: widget.student),
        );
      },
      onTapCancel: () => _scaleCtrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: isDark
                ? Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                    width: 0.5,
                  )
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  // Circular avatar
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        widget.student.name.isNotEmpty
                            ? widget.student.name[0].toUpperCase()
                            : '?',
                        style: GoogleFonts.inter(
                          color: cs.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.student.name,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'ID: ${widget.student.id}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  // Balance pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: pos.info.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      CurrencyFormatter.formatCompact(widget.student.balance),
                      style: GoogleFonts.inter(
                        color: pos.info,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (widget.student.hasDebt) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: pos.error.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '-${CurrencyFormatter.formatCompact(widget.student.debt)}',
                        style: GoogleFonts.inter(
                          color: pos.error,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  SizedBox(
                    height: 30,
                    child: TextButton.icon(
                      onPressed: () =>
                          _showRechargeDialog(context, widget.student),
                      icon: Icon(
                        Icons.add_circle_outline_rounded,
                        size: 14,
                        color: cs.primary,
                      ),
                      label: Text(
                        'Recharge',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: cs.primary,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRechargeDialog(BuildContext context, Student student) {
    final amountController = TextEditingController();
    final cs = Theme.of(context).colorScheme;
    final pos = context.pos;

    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
          backgroundColor: Theme.of(ctx).colorScheme.surface,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recharge Wallet',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${student.name} (${student.id})',
                  style: GoogleFonts.inter(
                    color: cs.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Current Balance: ',
                      style: GoogleFonts.inter(
                        color: cs.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(student.balance),
                      style: GoogleFonts.inter(
                        color: pos.info,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                if (student.hasDebt) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Current Debt: ',
                        style: GoogleFonts.inter(
                          color: cs.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(student.debt),
                        style: GoogleFonts.inter(
                          color: pos.error,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: pos.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 14,
                          color: pos.warning,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Debt will be automatically cleared from recharge amount',
                            style: GoogleFonts.inter(
                              color: pos.warning,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Recharge Amount (₹)',
                    prefixText: '₹ ',
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            final amount =
                                double.tryParse(amountController.text);
                            if (amount == null || amount <= 0) return;

                            setState(() => isSaving = true);
                            try {
                              await StudentRepository().rechargeWallet(
                                student.id,
                                amount,
                              );
                              await AuditRepository().log(
                                action: AppConstants.auditRecharge,
                                description:
                                    'Recharged ${student.name}: ${CurrencyFormatter.format(amount)}',
                                metadata: {
                                  'student_id': student.id,
                                  'amount': amount
                                },
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                              widget.onRechargeSuccess();
                            } catch (e) {
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $e'),
                                    backgroundColor: pos.error,
                                  ),
                                );
                              }
                              setState(() => isSaving = false);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: pos.info,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: pos.info.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Recharge',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  color: color.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                value,
                style: GoogleFonts.inter(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppleRefreshButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isRefreshing;

  const _AppleRefreshButton({
    required this.onPressed,
    required this.isRefreshing,
  });

  @override
  State<_AppleRefreshButton> createState() => _AppleRefreshButtonState();
}

class _AppleRefreshButtonState extends State<_AppleRefreshButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotateCtrl;

  @override
  void initState() {
    super.initState();
    _rotateCtrl = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(_AppleRefreshButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRefreshing && !oldWidget.isRefreshing) {
      _rotateCtrl.forward(from: 0);
    } else if (!widget.isRefreshing && oldWidget.isRefreshing) {
      _rotateCtrl.stop();
      _rotateCtrl.reset();
    }
  }

  @override
  void dispose() {
    _rotateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: widget.isRefreshing ? null : widget.onPressed,
      child: AnimatedBuilder(
        animation: _rotateCtrl,
        builder: (_, child) => Transform.rotate(
          angle: _rotateCtrl.value * 2 * 3.14159,
          child: child,
        ),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: isDark
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.08),
                      Colors.white.withValues(alpha: 0.04),
                    ],
                  )
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFFFFF), Color(0xFFF2F2F7)],
                  ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                blurRadius: isDark ? 8 : 4,
                offset: const Offset(0, 2),
              ),
              if (!isDark)
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.8),
                  blurRadius: 1,
                  offset: const Offset(0, 1),
                ),
            ],
            border: isDark
                ? Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                    width: 0.5,
                  )
                : null,
          ),
          child: Center(
            child: widget.isRefreshing
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(cs.primary),
                    ),
                  )
                : Icon(Icons.refresh_rounded, size: 22, color: cs.primary),
          ),
        ),
      ),
    );
  }
}
