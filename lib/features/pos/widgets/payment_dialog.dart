import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/receipt_id_generator.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/repositories/student_repository.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../data/repositories/audit_repository.dart';
import '../../../providers/cart_providers.dart';
import '../../../providers/student_providers.dart';
import 'receipt_dialog.dart';

class PaymentDialog extends ConsumerStatefulWidget {
  const PaymentDialog({super.key});

  @override
  ConsumerState<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends ConsumerState<PaymentDialog> {
  String _paymentMode = AppConstants.paymentCash;
  bool _isProcessing = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final cartTotal = ref.watch(cartTotalProvider);
    final selectedStudent = ref.watch(selectedStudentProvider);

    final hasStudent = selectedStudent != null;
    final walletBalance = selectedStudent?.balance ?? 0.0;

    // Calculate payment breakdown
    double walletDeduction = 0;
    double cashAmount = cartTotal;
    double debtAmount = 0;

    if (_paymentMode == AppConstants.paymentWallet && hasStudent) {
      if (walletBalance >= cartTotal) {
        walletDeduction = cartTotal;
        cashAmount = 0;
      } else {
        walletDeduction = walletBalance;
        cashAmount = 0;
        debtAmount = cartTotal - walletBalance;
      }
    } else if (_paymentMode == AppConstants.paymentMixed && hasStudent) {
      if (walletBalance >= cartTotal) {
        walletDeduction = cartTotal;
        cashAmount = 0;
      } else {
        walletDeduction = walletBalance;
        cashAmount = cartTotal - walletBalance;
      }
    }


    return Dialog(
      backgroundColor: AppColors.surfaceVariant,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Row(
                children: [
                  const Icon(Icons.payment_rounded, color: AppColors.primary, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    'Complete Payment',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                    color: AppColors.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Order Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Items', style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14)),
                        Text('${cartItems.length} products', style: const TextStyle(color: AppColors.onSurface, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total', style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14)),
                        Text(
                          CurrencyFormatter.format(cartTotal),
                          style: const TextStyle(
                            color: AppColors.onBackground,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    if (hasStudent) ...[
                      const Divider(height: 16, color: AppColors.divider),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${selectedStudent.name}\'s Wallet',
                              style: const TextStyle(color: AppColors.info, fontSize: 13)),
                          Text(CurrencyFormatter.format(walletBalance),
                              style: const TextStyle(color: AppColors.info, fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Payment Mode Selection
              const Text('Payment Mode',
                  style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),

              Row(
                children: [
                  _PaymentModeChip(
                    label: 'Cash',
                    icon: Icons.money_rounded,
                    isSelected: _paymentMode == AppConstants.paymentCash,
                    onTap: () => setState(() => _paymentMode = AppConstants.paymentCash),
                  ),
                  const SizedBox(width: 8),
                  _PaymentModeChip(
                    label: 'Wallet',
                    icon: Icons.account_balance_wallet_rounded,
                    isSelected: _paymentMode == AppConstants.paymentWallet,
                    enabled: hasStudent,
                    onTap: hasStudent
                        ? () => setState(() => _paymentMode = AppConstants.paymentWallet)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  _PaymentModeChip(
                    label: 'Mixed',
                    icon: Icons.sync_alt_rounded,
                    isSelected: _paymentMode == AppConstants.paymentMixed,
                    enabled: hasStudent,
                    onTap: hasStudent
                        ? () => setState(() => _paymentMode = AppConstants.paymentMixed)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Payment Breakdown
              if (_paymentMode != AppConstants.paymentCash && hasStudent) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      if (walletDeduction > 0)
                        _BreakdownRow(
                          label: 'Wallet Deduction',
                          amount: walletDeduction,
                          color: AppColors.info,
                        ),
                      if (cashAmount > 0)
                        _BreakdownRow(
                          label: 'Cash',
                          amount: cashAmount,
                          color: AppColors.onSurface,
                        ),
                      if (debtAmount > 0)
                        _BreakdownRow(
                          label: 'Added to Debt',
                          amount: debtAmount,
                          color: AppColors.error,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Error
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, size: 16, color: AppColors.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Confirm Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Confirm Payment — ${CurrencyFormatter.format(cartTotal)}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processPayment() async {
    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      final cartItems = ref.read(cartProvider);
      final cartTotal = ref.read(cartTotalProvider);
      final selectedStudent = ref.read(selectedStudentProvider);

      final receiptId = ReceiptIdGenerator.generate();

      double walletDeducted = 0;
      double cashAmount = cartTotal;
      double debtAmount = 0;

      // Process wallet payment if applicable
      if (_paymentMode != AppConstants.paymentCash && selectedStudent != null) {
        final studentRepo = StudentRepository();
        final result = await studentRepo.deductWallet(selectedStudent.id, cartTotal);
        walletDeducted = result['wallet_deducted'] ?? 0;
        debtAmount = result['debt_added'] ?? 0;

        if (_paymentMode == AppConstants.paymentMixed) {
          cashAmount = cartTotal - walletDeducted;
          debtAmount = 0; // Mixed means remaining is cash, not debt
        } else {
          cashAmount = 0;
        }
      }

      // Update stock for all products
      final productRepo = ProductRepository();
      final stockChanges = <String, int>{};
      for (final item in cartItems) {
        stockChanges[item.productId] = -(item.quantity);
      }
      await productRepo.batchUpdateStock(stockChanges);

      // Create transaction record
      final transactionRepo = TransactionRepository();
      final transaction = StoreTransaction(
        id: '',
        receiptId: receiptId,
        items: cartItems,
        totalAmount: cartTotal,
        paymentMode: _paymentMode,
        paidAmount: walletDeducted + cashAmount,
        debtAmount: debtAmount,
        studentId: selectedStudent?.id,
        studentName: selectedStudent?.name,
        createdAt: DateTime.now(),
      );
      await transactionRepo.createTransaction(transaction);

      // Log audit
      final auditRepo = AuditRepository();
      await auditRepo.log(
        action: AppConstants.auditSale,
        description: 'Sale: $receiptId — ${CurrencyFormatter.format(cartTotal)} (${_paymentMode})',
        metadata: {
          'receipt_id': receiptId,
          'total': cartTotal,
          'payment_mode': _paymentMode,
          'student_id': selectedStudent?.id,
        },
      );

      // Clear cart and student
      ref.read(cartProvider.notifier).clearCart();
      ref.read(selectedStudentProvider.notifier).state = null;
      ref.read(studentSearchQueryProvider.notifier).state = '';

      if (mounted) {
        Navigator.pop(context); // Close payment dialog

        // Show receipt
        showDialog(
          context: context,
          builder: (_) => ReceiptDialog(
            receiptId: receiptId,
            items: cartItems,
            totalAmount: cartTotal,
            paymentMode: _paymentMode,
            walletDeducted: walletDeducted,
            cashAmount: cashAmount,
            debtAmount: debtAmount,
            studentName: selectedStudent?.name,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isProcessing = false;
      });
    }
  }
}

class _PaymentModeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final bool enabled;
  final VoidCallback? onTap;

  const _PaymentModeChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    this.enabled = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryContainer : AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 1.5 : 0.5,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: !enabled
                      ? AppColors.onSurfaceVariant.withValues(alpha: 0.3)
                      : isSelected
                          ? AppColors.primary
                          : AppColors.onSurfaceVariant,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: !enabled
                        ? AppColors.onSurfaceVariant.withValues(alpha: 0.3)
                        : isSelected
                            ? AppColors.primary
                            : AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _BreakdownRow({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 13)),
          Text(
            CurrencyFormatter.format(amount),
            style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
