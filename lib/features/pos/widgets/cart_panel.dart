import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/pos_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/cart_providers.dart';

import 'cart_item_row.dart';
import 'student_info_card.dart';
import 'payment_dialog.dart';

class CartPanel extends ConsumerWidget {
  const CartPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final cartTotal = ref.watch(cartTotalProvider);
    final itemCount = ref.watch(cartItemCountProvider);
    final cs = Theme.of(context).colorScheme;
    final pos = context.pos;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        // Left shadow for panel separation
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 20,
            offset: const Offset(-4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // ─── Header ───
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                Text(
                  'Cart',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                    letterSpacing: -0.4,
                  ),
                ),
                if (itemCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$itemCount',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: cs.primary,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                if (cart.isNotEmpty)
                  TextButton(
                    onPressed: () => ref.read(cartProvider.notifier).clearCart(),
                    style: TextButton.styleFrom(
                      foregroundColor: pos.error,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      minimumSize: const Size(0, 36),
                    ),
                    child: Text(
                      'Clear',
                      style: GoogleFonts.inter(
                          fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
          ),

          // ─── Student Info ───
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: StudentInfoCard(),
          ),

          const SizedBox(height: 8),
          Divider(height: 1, color: pos.divider, indent: 20, endIndent: 20),

          // ─── Cart Items ───
          Expanded(
            child: cart.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          size: 48,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.15),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Cart is empty',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap a product to add',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: cart.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: pos.divider,
                      indent: 4,
                      endIndent: 4,
                    ),
                    itemBuilder: (context, index) {
                      return CartItemRow(item: cart[index]);
                    },
                  ),
          ),

          // ─── Total + Pay ───
          if (cart.isNotEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: BoxDecoration(
                color: cs.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Stacked Totals
                  _SummaryRow(
                    label: 'Subtotal ($itemCount items)',
                    value: CurrencyFormatter.format(cartTotal),
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(height: 8),
                  _SummaryRow(
                    label: 'Tax (0%)',
                    value: CurrencyFormatter.format(0),
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(height: 8),
                  _SummaryRow(
                    label: 'Discount',
                    value: '-${CurrencyFormatter.format(0)}',
                    color: pos.success,
                  ),
                  
                  const SizedBox(height: 16),
                  Divider(height: 1, color: pos.divider),
                  const SizedBox(height: 16),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(cartTotal),
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Checkout Button
                  SizedBox(
                    width: double.infinity,
                    height: 56, // Larger height matching mockup
                    child: ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => const PaymentDialog(),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary, // Mockup has blue checkout
                        foregroundColor: cs.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Checkout',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
