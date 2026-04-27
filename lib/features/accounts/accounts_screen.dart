import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/pos_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_card.dart';
import '../../../providers/accounts_provider.dart';
import '../../../core/utils/exporter/csv_exporter_stub.dart'
    if (dart.library.html) '../../../core/utils/exporter/csv_exporter_web.dart'
    if (dart.library.io) '../../../core/utils/exporter/csv_exporter_mobile.dart';
import 'package:intl/intl.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final pos = context.pos;

    final filter = ref.watch(accountsDateFilterProvider);
    final txnsAsync = ref.watch(accountsTransactionsProvider);
    final summary = ref.watch(accountsSummaryProvider);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Accounts & Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Export CSV Report',
            onPressed: () => _exportCsv(context, ref),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Filter Row
          Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: AccountsDateFilter.values.map((f) {
                  final isSelected = filter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_getFilterLabel(f, ref)),
                      selected: isSelected,
                      onSelected: (val) async {
                        if (!val) return;
                        
                        if (f == AccountsDateFilter.custom) {
                          final range = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2023),
                            lastDate: DateTime.now().add(const Duration(days: 30)),
                            initialDateRange: ref.read(accountsCustomDateRangeProvider),
                          );
                          if (range != null) {
                            ref.read(accountsCustomDateRangeProvider.notifier).state = range;
                            ref.read(accountsDateFilterProvider.notifier).state = f;
                          }
                        } else {
                          ref.read(accountsDateFilterProvider.notifier).state = f;
                        }
                      },
                      selectedColor: cs.primary.withValues(alpha: 0.1),
                      labelStyle: GoogleFonts.inter(
                        color: isSelected ? cs.primary : cs.onSurfaceVariant,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected ? cs.primary : cs.outline.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Summary Cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: AppCard(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Actual Receipts',
                          style: GoogleFonts.inter(fontSize: 16, color: cs.onSurfaceVariant),
                        ),
                        Text(
                          CurrencyFormatter.format(summary.totalReceived),
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: pos.success,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 20),
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _SummaryBox(label: 'Cash', amount: summary.totalCash, color: cs.onSurface)),
                            const SizedBox(width: 16),
                            Expanded(child: _SummaryBox(label: 'UPI', amount: summary.totalUpi, color: cs.primary)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _SummaryBox(label: 'Wallet Usage', amount: summary.totalWallet, color: pos.info)),
                            const SizedBox(width: 16),
                            Expanded(child: _SummaryBox(label: 'New Debt', amount: summary.totalDebt, color: pos.error)),
                          ],
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Transaction List
          Expanded(
            child: txnsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (txns) {
                final displayItems = txns.where((t) => !t.isVoided).toList();
                if (displayItems.isEmpty) {
                  return Center(
                    child: Text('No transactions found for this period.',
                      style: GoogleFonts.inter(color: cs.onSurfaceVariant)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                  itemCount: displayItems.length,
                  itemBuilder: (ctx, idx) {
                    final t = displayItems[idx];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: cs.outline.withValues(alpha: 0.1)),
                        ),
                        tileColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                        title: Text(t.receiptId, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          DateFormatter.formatDateTime(t.createdAt),
                          style: GoogleFonts.inter(fontSize: 12),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              CurrencyFormatter.format(t.totalAmount),
                              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              t.paymentMode.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: cs.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }

  String _getFilterLabel(AccountsDateFilter filter, WidgetRef ref) {
    switch (filter) {
      case AccountsDateFilter.today: return 'Today';
      case AccountsDateFilter.thisWeek: return 'This Week';
      case AccountsDateFilter.thisMonth: return 'This Month';
      case AccountsDateFilter.allTime: return 'All Time';
      case AccountsDateFilter.custom:
        final range = ref.watch(accountsCustomDateRangeProvider);
        if (range != null) {
          return 'Custom: ${DateFormatter.formatDate(range.start)} - ${DateFormatter.formatDate(range.end)}';
        }
        return 'Custom Range';
    }
  }

  Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
    final txns = ref.read(accountsTransactionsProvider).valueOrNull ?? [];
    if (txns.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data to export.')),
      );
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln('Receipt ID,Date,Total Amount,Payment Mode,Cash,UPI,Wallet,Debt,Section,Student/Debtor Name');

    for (final t in txns) {
      if (t.isVoided) continue;
      buffer.writeln(
        '${t.receiptId},'
        '${DateFormatter.formatDateTime(t.createdAt)},'
        '${t.totalAmount},'
        '${t.paymentMode},'
        '${t.cashAmount},'
        '${t.upiAmount},'
        '${t.walletAmount},'
        '${t.debtAmount},'
        '${t.section},'
        '${t.studentName ?? ""}'
      );
    }

    try {
      final dateStr = DateFormat('yyyy_MM_dd_HH_mm').format(DateTime.now());
      await saveAndShareFile('Accounts_Report_$dateStr.csv', buffer.toString());
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report exported successfully!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export: $e')),
        );
      }
    }
  }
}

class _SummaryBox extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _SummaryBox({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 13, color: cs.onSurfaceVariant)),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.format(amount),
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
