import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
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

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text('Expenses',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppColors.onBackground)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.errorContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Total: ', style: TextStyle(color: AppColors.errorLight, fontSize: 13)),
                    Text(CurrencyFormatter.format(totalExpenses),
                        style: const TextStyle(color: AppColors.error, fontSize: 15, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => _showExpenseForm(context),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Expense'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Expenses List
          Expanded(
            child: expensesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (error, _) => Center(child: Text('Error: $error', style: const TextStyle(color: AppColors.error))),
              data: (expenses) {
                if (expenses.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 64,
                            color: AppColors.onSurfaceVariant.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        const Text('No expenses recorded',
                            style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 18)),
                      ],
                    ),
                  );
                }

                return Card(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SingleChildScrollView(
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(AppColors.surfaceContainer),
                        columnSpacing: 32,
                        columns: const [
                          DataColumn(label: Text('Product', style: TextStyle(fontWeight: FontWeight.w600))),
                          DataColumn(label: Text('Quantity', style: TextStyle(fontWeight: FontWeight.w600)), numeric: true),
                          DataColumn(label: Text('Cost/Unit', style: TextStyle(fontWeight: FontWeight.w600)), numeric: true),
                          DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.w600)), numeric: true),
                          DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.w600))),
                          DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.w600))),
                        ],
                        rows: expenses.map((expense) {
                          return DataRow(cells: [
                            DataCell(Text(expense.productName,
                                style: const TextStyle(fontWeight: FontWeight.w500))),
                            DataCell(Text('${expense.quantity}')),
                            DataCell(Text(CurrencyFormatter.format(expense.cost))),
                            DataCell(Text(
                              CurrencyFormatter.format(expense.totalCost),
                              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.error),
                            )),
                            DataCell(Text(DateFormatter.formatDate(expense.date),
                                style: const TextStyle(color: AppColors.onSurfaceVariant))),
                            DataCell(IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 18),
                              color: AppColors.error,
                              onPressed: () async {
                                await ExpenseRepository().deleteExpense(expense.id);
                              },
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

  void _showExpenseForm(BuildContext context) {
    final productController = TextEditingController();
    final quantityController = TextEditingController();
    final costController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Dialog(
          backgroundColor: AppColors.surfaceVariant,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Add Expense', style: Theme.of(ctx).textTheme.titleLarge),
                  const SizedBox(height: 20),
                  TextField(
                    controller: productController,
                    decoration: const InputDecoration(labelText: 'Product / Description'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: quantityController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Quantity'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: costController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Cost/Unit (₹)', prefixText: '₹ '),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Date Picker
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
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        suffixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                      ),
                      child: Text(DateFormatter.formatDate(selectedDate)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final product = productController.text.trim();
                        final quantity = int.tryParse(quantityController.text) ?? 0;
                        final cost = double.tryParse(costController.text) ?? 0;
                        if (product.isEmpty || quantity <= 0 || cost <= 0) return;

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
                          description: 'Expense: $product — ${CurrencyFormatter.format(cost * quantity)}',
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: const Text('Add Expense'),
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
