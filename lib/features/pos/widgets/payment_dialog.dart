import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/pos_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/store_section.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/receipt_id_generator.dart';
import '../../../data/repositories/checkout_repository.dart';
import '../../../providers/student_providers.dart';
import '../../../providers/multi_cart_provider.dart';
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
  final TextEditingController _mixedUpiController = TextEditingController();
  final TextEditingController _mixedDebtController = TextEditingController();
  final TextEditingController _debtorNameController = TextEditingController();

  @override
  void dispose() {
    _mixedWalletController.dispose();
    _mixedCashController.dispose();
    _mixedUpiController.dispose();
    _mixedDebtController.dispose();
    _debtorNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final multiCart = ref.watch(multiCartProvider);
    final cartItems = multiCart.activeItems;
    final cartTotal = multiCart.activeSession.total;
    final selectedStudent = multiCart.activeStudent;
    final cs = Theme.of(context).colorScheme;
    final pos = context.pos;

    final hasStudent = selectedStudent != null;
    final walletBalance = selectedStudent?.balance ?? 0.0;

    // Auto-detect section from cart items
    final detectedSection = multiCart.activeSessionSection;

    double walletDeduction = 0;
    double cashAmount = 0;
    double upiAmount = 0;
    double debtAmount = 0;
    String? localError;

    if (_paymentMode == AppConstants.paymentCash) {
      cashAmount = cartTotal;
    } else if (_paymentMode == AppConstants.paymentUpi) {
      upiAmount = cartTotal;
    } else if (_paymentMode == AppConstants.paymentDebt) {
      debtAmount = cartTotal;
    } else if (_paymentMode == AppConstants.paymentWallet && hasStudent) {
      if (walletBalance >= cartTotal) {
        walletDeduction = cartTotal;
      } else {
        walletDeduction = walletBalance;
        debtAmount = cartTotal - walletBalance;
      }
    } else if (_paymentMode == AppConstants.paymentMixed) {
      walletDeduction = double.tryParse(_mixedWalletController.text) ?? 0.0;
      cashAmount = double.tryParse(_mixedCashController.text) ?? 0.0;
      upiAmount = double.tryParse(_mixedUpiController.text) ?? 0.0;
      debtAmount = double.tryParse(_mixedDebtController.text) ?? 0.0;

      if (hasStudent && walletDeduction > walletBalance) {
        localError = 'Wallet deduction exceeds balance (${CurrencyFormatter.format(walletBalance)})';
      }

      final sum = walletDeduction + cashAmount + upiAmount + debtAmount;
      if (localError == null && sum > cartTotal + 0.01) {
        localError = 'Total payments (${CurrencyFormatter.format(sum)}) exceed order amount';
      }
      if (sum < cartTotal) {
        debtAmount += (cartTotal - sum);
      }
    }

    final displayError = _error ?? localError;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: cs.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
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
                              style: GoogleFonts.inter(
                                  color: cs.onSurfaceVariant, fontSize: 14)),
                          Text('${cartItems.length} products',
                              style: GoogleFonts.inter(
                                  color: cs.onSurface, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total',
                              style: GoogleFonts.inter(
                                  color: cs.onSurfaceVariant, fontSize: 14)),
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
                                style: GoogleFonts.inter(
                                    color: pos.info, fontSize: 13)),
                            Text(CurrencyFormatter.format(walletBalance),
                                style: GoogleFonts.inter(
                                    color: pos.info,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                      // Section badge (auto-detected, read-only)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Row(
                          children: [
                            Divider(height: 1, color: pos.divider),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Section',
                                style: GoogleFonts.inter(
                                    color: cs.onSurfaceVariant, fontSize: 13)),
                            _SectionBadge(section: detectedSection),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Payment Mode Selection
                Text('Payment Method',
                    style: GoogleFonts.inter(
                        color: cs.onSurfaceVariant,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: _PaymentModeChip(
                        label: 'Cash',
                        icon: Icons.money_rounded,
                        isSelected: _paymentMode == AppConstants.paymentCash,
                        onTap: () =>
                            setState(() => _paymentMode = AppConstants.paymentCash),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _PaymentModeChip(
                        label: 'UPI',
                        icon: Icons.qr_code_2_rounded,
                        isSelected: _paymentMode == AppConstants.paymentUpi,
                        onTap: () =>
                            setState(() => _paymentMode = AppConstants.paymentUpi),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _PaymentModeChip(
                        label: 'Wallet',
                        icon: Icons.account_balance_wallet_rounded,
                        isSelected: _paymentMode == AppConstants.paymentWallet,
                        enabled: hasStudent,
                        onTap: hasStudent
                            ? () => setState(
                                () => _paymentMode = AppConstants.paymentWallet)
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _PaymentModeChip(
                        label: 'Debt',
                        icon: Icons.receipt_long_rounded,
                        isSelected: _paymentMode == AppConstants.paymentDebt,
                        onTap: () =>
                            setState(() => _paymentMode = AppConstants.paymentDebt),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _PaymentModeChip(
                        label: 'Mixed',
                        icon: Icons.sync_alt_rounded,
                        isSelected: _paymentMode == AppConstants.paymentMixed,
                        onTap: () =>
                            setState(() => _paymentMode = AppConstants.paymentMixed),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(child: SizedBox()),
                  ],
                ),
                const SizedBox(height: 16),

                // Mixed Mode Explicit Inputs
                if (_paymentMode == AppConstants.paymentMixed) ...[
                  Row(
                    children: [
                      if (hasStudent) ...[
                        Expanded(
                          child: TextField(
                            controller: _mixedWalletController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Wallet Amount',
                              isDense: true,
                            ),
                            onChanged: (_) => setState(() => _error = null),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: TextField(
                          controller: _mixedCashController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Cash Amount',
                            isDense: true,
                          ),
                          onChanged: (_) => setState(() => _error = null),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _mixedUpiController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'UPI Amount',
                            isDense: true,
                          ),
                          onChanged: (_) => setState(() => _error = null),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _mixedDebtController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Debt Amount',
                            isDense: true,
                          ),
                          onChanged: (_) => setState(() => _error = null),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                if (!hasStudent && debtAmount > 0) ...[
                  TextField(
                    controller: _debtorNameController,
                    decoration: const InputDecoration(
                      labelText: 'Debtor Name',
                      prefixIcon: Icon(Icons.person_outline),
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() => _error = null),
                  ),
                  const SizedBox(height: 16),
                ],

                // Payment Breakdown
                if (_paymentMode != AppConstants.paymentCash &&
                    _paymentMode != AppConstants.paymentUpi) ...[
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
                        if (upiAmount > 0)
                          _BreakdownRow(
                            label: 'UPI',
                            amount: upiAmount,
                            color: cs.primary,
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
                              style: GoogleFonts.inter(
                                  color: pos.error, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 16),

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
      ),
    );
  }

  Future<void> _processPayment() async {
    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      final multiCart = ref.read(multiCartProvider);
      final cartItems = multiCart.activeItems;
      final cartTotal = multiCart.activeSession.total;
      final selectedStudent = multiCart.activeStudent;
      final hasStudent = selectedStudent != null;

      final receiptId = ReceiptIdGenerator.generate();

      double? mixedWallet;
      double? mixedCash;
      double? mixedUpi;
      double? mixedDebt;

      if (_paymentMode == AppConstants.paymentMixed) {
        mixedWallet = double.tryParse(_mixedWalletController.text) ?? 0.0;
        mixedCash = double.tryParse(_mixedCashController.text) ?? 0.0;
        mixedUpi = double.tryParse(_mixedUpiController.text) ?? 0.0;
        mixedDebt = double.tryParse(_mixedDebtController.text) ?? 0.0;
      }

      String? finalDebtorName;
      if (!hasStudent && (_paymentMode == AppConstants.paymentDebt ||
          (_paymentMode == AppConstants.paymentMixed && (mixedDebt ?? 0) > 0))) {
        finalDebtorName = _debtorNameController.text.trim();
        if (finalDebtorName.isEmpty) throw Exception('Debtor name is required.');
      }

      final checkoutRepo = CheckoutRepository();
      final savedTransaction = await checkoutRepo.processCheckout(
        cartItems: cartItems,
        cartTotal: cartTotal,
        paymentMode: _paymentMode,
        receiptId: receiptId,
        studentId: selectedStudent?.id,
        studentName: selectedStudent?.name,
        userId: 'admin',
        section: multiCart.activeSessionSection.firestoreValue, // auto-detected
        mixedWalletAmount: mixedWallet,
        mixedCashAmount: mixedCash,
        mixedUpiAmount: mixedUpi,
        mixedDebtAmount: mixedDebt,
        debtorName: finalDebtorName,
      );

      double walletDeductedDisplay = 0;
      double debtAmountDisplay = 0;
      double cashAmountDisplay = 0;
      double upiAmountDisplay = 0;

      if (_paymentMode == AppConstants.paymentCash) {
        cashAmountDisplay = cartTotal;
      } else if (_paymentMode == AppConstants.paymentUpi) {
        upiAmountDisplay = cartTotal;
      } else if (_paymentMode == AppConstants.paymentDebt) {
        debtAmountDisplay = cartTotal;
      } else if (_paymentMode == AppConstants.paymentWallet && selectedStudent != null) {
        if (selectedStudent.balance >= cartTotal) {
          walletDeductedDisplay = cartTotal;
        } else {
          walletDeductedDisplay = selectedStudent.balance;
          debtAmountDisplay = cartTotal - selectedStudent.balance;
        }
      } else if (_paymentMode == AppConstants.paymentMixed) {
        walletDeductedDisplay = mixedWallet ?? 0.0;
        cashAmountDisplay = mixedCash ?? 0.0;
        upiAmountDisplay = mixedUpi ?? 0.0;
        debtAmountDisplay = mixedDebt ?? 0.0;
        
        final sum = walletDeductedDisplay + cashAmountDisplay + upiAmountDisplay + debtAmountDisplay;
        if (sum < cartTotal) {
          debtAmountDisplay += (cartTotal - sum);
        }
      }

      ref.read(multiCartProvider.notifier).closeActiveSessionAfterCheckout();
      ref.read(studentSearchQueryProvider.notifier).state = '';

      if (mounted) {
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (_) => ReceiptDialog(
            receiptId: receiptId,
            items: cartItems,
            totalAmount: cartTotal,
            paymentMode: _paymentMode,
            walletDeducted: walletDeductedDisplay,
            cashAmount: cashAmountDisplay,
            upiAmount: upiAmountDisplay,
            debtAmount: debtAmountDisplay,
            studentName: selectedStudent?.name ?? finalDebtorName,
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

    return MouseRegion(
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

/// Read-only badge showing auto-detected section (Cafe / Store / Combined).
class _SectionBadge extends StatelessWidget {
  final StoreSection section;
  const _SectionBadge({required this.section});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pos = context.pos;

    final Color color;
    switch (section) {
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '${section.emoji} ${section.label}',
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
