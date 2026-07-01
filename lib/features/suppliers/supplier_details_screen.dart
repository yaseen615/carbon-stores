import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/pos_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/supplier_model.dart';
import '../../data/models/supplier_payment_model.dart';
import '../../data/repositories/supplier_repository.dart';
import '../../data/repositories/supplier_payment_repository.dart';
import '../../data/repositories/audit_repository.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/supplier_providers.dart';
import '../../data/models/expense_model.dart';
import '../../data/repositories/expense_repository.dart';
class SupplierDetailsScreen extends ConsumerStatefulWidget {
  final Supplier supplier;
  const SupplierDetailsScreen({super.key, required this.supplier});

  @override
  ConsumerState<SupplierDetailsScreen> createState() => _SupplierDetailsScreenState();
}

class _SupplierDetailsScreenState extends ConsumerState<SupplierDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pos = context.pos;

    // Use a stream to listen to realtime changes of this supplier
    final supplierStream = ref.watch(supplierStreamProvider(widget.supplier.id));
    final currentSupplier = supplierStream.valueOrNull ?? widget.supplier;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(currentSupplier.name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 18)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: cs.primary,
          unselectedLabelColor: cs.onSurfaceVariant,
          indicatorColor: cs.primary,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Expenses (Bills)'),
            Tab(text: 'Payment History'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
            onPressed: () => _confirmDelete(context, currentSupplier),
            tooltip: 'Delete Supplier',
          ),
        ],
      ),
      body: Column(
        children: [
          // Supplier Summary Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(bottom: BorderSide(color: cs.onSurface.withValues(alpha: 0.1))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Outstanding Balance', style: GoogleFonts.inter(color: cs.onSurfaceVariant, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.format(currentSupplier.balance),
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: currentSupplier.balance > 0 ? pos.error : pos.success,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: currentSupplier.balance > 0 
                      ? () => _showClearBillDialog(context, currentSupplier)
                      : null,
                  icon: const Icon(Icons.payment_rounded, size: 18),
                  label: const Text('Clear Bill'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: pos.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    disabledBackgroundColor: cs.onSurfaceVariant.withValues(alpha: 0.2),
                  ),
                ),
              ],
            ),
          ),
          
          // Tabs Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _SupplierExpensesList(
                  supplier: currentSupplier,
                  onClearExpense: (e) => _showClearBillDialog(context, currentSupplier, expense: e),
                ),
                _SupplierPaymentsList(supplierId: currentSupplier.id),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showClearBillDialog(BuildContext context, Supplier supplier, {Expense? expense}) {
    final defaultAmount = expense != null ? (expense.totalCost - expense.paidAmount) : supplier.balance;
    final amountController = TextEditingController(text: defaultAmount.toString());
    final remarksController = TextEditingController();
    String paymentMode = 'Cash'; // Default
    final cs = Theme.of(context).colorScheme;
    bool isSaving = false;
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: cs.surface,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          expense != null ? 'Clear Bill: ${expense.productName}' : 'Clear Supplier Bill', 
                          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                        splashRadius: 20,
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Total due indicator
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Due:', style: GoogleFonts.inter(color: cs.error, fontWeight: FontWeight.w600)),
                        Text(CurrencyFormatter.format(supplier.balance), style: GoogleFonts.inter(color: cs.error, fontWeight: FontWeight.w700, fontSize: 16)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Amount to Pay (₹)'),
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    initialValue: paymentMode,
                    decoration: const InputDecoration(labelText: 'Payment Mode'),
                    items: ['Cash', 'UPI', 'Wallet'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (v) => setState(() => paymentMode = v!),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: remarksController,
                    decoration: const InputDecoration(labelText: 'Remarks (Optional)'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isSaving ? null : () async {
                        final amount = double.tryParse(amountController.text) ?? 0.0;
                        if (amount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Enter a valid amount'), backgroundColor: cs.error));
                          return;
                        }

                        setState(() => isSaving = true);
                        
                        try {
                          final payment = SupplierPayment(
                            id: '',
                            supplierId: supplier.id,
                            supplierName: supplier.name,
                            expenseId: expense?.id,
                            amount: amount,
                            date: selectedDate,
                            paymentMode: paymentMode,
                            remark: remarksController.text.trim(),
                            createdAt: DateTime.now(),
                          );

                          // Record Payment
                          await SupplierPaymentRepository().addPayment(payment);
                          
                          // Decrease Balance transactionally
                          await SupplierRepository().updateSupplierBalance(supplier.id, -amount);

                          // Update expense paidAmount if applicable
                          if (expense != null) {
                            await ExpenseRepository().updateExpense(expense.id, {
                              'paid_amount': expense.paidAmount + amount,
                            });
                          }
                          
                          // Audit
                          await AuditRepository().log(
                            action: AppConstants.auditExpense,
                            description: 'Supplier Payment: ${supplier.name} - ${CurrencyFormatter.format(amount)} via $paymentMode${expense != null ? " (For ${expense.productName})" : ""}',
                          );

                          if (ctx.mounted) Navigator.pop(ctx);
                        } catch (e) {
                          setState(() => isSaving = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: cs.error));
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.pos.success,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isSaving 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('Confirm Payment', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
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

  void _confirmDelete(BuildContext context, Supplier supplier) {
    if (supplier.balance > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Cannot delete supplier with outstanding balance. Clear bill first.'), backgroundColor: Theme.of(context).colorScheme.error),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Supplier?'),
        content: const Text('Are you sure you want to delete this supplier? Their expense and payment history will remain.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await SupplierRepository().deleteSupplier(supplier.id);
              if (context.mounted) Navigator.pop(context); // Go back to supplier list
            },
            style: ElevatedButton.styleFrom(backgroundColor: context.pos.error, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ─── Sub-Widgets for Tabs ───

class _SupplierExpensesList extends ConsumerWidget {
  final Supplier supplier;
  final Function(Expense) onClearExpense;
  const _SupplierExpensesList({required this.supplier, required this.onClearExpense});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(supplierExpensesProvider(supplier.id));
    final cs = Theme.of(context).colorScheme;

    return expensesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (expenses) {
        if (expenses.isEmpty) {
          return Center(child: Text('No expenses recorded for this supplier', style: TextStyle(color: cs.onSurfaceVariant)));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: expenses.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final e = expenses[index];
            return ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(e.isProductExpense ? Icons.inventory_2 : Icons.receipt_long, color: cs.primary, size: 20),
              ),
              title: Text(e.productName, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              subtitle: Text(DateFormatter.formatDate(e.date), style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!e.isPaid && e.totalCost > 0) ...[
                    ElevatedButton(
                      onPressed: () => onClearExpense(e),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        elevation: 0,
                        backgroundColor: cs.primary.withValues(alpha: 0.1),
                        foregroundColor: cs.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Pay', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 12),
                  ] else if (e.isPaid && e.totalCost > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: context.pos.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Paid', style: TextStyle(color: context.pos.success, fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Text(
                    CurrencyFormatter.format(e.totalCost),
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _SupplierPaymentsList extends ConsumerWidget {
  final String supplierId;
  const _SupplierPaymentsList({required this.supplierId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(supplierPaymentsProvider(supplierId));
    final cs = Theme.of(context).colorScheme;
    final pos = context.pos;

    return paymentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (payments) {
        if (payments.isEmpty) {
          return Center(child: Text('No payment history', style: TextStyle(color: cs.onSurfaceVariant)));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: payments.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final p = payments[index];
            return ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: pos.success.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(Icons.check_circle_outline, color: pos.success, size: 20),
              ),
              title: Text('Paid via ${p.paymentMode}', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(DateFormatter.formatDate(p.date), style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                  if (p.remark.isNotEmpty)
                    Text(p.remark, style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: cs.onSurfaceVariant)),
                ],
              ),
              trailing: Text(
                CurrencyFormatter.format(p.amount),
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: pos.success),
              ),
            );
          },
        );
      },
    );
  }
}
