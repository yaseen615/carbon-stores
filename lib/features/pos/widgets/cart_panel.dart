import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/cart_providers.dart';
import '../../../providers/student_providers.dart';
import 'cart_item_row.dart';
import 'student_info_card.dart';
import 'payment_dialog.dart';

class CartPanel extends ConsumerWidget {
  const CartPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final cartTotal = ref.watch(cartTotalProvider);
    final cartCount = ref.watch(cartItemCountProvider);
    final isEmpty = ref.watch(isCartEmptyProvider);
    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          // ─── Header ───
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cart',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.onBackground,
                  ),
                ),
                if (!isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$cartCount items',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.divider),

          // ─── Student Info ───
          const StudentInfoCard(),

          const Divider(height: 1, color: AppColors.divider),

          // ─── Cart Items ───
          Expanded(
            child: isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 48,
                          color: AppColors.onSurfaceVariant.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Cart is empty',
                          style: TextStyle(
                            color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap products to add',
                          style: TextStyle(
                            color: AppColors.onSurfaceVariant.withValues(alpha: 0.3),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: cartItems.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: AppColors.divider,
                    ),
                    itemBuilder: (context, index) {
                      return CartItemRow(item: cartItems[index]);
                    },
                  ),
          ),

          // ─── Total & Actions ───
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.surfaceVariant,
              border: Border(
                top: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Column(
              children: [
                // Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(cartTotal),
                      style: const TextStyle(
                        color: AppColors.onBackground,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Action Buttons
                Row(
                  children: [
                    // Clear
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isEmpty
                            ? null
                            : () {
                                ref.read(cartProvider.notifier).clearCart();
                                ref.read(selectedStudentProvider.notifier).state = null;
                                ref.read(studentSearchQueryProvider.notifier).state = '';
                              },
                        icon: const Icon(Icons.delete_outline_rounded, size: 18),
                        label: const Text('Clear'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Pay
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: isEmpty
                            ? null
                            : () {
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (_) => const PaymentDialog(),
                                );
                              },
                        icon: const Icon(Icons.payment_rounded, size: 20),
                        label: const Text('Pay'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 48),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
