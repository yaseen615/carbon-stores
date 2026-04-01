import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/csv_exporter.dart';
import '../../providers/transaction_providers.dart';
import '../../providers/expense_providers.dart';
import '../../providers/student_providers.dart';
import '../../providers/product_providers.dart';
import '../../providers/analytics_providers.dart';
import '../../data/models/student_model.dart';
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
    final totalDebt = ref.watch(totalDebtProvider);
    final currentFilter = ref.watch(analyticsDateFilterProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header ───
          Row(
            children: [
              Text('Analytics Dashboard',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppColors.onBackground)),
              const Spacer(),
              SegmentedButton<AnalyticsDateFilter>(
                segments: const [
                  ButtonSegment(value: AnalyticsDateFilter.today, label: Text('Today')),
                  ButtonSegment(value: AnalyticsDateFilter.thisMonth, label: Text('Month')),
                  ButtonSegment(value: AnalyticsDateFilter.thisYear, label: Text('Year')),
                  ButtonSegment(value: AnalyticsDateFilter.allTime, label: Text('All')),
                  ButtonSegment(value: AnalyticsDateFilter.custom, label: Text('Custom')),
                ],
                selected: {currentFilter},
                onSelectionChanged: (set) async {
                  final filter = set.first;
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
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: () => _exportReports(context, ref),
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('Export CSV'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ─── Summary Cards ───
          transactionsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (transactions) {
              final revenue = transactions.fold(0.0, (sum, t) => sum + t.paidAmount);
              final transactionCount = transactions.length;
              final profit = revenue - totalExpenses;

              return Column(
                children: [
                  Row(
                    children: [
                      _SummaryCard(
                        title: "Revenue",
                        value: CurrencyFormatter.format(revenue),
                        icon: Icons.trending_up_rounded,
                        color: AppColors.success,
                        subtitle: '$transactionCount transactions',
                      ),
                      _SummaryCard(
                        title: 'Total Expenses',
                        value: CurrencyFormatter.format(totalExpenses),
                        icon: Icons.trending_down_rounded,
                        color: AppColors.error,
                        subtitle: 'All time',
                      ),
                      _SummaryCard(
                        title: 'Profit/Loss',
                        value: CurrencyFormatter.format(profit),
                        icon: profit >= 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                        color: profit >= 0 ? AppColors.success : AppColors.error,
                        subtitle: profit >= 0 ? 'Profit' : 'Loss',
                      ),
                      _SummaryCard(
                        title: 'Student Wallets',
                        value: CurrencyFormatter.format(totalWallet),
                        icon: Icons.account_balance_wallet_rounded,
                        color: AppColors.info,
                        subtitle: 'Debt: ${CurrencyFormatter.formatCompact(totalDebt)}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ─── Charts Row ───
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Revenue Chart
                      Expanded(
                        flex: 2,
                        child: _RevenueChart(
                          transactions: transactions,
                          filter: currentFilter,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Top Products
                      Expanded(
                        child: _TopProductsCard(transactions: transactions),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ─── Recent Transactions ───
                  _RecentTransactionsCard(transactions: transactions),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _exportReports(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Export Reports', style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 20),
                _ExportOption(
                  icon: Icons.shopping_cart_rounded,
                  label: 'Sales Report',
                  onTap: () async {
                    final transactionsAsync = ref.read(filteredTransactionsProvider);
                    final transactions = transactionsAsync.maybeWhen(data: (d) => d, orElse: () => <StoreTransaction>[]);
                    await CsvExporter.exportSalesReport(transactions);
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Sales report exported!')));
                      Navigator.pop(ctx);
                    }
                  },
                ),
                _ExportOption(
                  icon: Icons.inventory_2_rounded,
                  label: 'Inventory Report',
                  onTap: () async {
                    final productsAsync = ref.read(productsStreamProvider);
                    final products = productsAsync.maybeWhen(data: (d) => d, orElse: () => <Product>[]);
                    await CsvExporter.exportInventoryReport(products);
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Inventory report exported!')));
                      Navigator.pop(ctx);
                    }
                  },
                ),
                _ExportOption(
                  icon: Icons.school_rounded,
                  label: 'Student Report',
                  onTap: () async {
                    final studentsAsync = ref.read(studentsStreamProvider);
                    final students = studentsAsync.maybeWhen(data: (d) => d, orElse: () => <Student>[]);
                    await CsvExporter.exportStudentReport(students);
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Student report exported!')));
                      Navigator.pop(ctx);
                    }
                  },
                ),
                _ExportOption(
                  icon: Icons.trending_down_rounded,
                  label: 'Expense Report',
                  onTap: () async {
                    final expensesAsync = ref.read(filteredExpensesProvider);
                    final expenses = expensesAsync.maybeWhen(data: (d) => d, orElse: () => <Expense>[]);
                    await CsvExporter.exportExpenseReport(expenses);
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Expense report exported!')));
                      Navigator.pop(ctx);
                    }
                  },
                ),
                _ExportOption(
                  icon: Icons.analytics_rounded,
                  label: 'Profit/Loss Report',
                  onTap: () async {
                    final transactionsAsync = ref.read(filteredTransactionsProvider);
                    final transactions = transactionsAsync.maybeWhen(data: (d) => d, orElse: () => <StoreTransaction>[]);
                    final expensesAsync = ref.read(filteredExpensesProvider);
                    final expenses = expensesAsync.maybeWhen(data: (d) => d, orElse: () => <Expense>[]);
                    
                    await CsvExporter.exportPandLReport(transactions, expenses);
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('P&L report exported!')));
                      Navigator.pop(ctx);
                    }
                  },
                ),
              ],
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

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 20, color: color),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 14),
              Text(title, style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12)),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RevenueChart extends StatelessWidget {
  final List<StoreTransaction> transactions;
  final AnalyticsDateFilter filter;

  const _RevenueChart({
    required this.transactions,
    required this.filter,
  });

  @override
  Widget build(BuildContext context) {
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

    final spots = dataMap.entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList()
      ..sort((a, b) => a.x.compareTo(b.x));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Revenue by $xLabel",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.onBackground)),
            const SizedBox(height: 20),
            SizedBox(
              height: 220,
              child: spots.isEmpty
                  ? Center(
                      child: Text('No data yet',
                          style: TextStyle(color: AppColors.onSurfaceVariant.withValues(alpha: 0.5))),
                    )
                  : BarChart(
                      BarChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: AppColors.divider,
                            strokeWidth: 0.5,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 50,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '₹${value.toInt()}',
                                  style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final label = value.toInt();
                                if (xLabel == 'Month') {
                                  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                                  return Text(
                                    label >= 1 && label <= 12 ? months[label - 1] : '',
                                    style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant),
                                  );
                                }
                                return Text(
                                  label.toString() + (xLabel == 'Hour' ? 'h' : ''),
                                  style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant),
                                );
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: dataMap.entries.map((e) {
                          return BarChartGroupData(
                            x: e.key,
                            barRods: [
                              BarChartRodData(
                                toY: e.value,
                                color: AppColors.primary,
                                width: xLabel == 'Day' ? 8 : 16,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(4),
                                  topRight: Radius.circular(4),
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
      ),
    );
  }
}

class _TopProductsCard extends StatelessWidget {
  final List<StoreTransaction> transactions;

  const _TopProductsCard({required this.transactions});

  @override
  Widget build(BuildContext context) {
    // Aggregate product sales
    final productSales = <String, int>{};
    for (final t in transactions) {
      for (final item in t.items) {
        productSales[item.name] = (productSales[item.name] ?? 0) + item.quantity;
      }
    }

    final sorted = productSales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top5 = sorted.take(5).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Top Products',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.onBackground)),
            const SizedBox(height: 16),
            if (top5.isEmpty)
              Center(
                child: Text('No data yet',
                    style: TextStyle(color: AppColors.onSurfaceVariant.withValues(alpha: 0.5))),
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
                              style: const TextStyle(fontSize: 13, color: AppColors.onSurface),
                              overflow: TextOverflow.ellipsis),
                        ),
                        Text('${item.value} sold',
                            style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: barWidth,
                        backgroundColor: AppColors.surfaceContainer,
                        color: AppColors.categoryColors[index % AppColors.categoryColors.length],
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _RecentTransactionsCard extends StatelessWidget {
  final List<StoreTransaction> transactions;

  const _RecentTransactionsCard({required this.transactions});

  @override
  Widget build(BuildContext context) {
    final recent = transactions.take(15).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Recent Transactions',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.onBackground)),
            const SizedBox(height: 12),
            if (recent.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text('No transactions in this period',
                      style: TextStyle(color: AppColors.onSurfaceVariant)),
                ),
              ),
            ...recent.map((t) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.successContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.receipt_rounded, size: 16, color: AppColors.success),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.receiptId,
                            style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppColors.onSurfaceVariant)),
                        Text(t.itemsSummary,
                            style: const TextStyle(fontSize: 13, color: AppColors.onSurface),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(CurrencyFormatter.format(t.totalAmount),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.onBackground)),
                      Text(t.paymentMode.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: t.paymentMode == 'wallet'
                                ? AppColors.info
                                : t.paymentMode == 'mixed'
                                    ? AppColors.warning
                                    : AppColors.onSurfaceVariant,
                          )),
                    ],
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class _ExportOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ExportOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontSize: 14, color: AppColors.onSurface)),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
