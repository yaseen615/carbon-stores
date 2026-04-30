import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/pos_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/search_field.dart';
import '../../../providers/student_providers.dart';

enum SortOption { nameAsc, nameDesc, balanceAsc, balanceDesc }

class BalanceDetailsDialog extends ConsumerStatefulWidget {
  const BalanceDetailsDialog({super.key});

  @override
  ConsumerState<BalanceDetailsDialog> createState() =>
      _BalanceDetailsDialogState();
}

class _BalanceDetailsDialogState extends ConsumerState<BalanceDetailsDialog> {
  String _searchQuery = '';
  SortOption _sortOption = SortOption.nameAsc;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pos = context.pos;
    final studentsAsync = ref.watch(studentsStreamProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: cs.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: pos.info.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.account_balance_wallet_rounded,
                        color: pos.info, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Balance Details',
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                            letterSpacing: -0.4,
                          ),
                        ),
                        Text(
                          'Students with positive wallet balance',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant),
                    tooltip: 'Close',
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Search & Sort Bar
              Row(
                children: [
                  Expanded(
                    child: SearchField(
                      hintText: 'Search by name or ID...',
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.2),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<SortOption>(
                        value: _sortOption,
                        icon: Icon(Icons.sort_rounded,
                            color: cs.onSurfaceVariant, size: 20),
                        style: GoogleFonts.inter(
                          color: cs.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        dropdownColor: cs.surface,
                        borderRadius: BorderRadius.circular(12),
                        onChanged: (val) {
                          if (val != null) setState(() => _sortOption = val);
                        },
                        items: const [
                          DropdownMenuItem(
                            value: SortOption.nameAsc,
                            child: Text('Name (A-Z)'),
                          ),
                          DropdownMenuItem(
                            value: SortOption.nameDesc,
                            child: Text('Name (Z-A)'),
                          ),
                          DropdownMenuItem(
                            value: SortOption.balanceDesc,
                            child: Text('Balance (High to Low)'),
                          ),
                          DropdownMenuItem(
                            value: SortOption.balanceAsc,
                            child: Text('Balance (Low to High)'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Student List
              Expanded(
                child: studentsAsync.when(
                  loading: () => Center(
                    child: CircularProgressIndicator(
                      color: cs.primary,
                      strokeWidth: 2.5,
                    ),
                  ),
                  error: (err, _) => Center(
                    child: Text(
                      'Error loading balances: \$err',
                      style: GoogleFonts.inter(color: pos.error),
                    ),
                  ),
                  data: (students) {
                    // Filter: balance > 0
                    var filtered = students
                        .where((s) => s.balance > 0)
                        .toList();

                    // Search
                    if (_searchQuery.trim().isNotEmpty) {
                      final q = _searchQuery.trim().toLowerCase();
                      filtered = filtered.where((s) {
                        return s.name.toLowerCase().contains(q) ||
                            s.id.toLowerCase().contains(q);
                      }).toList();
                    }

                    // Sort
                    filtered.sort((a, b) {
                      switch (_sortOption) {
                        case SortOption.nameAsc:
                          return a.name
                              .toLowerCase()
                              .compareTo(b.name.toLowerCase());
                        case SortOption.nameDesc:
                          return b.name
                              .toLowerCase()
                              .compareTo(a.name.toLowerCase());
                        case SortOption.balanceAsc:
                          return a.balance.compareTo(b.balance);
                        case SortOption.balanceDesc:
                          return b.balance.compareTo(a.balance);
                      }
                    });

                    if (filtered.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.account_balance_wallet_outlined,
                              size: 48,
                              color: cs.onSurfaceVariant.withValues(alpha: 0.2),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No balances found.',
                              style: GoogleFonts.inter(
                                color: cs.onSurfaceVariant,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.1),
                      ),
                      itemBuilder: (context, index) {
                        final student = filtered[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: pos.info.withValues(alpha: 0.1),
                            foregroundColor: pos.info,
                            child: Text(
                              student.name.isNotEmpty
                                  ? student.name[0].toUpperCase()
                                  : '?',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            student.name,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: cs.onSurface,
                            ),
                          ),
                          subtitle: Text(
                            'ID: ${student.id}',
                            style: GoogleFonts.inter(
                              color: cs.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                          trailing: Text(
                            CurrencyFormatter.format(student.balance),
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: pos.info,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
