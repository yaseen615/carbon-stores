import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/pos_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/cart_item_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/void_repository.dart';
import '../../../core/utils/receipt_generator.dart';

class ReceiptDialog extends StatelessWidget {
  final String receiptId;
  final List<CartItem> items;
  final double totalAmount;
  final String paymentMode;
  final double walletDeducted;
  final double cashAmount;
  final double debtAmount;
  final String? studentName;
  final StoreTransaction? transaction;

  const ReceiptDialog({
    super.key,
    required this.receiptId,
    required this.items,
    required this.totalAmount,
    required this.paymentMode,
    required this.walletDeducted,
    required this.cashAmount,
    required this.debtAmount,
    this.studentName,
    this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pos = context.pos;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: cs.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success Icon — larger
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: pos.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_rounded, color: pos.success, size: 36),
              ),
              const SizedBox(height: 16),

              Text(
                'Payment Successful!',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: pos.success,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),

              Text(
                receiptId,
                style: GoogleFonts.inter(
                  color: cs.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),

              Text(
                DateFormatter.formatDateTime(DateTime.now()),
                style: GoogleFonts.inter(
                  color: cs.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 20),
              Divider(height: 1, color: pos.divider),
              const SizedBox(height: 16),

              // Items
              ...items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${item.name} ×${item.quantity}',
                        style: GoogleFonts.inter(color: cs.onSurface, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(item.total),
                      style: GoogleFonts.inter(
                          color: cs.onSurface, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              )),

              const SizedBox(height: 16),
              Divider(height: 1, color: pos.divider),
              const SizedBox(height: 12),

              // Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total',
                      style: GoogleFonts.inter(
                          color: cs.onSurfaceVariant, fontSize: 15)),
                  Text(
                    CurrencyFormatter.format(totalAmount),
                    style: GoogleFonts.inter(
                      color: cs.onSurface,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),

              // Payment breakdown
              if (walletDeducted > 0) ...[
                const SizedBox(height: 8),
                _BreakdownRow(label: 'Wallet', amount: walletDeducted, color: pos.info),
              ],
              if (cashAmount > 0) ...[
                const SizedBox(height: 4),
                _BreakdownRow(
                    label: 'Cash', amount: cashAmount, color: cs.onSurfaceVariant),
              ],
              if (debtAmount > 0) ...[
                const SizedBox(height: 4),
                _BreakdownRow(label: 'Debt', amount: debtAmount, color: pos.error),
              ],

              if (studentName != null) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Student',
                        style: GoogleFonts.inter(
                            color: cs.onSurfaceVariant, fontSize: 13)),
                    Text(studentName!,
                        style: GoogleFonts.inter(color: cs.onSurface, fontSize: 13)),
                  ],
                ),
              ],

              const SizedBox(height: 28),

              // Action Buttons
              if (transaction != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ReceiptGenerator.printReceipt(transaction!,
                              walletDeducted: walletDeducted,
                              cashAmount: cashAmount);
                        },
                        icon: const Icon(Icons.print_rounded, size: 18),
                        label: const Text('Print'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    if (transaction != null && !transaction!.isVoided) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _confirmVoid(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: pos.error,
                            side: BorderSide(color: pos.error.withValues(alpha: 0.4)),
                            minimumSize: const Size(0, 48),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Cancel Purchase'),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
              ],

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text('Done',
                      style: GoogleFonts.inter(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmVoid(BuildContext context) {
    final reasonController = TextEditingController();
    final cs = Theme.of(context).colorScheme;
    final pos = context.pos;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Cancel Purchase?',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will reverse wallet deductions and restock items. This action cannot be undone.',
              style: GoogleFonts.inter(fontSize: 13, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for cancelling',
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Back'),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) return;

              Navigator.pop(ctx);

              try {
                await VoidRepository().voidTransaction(transaction!, reason);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Purchase cancelled successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to cancel: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: pos.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Void Transaction'),
          ),
        ],
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(color: color, fontSize: 13)),
        Text(
          CurrencyFormatter.format(amount),
          style: GoogleFonts.inter(
              color: color, fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
