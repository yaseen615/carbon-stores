import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/responsive_helper.dart';
import '../../core/theme/pos_colors.dart';
import '../../data/models/audit_log_model.dart';
import '../../providers/audit_pagination_provider.dart';

class AuditScreen extends ConsumerStatefulWidget {
  const AuditScreen({super.key});

  @override
  ConsumerState<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends ConsumerState<AuditScreen> {
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
      ref.read(paginatedAuditProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
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
                Text('Audit Logs',
                    style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4)),
                const Spacer(),
                _buildFilterButton(),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Audit Logs',
                        style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4)),
                    _buildFilterButton(),
                  ],
                ),
              ],
            ),
          const SizedBox(height: 20),

          // ─── Logs Stream ───
          Expanded(
            child: ref.watch(paginatedAuditProvider).when(
              data: (paginatedState) {
                final logs = paginatedState.logs;
                if (logs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_rounded,
                            size: 56,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.2)),
                        const SizedBox(height: 16),
                        Text('No audit logs found',
                            style: GoogleFonts.inter(
                                color: cs.onSurfaceVariant, fontSize: 16)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: logs.length + (paginatedState.isLoadingMore ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    if (index == logs.length) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Center(
                            child: CircularProgressIndicator(
                                color: cs.primary, strokeWidth: 2.5)),
                      );
                    }
                    return _AuditLogTile(log: logs[index], isDark: isDark);
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

  Widget _buildFilterButton() {
    final filter = ref.watch(auditFilterProvider);
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
          ref.read(auditFilterProvider.notifier).state = AuditFilter(
            startDate: picked.start,
            endDate: picked.end.add(const Duration(days: 1)), // Include the full end day
          );
        } else if (hasFilter) {
          // Clear filter if they cancel and we had one?
          // Actually usually cancel should keep current.
          // Let's add a long press or a "Clear" option if needed, 
          // but for now let's just allow picking or resetting by picking a wide range.
          // Alternatively, we can use a custom dialog if more control is needed.
        }
      },
      onLongPress: hasFilter ? () {
        ref.read(auditFilterProvider.notifier).state = AuditFilter();
      } : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  : 'Filter By Date', 
              style: GoogleFonts.inter(
                fontSize: 14,
                color: hasFilter ? Theme.of(context).colorScheme.primary : null,
                fontWeight: hasFilter ? FontWeight.w600 : null,
              )
            ),
            if (hasFilter) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => ref.read(auditFilterProvider.notifier).state = AuditFilter(),
                child: Icon(Icons.close_rounded, size: 16, color: Theme.of(context).colorScheme.primary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AuditLogTile extends StatelessWidget {
  final AuditLog log;
  final bool isDark;

  const _AuditLogTile({required this.log, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pos = context.pos;

    IconData icon;
    Color color;

    switch (log.action) {
      case 'sale':
        icon = Icons.shopping_cart_checkout_rounded;
        color = pos.success;
        break;
      case 'recharge':
        icon = Icons.account_balance_wallet_rounded;
        color = pos.success;
        break;
      case 'edit':
        icon = Icons.edit_note_rounded;
        color = pos.warning;
        break;
      case 'stock_in':
        icon = Icons.add_box_rounded;
        color = cs.primary;
        break;
      case 'expense':
        icon = Icons.receipt_long_rounded;
        color = pos.error;
        break;
      case 'void':
        icon = Icons.cancel_rounded;
        color = pos.error;
        break;
      default:
        icon = Icons.info_outline_rounded;
        color = pos.info;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: isDark
            ? Border.all(color: Colors.white.withValues(alpha: 0.06), width: 0.5)
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        (log.action == 'void'
                                ? 'CANCEL PURCHASE'
                                : log.action)
                            .toUpperCase(),
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          color: color,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    Text(
                      DateFormatter.formatDateTime(log.timestamp),
                      style: GoogleFonts.inter(
                          color: cs.onSurfaceVariant, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(log.description,
                    style: GoogleFonts.inter(
                        color: cs.onSurface, fontSize: 14)),
                if (log.userId != null) ...[
                  const SizedBox(height: 4),
                  Text('User: ${log.userId}',
                      style: GoogleFonts.inter(
                          color: cs.onSurfaceVariant, fontSize: 11)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
