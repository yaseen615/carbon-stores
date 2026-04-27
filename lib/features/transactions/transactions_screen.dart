import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/pos_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/responsive_helper.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/constants/store_section.dart';
import '../../data/models/transaction_model.dart';
import '../../providers/transaction_pagination_provider.dart';
import '../pos/widgets/receipt_dialog.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  String _searchQuery = '';
  StoreSection _sectionFilter = StoreSection.all; // local, screen-specific
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(paginatedTransactionsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final paginatedAsync = ref.watch(paginatedTransactionsProvider);
    final cs = Theme.of(context).colorScheme;
    final pos = context.pos;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isDesktop = Responsive.isTabletOrDesktop(context);
    final isPhone = Responsive.isPhone(context);
    final topPadding = isPhone ? MediaQuery.paddingOf(context).top + 16 : 20.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(isDesktop ? 24 : 16, topPadding, isDesktop ? 24 : 16, isPhone ? 8 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header ───
          if (isDesktop)
            Row(
              children: [
                Text('Transactions',
                    style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4)),
                const Spacer(),
                SizedBox(
                  width: 300,
                  child: _buildSearchField(cs),
                ),
                const SizedBox(width: 12),
                _buildFilterButton(),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Transactions',
                        style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4)),
                    const Spacer(),
                    _buildFilterButton(),
                  ],
                ),
                const SizedBox(height: 12),
                _buildSearchField(cs),
              ],
            ),
          const SizedBox(height: 16),

          // ─── Section Filter Tabs ───
          _SectionFilterRow(
            current: _sectionFilter,
            onChanged: (s) => setState(() => _sectionFilter = s),
          ),
          const SizedBox(height: 16),

          // ─── List ───
          Expanded(
            child: paginatedAsync.when(
              data: (paginatedState) {
                final transactions = paginatedState.transactions;
                final query = _searchQuery.toLowerCase();
                var filtered = transactions.where((t) {
                  final matchReceipt =
                      t.receiptId.toLowerCase().contains(query);
                  final matchName =
                      t.studentName?.toLowerCase().contains(query) ?? false;
                  final matchId =
                      t.studentId?.toLowerCase().contains(query) ?? false;
                  return matchReceipt || matchName || matchId;
                }).toList();

                // Filter by local section selection
                if (_sectionFilter != StoreSection.all) {
                  filtered = filtered.where((t) =>
                      t.section == _sectionFilter.firestoreValue ||
                      t.section == 'combined').toList();
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined,
                            size: 56,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.2)),
                        const SizedBox(height: 16),
                        Text('No transactions found',
                            style: GoogleFonts.inter(
                                color: cs.onSurfaceVariant, fontSize: 16)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  controller: _scrollController,
                  padding: EdgeInsets.only(bottom: isPhone ? 80 : 24),
                  itemCount: filtered.length + (paginatedState.isLoadingMore ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    if (index == filtered.length) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Center(
                            child: CircularProgressIndicator(
                                color: cs.primary, strokeWidth: 2.5)),
                      );
                    }
                    return _TransactionCard(
                        key: ValueKey(filtered[index].id),
                        transaction: filtered[index],
                        isDark: isDark);
                  },
                );
              },
              loading: () => Center(
                  child: CircularProgressIndicator(
                      color: cs.primary, strokeWidth: 2.5)),
              error: (err, _) => Center(
                  child: Text('Error: $err',
                      style: TextStyle(color: pos.error))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(ColorScheme cs) {
    return TextField(
      onChanged: (val) => setState(() => _searchQuery = val),
      style: GoogleFonts.inter(fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Search receipt or student...',
        hintStyle: GoogleFonts.inter(
            fontSize: 14,
            color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
        prefixIcon: Icon(Icons.search_rounded,
            size: 18,
            color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 0),
      ),
    );
  }

  Widget _buildFilterButton() {
    final filter = ref.watch(transactionFilterProvider);
    final hasFilter = filter.startDate != null || filter.endDate != null;

    return InkWell(
      onTap: () async {
        final DateTimeRange? picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2023),
          lastDate: DateTime.now().add(const Duration(days: 1)),
          initialDateRange: filter.startDate != null && filter.endDate != null
              ? DateTimeRange(start: filter.startDate!, end: filter.endDate!)
              : null,
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Theme.of(context).colorScheme.primary,
                  onPrimary: Theme.of(context).colorScheme.onPrimary,
                  surface: Theme.of(context).colorScheme.surface,
                  onSurface: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              child: child!,
            );
          },
        );

        if (picked != null) {
          ref.read(transactionFilterProvider.notifier).state = TransactionFilter(
            startDate: picked.start,
            endDate: picked.end.add(const Duration(days: 1)), // Include full end day
          );
        }
      },
      onLongPress: hasFilter ? () {
        ref.read(transactionFilterProvider.notifier).state = TransactionFilter();
      } : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(
            color: hasFilter 
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)
          ),
          borderRadius: BorderRadius.circular(12),
          color: hasFilter ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.05) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasFilter ? Icons.date_range_rounded : Icons.filter_list_rounded, 
              size: 18,
              color: hasFilter ? Theme.of(context).colorScheme.primary : null,
            ),
            const SizedBox(width: 8),
            Text(
              hasFilter 
                  ? "${DateFormatter.formatDate(filter.startDate!)} - ${DateFormatter.formatDate(filter.endDate!.subtract(const Duration(days: 1)))}"
                  : 'Filter', 
              style: GoogleFonts.inter(
                fontSize: 14,
                color: hasFilter ? Theme.of(context).colorScheme.primary : null,
                fontWeight: hasFilter ? FontWeight.w600 : null,
              )
            ),
            if (hasFilter) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => ref.read(transactionFilterProvider.notifier).state = TransactionFilter(),
                child: Icon(Icons.close_rounded, size: 16, color: Theme.of(context).colorScheme.primary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TransactionCard extends StatefulWidget {
  final StoreTransaction transaction;
  final bool isDark;

  const _TransactionCard({super.key, required this.transaction, required this.isDark});

  @override
  State<_TransactionCard> createState() => _TransactionCardState();
}

class _TransactionCardState extends State<_TransactionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleCtrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
        duration: const Duration(milliseconds: 120), vsync: this);
    _scale = Tween<double>(begin: 1.0, end: 0.98)
        .animate(CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeInOut));
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
    final txn = widget.transaction;

    return GestureDetector(
      onTapDown: (_) => _scaleCtrl.forward(),
      onTapUp: (_) {
        _scaleCtrl.reverse();
        showDialog(
          context: context,
          builder: (context) => ReceiptDialog(
            receiptId: txn.receiptId,
            items: txn.items,
            totalAmount: txn.totalAmount,
            paymentMode: txn.paymentMode,
            walletDeducted: txn.paidAmount -
                (txn.paymentMode == 'cash' ? txn.paidAmount : 0),
            cashAmount: txn.paymentMode == 'cash' ||
                    txn.paymentMode == 'mixed'
                ? txn.paidAmount
                : 0,
            debtAmount: txn.debtAmount,
            studentName: txn.studentName,
            transaction: txn,
          ),
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
            color: txn.isVoided
                ? pos.error.withValues(alpha: 0.04)
                : cs.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withValues(alpha: widget.isDark ? 0.2 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: widget.isDark
                ? Border.all(
                    color: Colors.white.withValues(alpha: 0.06), width: 0.5)
                : null,
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (txn.isVoided ? pos.error : cs.primary)
                      .withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  txn.isVoided
                      ? Icons.cancel_rounded
                      : Icons.receipt_long_rounded,
                  size: 20,
                  color: txn.isVoided ? pos.error : cs.primary,
                ),
              ),
              const SizedBox(width: 14),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            txn.receiptId,
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (txn.isVoided) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: pos.error.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text('CANCELLED',
                                style: GoogleFonts.inter(
                                    fontSize: 9,
                                    color: pos.error,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormatter.formatDateTime(txn.createdAt),
                      style: GoogleFonts.inter(
                          fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                    if (txn.studentName != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.person_outline_rounded,
                              size: 12, color: cs.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(txn.studentName!,
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: cs.onSurfaceVariant)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Payment Info
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.format(txn.totalAmount),
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: txn.isVoided ? pos.error : cs.onSurface,
                      decoration: txn.isVoided
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: pos.fill,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      txn.paymentMode.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  _SectionChip(section: txn.section),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────
//  SECTION FILTER ROW — All | Cafe | Store (highlighted pills)
// ───────────────────────────────────────────────────────────────

class _SectionFilterRow extends StatelessWidget {
  final StoreSection current;
  final ValueChanged<StoreSection> onChanged;

  const _SectionFilterRow({
    required this.current,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pos = context.pos;

    // Only show All / Cafe / Store (not combined — combined is for transaction data only)
    const options = [StoreSection.all, StoreSection.cafe, StoreSection.store];

    return Row(
      children: options.map((section) {
        final isSelected = section == current;

        Color activeColor;
        switch (section) {
          case StoreSection.cafe:
            activeColor = pos.info;
            break;
          case StoreSection.store:
            activeColor = pos.success;
            break;
          default:
            activeColor = cs.primary;
        }

        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => onChanged(section),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? activeColor
                    : activeColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? activeColor
                      : activeColor.withValues(alpha: 0.25),
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: activeColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ]
                    : [],
              ),
              child: Text(
                '${section.emoji} ${section.label}',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : activeColor,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Small inline chip showing the section of a transaction.
class _SectionChip extends StatelessWidget {
  final String section; // raw Firestore string: 'cafe', 'store', 'combined'
  const _SectionChip({required this.section});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pos = context.pos;

    final s = StoreSection.fromString(section);
    final Color color;
    switch (s) {
      case StoreSection.cafe:
        color = pos.info;
        break;
      case StoreSection.combined:
        color = cs.primary;
        break;
      default:
        color = pos.success;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '${s.emoji} ${s.label}',
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
