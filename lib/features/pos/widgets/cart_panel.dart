import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/pos_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/multi_cart_provider.dart';

import 'cart_item_row.dart';
import 'student_info_card.dart';
import 'payment_dialog.dart';

/// Cart panel — clean, spacious layout optimized for 10" tablet.
/// Customer session tabs have moved to the product area (pos_screen.dart).
class CartPanel extends ConsumerWidget {
  const CartPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final multiCart = ref.watch(multiCartProvider);
    final activeSession = multiCart.activeSession;
    final cart = activeSession.items;
    final cartTotal = activeSession.total;
    final itemCount = activeSession.itemCount;
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
          // ─── Cart Header ───
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                // Cart icon
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.shopping_cart_rounded,
                    size: 18,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Cart',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                    letterSpacing: -0.3,
                  ),
                ),
                if (itemCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$itemCount',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: cs.primary,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                if (cart.isNotEmpty)
                  Material(
                    color: pos.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: () => ref.read(multiCartProvider.notifier).clearCart(),
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Clear All',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: pos.error,
                              ),
                            ),
                            const SizedBox(width: 6),
                            _KbdHint(label: 'Ctrl+⌫', color: pos.error),
                          ],
                        ),
                      ),
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
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: cs.onSurfaceVariant.withValues(alpha: 0.06),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.shopping_bag_outlined,
                            size: 32,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.25),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Cart is empty',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap a product to add',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: cart.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: pos.divider,
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
                  const SizedBox(height: 6),
                  _SummaryRow(
                    label: 'Tax (0%)',
                    value: CurrencyFormatter.format(0),
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(height: 6),
                  _SummaryRow(
                    label: 'Discount',
                    value: '-${CurrencyFormatter.format(0)}',
                    color: pos.success,
                  ),
                  
                  const SizedBox(height: 14),
                  Divider(height: 1, color: pos.divider),
                  const SizedBox(height: 14),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(cartTotal),
                        style: GoogleFonts.inter(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Checkout Button — Large, Apple-style
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => const PaymentDialog(),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.payment_rounded, size: 22),
                          const SizedBox(width: 10),
                          Text(
                            'Checkout  •  ${CurrencyFormatter.format(cartTotal)}',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 10),
                          _KbdHint(
                            label: 'F2',
                            color: cs.onPrimary,
                            bgOpacity: 0.2,
                          ),
                        ],
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

// ─── Summary Row ───

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

/// Small inline keyboard shortcut hint badge.
class _KbdHint extends StatelessWidget {
  final String label;
  final Color color;
  final double bgOpacity;

  const _KbdHint({
    required this.label,
    required this.color,
    this.bgOpacity = 0.12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: bgOpacity),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withValues(alpha: bgOpacity + 0.1),
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color.withValues(alpha: 0.8),
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
