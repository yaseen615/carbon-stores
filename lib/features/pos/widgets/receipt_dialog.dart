import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/cart_item_model.dart';

class ReceiptDialog extends StatelessWidget {
  final String receiptId;
  final List<CartItem> items;
  final double totalAmount;
  final String paymentMode;
  final double walletDeducted;
  final double cashAmount;
  final double debtAmount;
  final String? studentName;

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
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceVariant,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.successContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: AppColors.success, size: 32),
              ),
              const SizedBox(height: 16),

              Text(
                'Payment Successful!',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 4),

              Text(
                receiptId,
                style: const TextStyle(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 13,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 4),

              Text(
                DateFormatter.formatDateTime(DateTime.now()),
                style: const TextStyle(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 20),
              const Divider(color: AppColors.divider),
              const SizedBox(height: 12),

              // Items
              ...items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${item.name} x${item.quantity}',
                        style: const TextStyle(color: AppColors.onSurface, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(item.total),
                      style: const TextStyle(color: AppColors.onSurface, fontSize: 13),
                    ),
                  ],
                ),
              )),

              const SizedBox(height: 12),
              const Divider(color: AppColors.divider),
              const SizedBox(height: 8),

              // Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total', style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 15)),
                  Text(
                    CurrencyFormatter.format(totalAmount),
                    style: const TextStyle(
                      color: AppColors.onBackground,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),

              // Payment breakdown
              if (walletDeducted > 0) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Wallet', style: TextStyle(color: AppColors.info, fontSize: 13)),
                    Text(CurrencyFormatter.format(walletDeducted),
                        style: const TextStyle(color: AppColors.info, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
              if (cashAmount > 0) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Cash', style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13)),
                    Text(CurrencyFormatter.format(cashAmount),
                        style: const TextStyle(color: AppColors.onSurface, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
              if (debtAmount > 0) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Debt', style: TextStyle(color: AppColors.error, fontSize: 13)),
                    Text(CurrencyFormatter.format(debtAmount),
                        style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w700)),
                  ],
                ),
              ],

              if (studentName != null) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Student', style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13)),
                    Text(studentName!, style: const TextStyle(color: AppColors.onSurface, fontSize: 13)),
                  ],
                ),
              ],

              const SizedBox(height: 24),

              // Close Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                  ),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
