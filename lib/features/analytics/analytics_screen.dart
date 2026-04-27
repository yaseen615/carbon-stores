import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/pos_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/responsive_helper.dart';
import '../../core/utils/csv_exporter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/constants/store_section.dart';
import '../../providers/transaction_providers.dart';
import '../../providers/expense_providers.dart';
import '../../providers/student_providers.dart';
import '../../providers/product_providers.dart';
import '../../providers/analytics_providers.dart';
import '../../providers/store_section_provider.dart';

import '../../data/models/product_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/expense_model.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(filteredTransactionsProvider);
    final totalExpenses = ref.watch(totalFilteredExpensesProvider);
    final totalWallet = ref.watch(totalWalletBalanceProvider);
    final totalDebt = ref.watch(totalOverallDebtProvider);
    final currentFilter = ref.watch(analyticsDateFilterProvider);
    final cs = Theme.of(context).colorScheme;
    final pos = context.pos;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isDesktop = Responsive.isTabletOrDesktop(context);
    final isPhone = Responsive.isPhone(context);

    final topPadding = isPhone ? MediaQuery.paddingOf(context).top + 16 : 20.0;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          isDesktop ? 24 : 16, topPadding, isDesktop ? 24 : 16, isPhone ? 80 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header ───
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Analytics',
                  style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                      letterSpacing: -0.4)),
              InkWell(
                onTap: () => _exportReports(context, ref),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.ios_share_rounded, size: 20, color: cs.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ─── Section Filter (Cafe / Store / All) ───
          Consumer(
            builder: (context, ref, _) {
              final current = ref.watch(storeSectionProvider);
              const options = [StoreSection.all, StoreSection.cafe, StoreSection.store];
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: options.map((section) {
                    final isSelected = section == current;
                    final Color activeColor;
                    switch (section) {
                      case StoreSection.cafe:
                        activeColor = const Color(0xFF0090D9); // blue
                        break;
                      case StoreSection.store:
                        activeColor = const Color(0xFF34C759); // green
                        break;
                      default:
                        activeColor = cs.primary;
                    }
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => ref.read(storeSectionProvider.notifier).state = section,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                          decoration: BoxDecoration(
                            color: isSelected ? activeColor : activeColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? activeColor : activeColor.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                            boxShadow: isSelected ? [
                              BoxShadow(
                                color: activeColor.withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              )
                            ] : [],
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
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // ─── Filter Row (Apple Style Pills) ───
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _FilterChip(
                  label: 'Today',
                  filter: AnalyticsDateFilter.today,
                  currentFilter: currentFilter,
                  ref: ref,
                  context: context,
                ),
                _FilterChip(
                  label: 'This Month',
                  filter: AnalyticsDateFilter.thisMonth,
                  currentFilter: currentFilter,
                  ref: ref,
                  context: context,
                ),
                _FilterChip(
                  label: 'This Year',
                  filter: AnalyticsDateFilter.thisYear,
                  currentFilter: currentFilter,
                  ref: ref,
                  context: context,
                ),
                _FilterChip(
                  label: 'All Time',
                  filter: AnalyticsDateFilter.allTime,
                  currentFilter: currentFilter,
                  ref: ref,
                  context: context,
                ),
                _FilterChip(
                  label: 'Custom Range',
                  filter: AnalyticsDateFilter.custom,
                  currentFilter: currentFilter,
                  ref: ref,
                  context: context,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ─── Summary Cards ───
          transactionsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (transactions) {
              final revenue = transactions.fold(
                  0.0, (sum, t) => sum + t.paidAmount);
              final transactionCount = transactions.length;
              final profit = revenue - totalExpenses;

              return Column(
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final useGrid = constraints.maxWidth < 800;
                      if (useGrid) {
                        return GridView.count(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          crossAxisCount: 2,
                          crossAxisSpacing: isPhone ? 12 : 16,
                          mainAxisSpacing: isPhone ? 12 : 16,
                          childAspectRatio: isPhone ? 1.15 : 2.2,
                          children: [
                            _SummaryCard(
                              title: "Revenue",
                              value: CurrencyFormatter.format(revenue),
                              icon: Icons.trending_up_rounded,
                              color: pos.success,
                              subtitle: '$transactionCount transactions',
                              isDark: isDark,
                            ),
                            _SummaryCard(
                              title: 'Expenses',
                              value: CurrencyFormatter.format(totalExpenses),
                              icon: Icons.trending_down_rounded,
                              color: pos.error,
                              subtitle: 'All time',
                              isDark: isDark,
                            ),
                            _SummaryCard(
                              title: 'Profit/Loss',
                              value: CurrencyFormatter.format(profit),
                              icon: profit >= 0
                                  ? Icons.arrow_upward_rounded
                                  : Icons.arrow_downward_rounded,
                              color: profit >= 0 ? pos.success : pos.error,
                              subtitle: profit >= 0 ? 'Profit' : 'Loss',
                              isDark: isDark,
                            ),
                            _SummaryCard(
                              title: 'Wallets',
                              value: CurrencyFormatter.format(totalWallet),
                              icon: Icons.account_balance_wallet_rounded,
                              color: pos.info,
                              subtitle:
                                  'Debt: ${CurrencyFormatter.formatCompact(totalDebt)}',
                              isDark: isDark,
                            ),
                          ],
                        );
                      }
                      
                      return Row(
                        children: [
                          Expanded(
                            child: _SummaryCard(
                              title: "Revenue",
                              value: CurrencyFormatter.format(revenue),
                              icon: Icons.trending_up_rounded,
                              color: pos.success,
                              subtitle: '$transactionCount transactions',
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _SummaryCard(
                              title: 'Expenses',
                              value: CurrencyFormatter.format(totalExpenses),
                              icon: Icons.trending_down_rounded,
                              color: pos.error,
                              subtitle: 'All time',
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _SummaryCard(
                              title: 'Profit/Loss',
                              value: CurrencyFormatter.format(profit),
                              icon: profit >= 0
                                  ? Icons.arrow_upward_rounded
                                  : Icons.arrow_downward_rounded,
                              color: profit >= 0 ? pos.success : pos.error,
                              subtitle: profit >= 0 ? 'Profit' : 'Loss',
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _SummaryCard(
                              title: 'Wallets',
                              value: CurrencyFormatter.format(totalWallet),
                              icon: Icons.account_balance_wallet_rounded,
                              color: pos.info,
                              subtitle:
                                  'Debt: ${CurrencyFormatter.formatCompact(totalDebt)}',
                              isDark: isDark,
                            ),
                          ),
                        ],
                      );
                    }
                  ),
                  const SizedBox(height: 24),

                  // ─── Charts Row ───
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 600) {
                        return Column(
                          children: [
                            _RevenueChart(
                              transactions: transactions,
                              filter: currentFilter,
                              isDark: isDark,
                            ),
                            const SizedBox(height: 16),
                            _TopProductsCard(
                                transactions: transactions, isDark: isDark),
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: _RevenueChart(
                              transactions: transactions,
                              filter: currentFilter,
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _TopProductsCard(
                                transactions: transactions, isDark: isDark),
                          ),
                        ],
                      );
                    }
                  ),
                  const SizedBox(height: 20),

                  _RecentTransactionsCard(
                      transactions: transactions, isDark: isDark),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _exportReports(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    bool isExporting = false;
    String? exportingLabel;

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
                Row(
                  children: [
                    Text('Export Reports',
                        style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4)),
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
                        child: Icon(Icons.close_rounded,
                            size: 16, color: cs.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _ExportOption(
                  icon: Icons.shopping_cart_rounded,
                  label: 'Sales Report',
                  isExporting: isExporting && exportingLabel == 'Sales Report',
                  onTap: isExporting
                      ? null
                      : () async {
                          setState(() {
                            isExporting = true;
                            exportingLabel = 'Sales Report';
                          });
                          final transactionsAsync =
                              ref.read(filteredTransactionsProvider);
                          final transactions = transactionsAsync.maybeWhen(
                              data: (d) => d,
                              orElse: () => <StoreTransaction>[]);
                          final section = ref.read(storeSectionProvider).label;
                          await CsvExporter.exportSalesReport(transactions,
                              sectionPrefix: section);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                                content: Text('Sales report exported!')));
                            Navigator.pop(ctx);
                          }
                        },
                ),
                _ExportOption(
                  icon: Icons.inventory_2_rounded,
                  label: 'Inventory Report',
                  isExporting:
                      isExporting && exportingLabel == 'Inventory Report',
                  onTap: isExporting
                      ? null
                      : () async {
                          setState(() {
                            isExporting = true;
                            exportingLabel = 'Inventory Report';
                          });
                          final productsAsync = ref.read(productsStreamProvider);
                          final products = productsAsync.maybeWhen(
                              data: (d) => d, orElse: () => <Product>[]);
                          final section = ref.read(storeSectionProvider).label;
                          await CsvExporter.exportInventoryReport(products,
                              sectionPrefix: section);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                                content: Text('Inventory report exported!')));
                            Navigator.pop(ctx);
                          }
                        },
                ),
                _ExportOption(
                  icon: Icons.school_rounded,
                  label: 'Student Report',
                  isExporting: isExporting && exportingLabel == 'Student Report',
                  onTap: isExporting
                      ? null
                      : () async {
                          setState(() {
                            isExporting = true;
                            exportingLabel = 'Student Report';
                          });
                          // Show a quick snackbar so they know it's loading
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text('Generating Student Report...')));

                          final repo = ref.read(studentRepositoryProvider);
                          final students = await repo.getAllStudentsForExport();

                          await CsvExporter.exportStudentReport(students);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                                content: Text('Student report exported!')));
                            Navigator.pop(ctx);
                          }
                        },
                ),
                _ExportOption(
                  icon: Icons.trending_down_rounded,
                  label: 'Expense Report',
                  isExporting: isExporting && exportingLabel == 'Expense Report',
                  onTap: isExporting
                      ? null
                      : () async {
                          setState(() {
                            isExporting = true;
                            exportingLabel = 'Expense Report';
                          });
                          final expensesAsync = ref.read(filteredExpensesProvider);
                          final expenses = expensesAsync.maybeWhen(
                              data: (d) => d, orElse: () => <Expense>[]);
                          final section = ref.read(storeSectionProvider).label;
                          await CsvExporter.exportExpenseReport(expenses,
                              sectionPrefix: section);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                                content: Text('Expense report exported!')));
                            Navigator.pop(ctx);
                          }
                        },
                ),
                _ExportOption(
                  icon: Icons.analytics_rounded,
                  label: 'Profit/Loss Report',
                  onTap: () async {
                    final transactionsAsync =
                        ref.read(filteredTransactionsProvider);
                    final transactions = transactionsAsync.maybeWhen(
                        data: (d) => d,
                        orElse: () => <StoreTransaction>[]);
                    final expensesAsync = ref.read(filteredExpensesProvider);
                    final expenses = expensesAsync.maybeWhen(
                        data: (d) => d, orElse: () => <Expense>[]);
                    final section = ref.read(storeSectionProvider).label;

                    await CsvExporter.exportPandLReport(
                        transactions, expenses, sectionPrefix: section);
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                          content: Text('P&L report exported!')));
                      Navigator.pop(ctx);
                    }
                  },
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

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;
  final bool isDark;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isDark ? 0.05 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: isDark
            ? Border.all(color: Colors.white.withValues(alpha: 0.04), width: 0.5)
            : Border.all(color: cs.onSurface.withValues(alpha: 0.03), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    color: cs.onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.inter(
              color: cs.onSurface,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
            maxLines: 1,
            // Removes scaling overflow issues
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final AnalyticsDateFilter filter;
  final AnalyticsDateFilter currentFilter;
  final WidgetRef ref;
  final BuildContext context;

  const _FilterChip({
    required this.label,
    required this.filter,
    required this.currentFilter,
    required this.ref,
    required this.context,
  });

  @override
  Widget build(BuildContext _) {
    final cs = Theme.of(context).colorScheme;
    final isSelected = filter == currentFilter;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            if (filter == AnalyticsDateFilter.custom) {
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (range != null) {
                ref.read(analyticsCustomDateRangeProvider.notifier).state = range;
                ref.read(analyticsDateFilterProvider.notifier).state = filter;
              }
            } else {
              ref.read(analyticsDateFilterProvider.notifier).state = filter;
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? cs.primary : cs.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? cs.primary : cs.onSurfaceVariant.withValues(alpha: 0.2),
                width: 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: cs.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : [],
            ),
            child: Text(
              filter == AnalyticsDateFilter.custom && ref.watch(analyticsCustomDateRangeProvider) != null
                  ? 'Custom: ${DateFormatter.formatDate(ref.read(analyticsCustomDateRangeProvider)!.start)} - ${DateFormatter.formatDate(ref.read(analyticsCustomDateRangeProvider)!.end)}'
                  : label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RevenueChart extends StatelessWidget {
  final List<StoreTransaction> transactions;
  final AnalyticsDateFilter filter;
  final bool isDark;

  const _RevenueChart({
    required this.transactions,
    required this.filter,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pos = context.pos;

    String xLabel = 'Hour';
    final dataMap = <int, double>{};

    if (filter == AnalyticsDateFilter.today) {
      xLabel = 'Hour';
      for (final t in transactions) {
        final hour = t.createdAt.hour;
        dataMap[hour] = (dataMap[hour] ?? 0) + t.paidAmount;
      }
    } else if (filter == AnalyticsDateFilter.thisMonth) {
      xLabel = 'Day';
      for (final t in transactions) {
        final day = t.createdAt.day;
        dataMap[day] = (dataMap[day] ?? 0) + t.paidAmount;
      }
    } else {
      xLabel = 'Month';
      for (final t in transactions) {
        final month = t.createdAt.month;
        dataMap[month] = (dataMap[month] ?? 0) + t.paidAmount;
      }
    }

    double maxY = 10;
    if (dataMap.isNotEmpty) {
      final actualMax = dataMap.values.reduce((a, b) => a > b ? a : b);
      if (actualMax > 0) {
        if (actualMax <= 10) {
          maxY = 10;
        } else if (actualMax <= 50) {
          maxY = (actualMax / 10).ceil() * 10;
        } else if (actualMax <= 100) {
          maxY = (actualMax / 20).ceil() * 20;
        } else if (actualMax <= 1000) {
          maxY = (actualMax / 100).ceil() * 100;
        } else {
          maxY = (actualMax / 500).ceil() * 500;
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
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
            ? Border.all(color: Colors.white.withValues(alpha: 0.06), width: 0.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Revenue by $xLabel",
              style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface)),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: dataMap.isEmpty
                ? Center(
                    child: Text('No data yet',
                        style: GoogleFonts.inter(
                            color: cs.onSurfaceVariant.withValues(alpha: 0.4))),
                  )
                : BarChart(
                    BarChartData(
                      maxY: maxY,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: pos.divider,
                          strokeWidth: 0.5,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 50,
                            getTitlesWidget: (value, meta) {
                              if (value == meta.max && value != maxY) return const SizedBox.shrink();
                              return Text('₹${value.toInt()}',
                                  style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: cs.onSurfaceVariant));
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final label = value.toInt();
                              if (xLabel == 'Month') {
                                const months = [
                                  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                                  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                                ];
                                return Text(
                                  label >= 1 && label <= 12
                                      ? months[label - 1]
                                      : '',
                                  style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: cs.onSurfaceVariant),
                                );
                              }
                              return Text(
                                '${label}${xLabel == 'Hour' ? 'h' : ''}',
                                style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: cs.onSurfaceVariant),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: dataMap.entries.map((e) {
                        return BarChartGroupData(
                          x: e.key,
                          barRods: [
                            BarChartRodData(
                              toY: e.value,
                              color: cs.primary,
                              width: xLabel == 'Day' ? 8 : 16,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(6),
                                topRight: Radius.circular(6),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TopProductsCard extends StatelessWidget {
  final List<StoreTransaction> transactions;
  final bool isDark;

  const _TopProductsCard(
      {required this.transactions, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pos = context.pos;

    final productSales = <String, int>{};
    for (final t in transactions) {
      for (final item in t.items) {
        productSales[item.name] =
            (productSales[item.name] ?? 0) + item.quantity;
      }
    }

    final sorted = productSales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top5 = sorted.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(20),
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
            ? Border.all(color: Colors.white.withValues(alpha: 0.06), width: 0.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Top Products',
              style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface)),
          const SizedBox(height: 16),
          if (top5.isEmpty)
            Center(
              child: Text('No data yet',
                  style: GoogleFonts.inter(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.4))),
            ),
          ...top5.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final maxQty = top5.first.value;
            final barWidth = maxQty > 0 ? item.value / maxQty : 0.0;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(item.key,
                            style: GoogleFonts.inter(
                                fontSize: 13, color: cs.onSurface),
                            overflow: TextOverflow.ellipsis),
                      ),
                      Text('${item.value} sold',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: barWidth,
                      backgroundColor: pos.fill,
                      color: AppColors.categoryColors[
                          index % AppColors.categoryColors.length],
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _RecentTransactionsCard extends StatelessWidget {
  final List<StoreTransaction> transactions;
  final bool isDark;

  const _RecentTransactionsCard(
      {required this.transactions, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final recent = transactions.take(15).toList();
    final cs = Theme.of(context).colorScheme;
    final pos = context.pos;

    return Container(
      padding: const EdgeInsets.all(20),
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
            ? Border.all(color: Colors.white.withValues(alpha: 0.06), width: 0.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent Transactions',
              style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface)),
          const SizedBox(height: 12),
          if (recent.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text('No transactions in this period',
                    style: GoogleFonts.inter(color: cs.onSurfaceVariant)),
              ),
            ),
          ...recent.map((t) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: pos.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.receipt_rounded,
                          size: 14, color: pos.success),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.receiptId,
                              style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: cs.onSurfaceVariant)),
                          Text(t.itemsSummary,
                              style: GoogleFonts.inter(
                                  fontSize: 13, color: cs.onSurface),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(CurrencyFormatter.format(t.totalAmount),
                            style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: pos.fill,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            t.paymentMode.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: t.paymentMode == 'wallet'
                                  ? pos.info
                                  : t.paymentMode == 'mixed'
                                      ? pos.warning
                                      : cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _ExportOption extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isExporting;

  const _ExportOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isExporting = false,
  });

  @override
  State<_ExportOption> createState() => _ExportOptionState();
}

class _ExportOptionState extends State<_ExportOption> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pos = context.pos;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: _hovered ? pos.fill : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 20, color: cs.primary),
              const SizedBox(width: 12),
              Text(widget.label,
                  style: GoogleFonts.inter(
                      fontSize: 14, color: cs.onSurface)),
              const Spacer(),
              if (widget.isExporting)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.blue,
                  ),
                )
              else
                Icon(Icons.chevron_right_rounded,
                    size: 18, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
