import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/pos_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/responsive_helper.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/expense_model.dart';
import '../../data/repositories/expense_repository.dart';
import '../../data/repositories/audit_repository.dart';
import '../../providers/expense_providers.dart';

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesStreamProvider);
    final totalExpenses = ref.watch(totalExpensesProvider);
    final cs = Theme.of(context).colorScheme;
    final pos = context.pos;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isDesktop = Responsive.isTabletOrDesktop(context);
    final isPhone = Responsive.isPhone(context);
    final topPadding = isPhone ? MediaQuery.paddingOf(context).top + 16 : 20.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(isDesktop ? 24 : 16, topPadding, isDesktop ? 24 : 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          if (isDesktop)
            Row(
              children: [
                Text('Expenses',
                    style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4)),
                const Spacer(),
                _buildTotalBadge(pos, totalExpenses),
                const SizedBox(width: 12),
                _buildAddButton(context),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Expenses',
                        style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildTotalBadge(pos, totalExpenses)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildAddButton(context)),
                  ],
                ),
              ],
            ),
          const SizedBox(height: 20),

          // Expenses Table
          Expanded(
            child: expensesAsync.when(
              loading: () => Center(
                  child: CircularProgressIndicator(
                      color: cs.primary, strokeWidth: 2.5)),
              error: (error, _) => Center(
                  child:
                      Text('Error: $error', style: TextStyle(color: pos.error))),
              data: (expenses) {
                if (expenses.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined,
                            size: 56,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.2)),
                        const SizedBox(height: 16),
                        Text('No expenses recorded',
                            style: GoogleFonts.inter(
                                color: cs.onSurfaceVariant, fontSize: 16)),
                      ],
                    ),
                  );
                }

                // ─── Phone: Card-based expense list ───
                if (isPhone) {
                  return ListView.separated(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: expenses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final expense = expenses[index];
                      return Container(
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
                                  width: 0.5)
                              : null,
                        ),
                        child: Row(
                          children: [
                            // Icon
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: pos.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.receipt_long_rounded,
                                  size: 20, color: pos.error),
                            ),
                            const SizedBox(width: 14),
                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    expense.productName,
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: cs.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${expense.quantity} × ${CurrencyFormatter.format(expense.cost)} • ${DateFormatter.formatDate(expense.date)}',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Total + delete
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  CurrencyFormatter.format(expense.totalCost),
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: pos.error,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                GestureDetector(
                                  onTap: () => _confirmDelete(context, expense.id),
                                  child: Icon(Icons.delete_outline_rounded,
                                      size: 18, color: pos.error.withValues(alpha: 0.6)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }

                // ─── Tablet / Desktop: DataTable ───
                return Container(
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
                            color: Colors.white.withValues(alpha: 0.06), width: 0.5)
                        : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(
                          isDark
                              ? Colors.white.withValues(alpha: 0.04)
                              : Colors.black.withValues(alpha: 0.02),
                        ),
                        headingTextStyle: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurfaceVariant,
                        ),
                        dataTextStyle:
                            GoogleFonts.inter(fontSize: 14, color: cs.onSurface),
                        columnSpacing: 32,
                        dividerThickness: 0.5,
                        columns: [
                          DataColumn(label: Text('Product', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12))),
                          DataColumn(label: Text('Qty', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12)), numeric: true),
                          DataColumn(label: Text('Cost/Unit', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12)), numeric: true),
                          DataColumn(label: Text('Total', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12)), numeric: true),
                          DataColumn(label: Text('Date', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12))),
                          DataColumn(label: Text('', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12))),
                        ],
                        rows: expenses.map((expense) {
                          return DataRow(cells: [
                            DataCell(Text(expense.productName,
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w500))),
                            DataCell(Text('${expense.quantity}')),
                            DataCell(Text(
                                CurrencyFormatter.format(expense.cost))),
                            DataCell(Text(
                              CurrencyFormatter.format(expense.totalCost),
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  color: pos.error),
                            )),
                            DataCell(Text(
                                DateFormatter.formatDate(expense.date),
                                style: GoogleFonts.inter(
                                    color: cs.onSurfaceVariant))),
                            DataCell(IconButton(
                              icon: Icon(Icons.delete_outline_rounded,
                                  size: 16, color: pos.error),
                              onPressed: () =>
                                  _confirmDelete(context, expense.id),
                            )),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalBadge(POSColors pos, double totalExpenses) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: pos.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Total ',
              style: GoogleFonts.inter(
                  color: pos.error.withValues(alpha: 0.6), fontSize: 13)),
          Text(CurrencyFormatter.format(totalExpenses),
              style: GoogleFonts.inter(
                  color: pos.error,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _showExpenseForm(context),
      icon: const Icon(Icons.add_rounded, size: 18),
      label: const Text('Add Expense'),
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String expenseId) {
    final pos = context.pos;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Expense?',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to delete this expense record?',
            style: GoogleFonts.inter(fontSize: 14)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ExpenseRepository().deleteExpense(expenseId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: pos.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showExpenseForm(BuildContext context) {
    final productController = TextEditingController();
    final quantityController = TextEditingController();
    final costController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    final cs = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
          backgroundColor: Theme.of(ctx).colorScheme.surface,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Add Expense',
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
                  const SizedBox(height: 24),
                  TextField(
                    controller: productController,
                    decoration: const InputDecoration(
                        labelText: 'Product / Description'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: quantityController,
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(labelText: 'Quantity'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: costController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              labelText: 'Cost/Unit (₹)', prefixText: '₹ '),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate,
                        firstDate: DateTime(2024),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => selectedDate = picked);
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        suffixIcon:
                            Icon(Icons.calendar_today_rounded, size: 18),
                      ),
                      child: Text(DateFormatter.formatDate(selectedDate)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        final product = productController.text.trim();
                        final quantity =
                            int.tryParse(quantityController.text) ?? 0;
                        final cost =
                            double.tryParse(costController.text) ?? 0;
                        if (product.isEmpty || quantity <= 0 || cost <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                  'Please fill out all fields with valid values'),
                              backgroundColor: cs.error,
                            ),
                          );
                          return;
                        }

                        final expense = Expense(
                          id: '',
                          productName: product,
                          quantity: quantity,
                          cost: cost,
                          date: selectedDate,
                          createdAt: DateTime.now(),
                        );
                        await ExpenseRepository().addExpense(expense);
                        await AuditRepository().log(
                          action: AppConstants.auditExpense,
                          description:
                              'Expense: $product — ${CurrencyFormatter.format(cost * quantity)}',
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('Add Expense',
                          style: GoogleFonts.inter(
                              fontSize: 16, fontWeight: FontWeight.w600)),
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
