import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/pos_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/receipt_id_generator.dart';
import '../../../data/repositories/checkout_repository.dart';
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

  final TextEditingController _mixedWalletController = TextEditingController();
  final TextEditingController _mixedCashController = TextEditingController();

  @override
  void dispose() {
    _mixedWalletController.dispose();
    _mixedCashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final cartTotal = ref.watch(cartTotalProvider);
    final selectedStudent = ref.watch(selectedStudentProvider);
    final cs = Theme.of(context).colorScheme;
    final pos = context.pos;

    final hasStudent = selectedStudent != null;
    final walletBalance = selectedStudent?.balance ?? 0.0;

    // Calculate payment breakdown
    double walletDeduction = 0;
    double cashAmount = cartTotal;
    double debtAmount = 0;
    String? localError;

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
      walletDeduction = double.tryParse(_mixedWalletController.text) ?? 0.0;
      cashAmount = double.tryParse(_mixedCashController.text) ?? 0.0;

      if (walletDeduction > walletBalance) {
        localError = 'Wallet deduction exceeds balance (${CurrencyFormatter.format(walletBalance)})';
      }

      debtAmount = cartTotal - (walletDeduction + cashAmount);
      if (debtAmount < 0) debtAmount = 0;
    }

    final displayError = _error ?? localError;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: cs.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.payment_rounded, color: cs.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Complete Payment',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const Spacer(),
                  _CloseCircle(onTap: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 24),

              // Order Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: pos.fill,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Items',
                            style: GoogleFonts.inter(color: cs.onSurfaceVariant, fontSize: 14)),
                        Text('${cartItems.length} products',
                            style: GoogleFonts.inter(color: cs.onSurface, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total',
                            style: GoogleFonts.inter(color: cs.onSurfaceVariant, fontSize: 14)),
                        Text(
                          CurrencyFormatter.format(cartTotal),
                          style: GoogleFonts.inter(
                            color: cs.onSurface,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ],
                    ),
                    if (hasStudent) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Divider(height: 1, color: pos.divider),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${selectedStudent.name}\'s Wallet',
                              style: GoogleFonts.inter(color: pos.info, fontSize: 13)),
                          Text(CurrencyFormatter.format(walletBalance),
                              style: GoogleFonts.inter(
                                  color: pos.info, fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Payment Mode Selection
              Text('Payment Method',
                  style: GoogleFonts.inter(
                      color: cs.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w600)),
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
              const SizedBox(height: 16),

              // Mixed Mode Explicit Inputs
              if (_paymentMode == AppConstants.paymentMixed && hasStudent) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _mixedWalletController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Take from Wallet',
                          isDense: true,
                        ),
                        onChanged: (_) => setState(() => _error = null),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _mixedCashController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Take in Cash',
                          isDense: true,
                        ),
                        onChanged: (_) => setState(() => _error = null),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Payment Breakdown
              if (_paymentMode != AppConstants.paymentCash && hasStudent) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: pos.fill,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      if (walletDeduction > 0)
                        _BreakdownRow(
                          label: 'Wallet Deduction',
                          amount: walletDeduction,
                          color: pos.info,
                        ),
                      if (cashAmount > 0)
                        _BreakdownRow(
                          label: 'Cash',
                          amount: cashAmount,
                          color: cs.onSurface,
                        ),
                      if (debtAmount > 0)
                        _BreakdownRow(
                          label: 'Added to Debt',
                          amount: debtAmount,
                          color: pos.error,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Error
              if (displayError != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: pos.errorContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, size: 16, color: pos.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(displayError,
                            style: GoogleFonts.inter(color: pos.error, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Confirm Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: (_isProcessing || localError != null)
                      ? null
                      : _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: pos.success,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                    disabledBackgroundColor: pos.success.withValues(alpha: 0.4),
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
                          'Confirm — ${CurrencyFormatter.format(cartTotal)}',
                          style: GoogleFonts.inter(
                              fontSize: 16, fontWeight: FontWeight.w700),
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

      double? mixedWallet;
      double? mixedCash;

      if (_paymentMode == AppConstants.paymentMixed) {
        mixedWallet = double.tryParse(_mixedWalletController.text) ?? 0.0;
        mixedCash = double.tryParse(_mixedCashController.text) ?? 0.0;
      }

      // Process atomic checkout
      final checkoutRepo = CheckoutRepository();
      final savedTransaction = await checkoutRepo.processCheckout(
        cartItems: cartItems,
        cartTotal: cartTotal,
        paymentMode: _paymentMode,
        receiptId: receiptId,
        studentId: selectedStudent?.id,
        studentName: selectedStudent?.name,
        userId: 'admin',
        mixedWalletAmount: mixedWallet,
        mixedCashAmount: mixedCash,
      );

      // Re-calculate the display amounts for the receipt dialog
      double walletDeductedDisplay = 0;
      double debtAmountDisplay = 0;
      double cashAmountDisplay = cartTotal;

      if (_paymentMode != AppConstants.paymentCash && selectedStudent != null) {
        if (_paymentMode == AppConstants.paymentWallet) {
          if (selectedStudent.balance >= cartTotal) {
            walletDeductedDisplay = cartTotal;
            cashAmountDisplay = 0;
          } else {
            walletDeductedDisplay = selectedStudent.balance;
            debtAmountDisplay = cartTotal - selectedStudent.balance;
            cashAmountDisplay = 0;
          }
        } else if (_paymentMode == AppConstants.paymentMixed) {
          walletDeductedDisplay = mixedWallet ?? 0.0;
          cashAmountDisplay = mixedCash ?? 0.0;
          debtAmountDisplay =
              cartTotal - (walletDeductedDisplay + cashAmountDisplay);
          if (debtAmountDisplay < 0) debtAmountDisplay = 0;
        }
      }

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
            walletDeducted: walletDeductedDisplay,
            cashAmount: cashAmountDisplay,
            debtAmount: debtAmountDisplay,
            studentName: selectedStudent?.name,
            transaction: savedTransaction,
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

class _CloseCircle extends StatefulWidget {
  final VoidCallback onTap;
  const _CloseCircle({required this.onTap});

  @override
  State<_CloseCircle> createState() => _CloseCircleState();
}

class _CloseCircleState extends State<_CloseCircle> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: _hovered
                ? cs.onSurfaceVariant.withValues(alpha: 0.15)
                : cs.onSurfaceVariant.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.close_rounded, size: 16, color: cs.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _PaymentModeChip extends StatefulWidget {
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
  State<_PaymentModeChip> createState() => _PaymentModeChipState();
}

class _PaymentModeChipState extends State<_PaymentModeChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pos = context.pos;

    return Expanded(
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.enabled ? widget.onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? cs.primary.withValues(alpha: 0.1)
                  : _isHovered && widget.enabled
                      ? pos.fill
                      : pos.fillSecondary,
              borderRadius: BorderRadius.circular(12),
              border: widget.isSelected
                  ? Border.all(color: cs.primary, width: 1.5)
                  : null,
            ),
            child: Column(
              children: [
                Icon(
                  widget.icon,
                  size: 22,
                  color: !widget.enabled
                      ? cs.onSurfaceVariant.withValues(alpha: 0.2)
                      : widget.isSelected
                          ? cs.primary
                          : cs.onSurfaceVariant,
                ),
                const SizedBox(height: 6),
                Text(
                  widget.label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight:
                        widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: !widget.enabled
                        ? cs.onSurfaceVariant.withValues(alpha: 0.2)
                        : widget.isSelected
                            ? cs.primary
                            : cs.onSurfaceVariant,
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(color: color, fontSize: 13)),
          Text(
            CurrencyFormatter.format(amount),
            style: GoogleFonts.inter(
                color: color, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
