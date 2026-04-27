import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/pos_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/cart_item_model.dart';
import '../../../providers/multi_cart_provider.dart';

/// Cart item row redesigned for 10" tablet usability.
/// Uses a two-row layout:
///   Row 1: Product name (full width) + subtotal
///   Row 2: Unit price + quantity stepper + delete button
/// No thumbnail image — saves space so names display fully.
class CartItemRow extends ConsumerWidget {
  final CartItem item;

  const CartItemRow({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final pos = context.pos;
    final subtotal = item.total;

    return Dismissible(
      key: ValueKey(item.productId),
      direction: DismissDirection.horizontal,
      // ─── Swipe Right (Start to End): Reduce Quantity ───
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        decoration: BoxDecoration(
          color: pos.info.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.remove_circle_outline_rounded, color: pos.info, size: 24),
            const SizedBox(height: 4),
            Text(
              item.quantity > 1 
                ? '${item.quantity} → ${item.quantity - 1}' 
                : 'Remove',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: pos.info,
              ),
            ),
          ],
        ),
      ),
      // ─── Swipe Left (End to Start): Remove Item ───
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: pos.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline_rounded, color: pos.error, size: 24),
            const SizedBox(height: 4),
            Text(
              'Remove',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: pos.error,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe Right: Reduce quantity
          if (item.quantity > 1) {
            ref.read(multiCartProvider.notifier).decrementQuantity(item.productId);
            // Snap back
            return false;
          }
          // If quantity is 1, return true to remove via onDismissed
          return true;
        }
        // Swipe Left: Remove via onDismissed
        return true;
      },
      onDismissed: (direction) {
        // In both cases where it's dismissed, we remove it.
        // If it was Swipe Right with Qty=1, or Swipe Left (always Remove)
        ref.read(multiCartProvider.notifier).removeItem(item.productId);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Row 1: Product name + Subtotal ───
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  CurrencyFormatter.format(subtotal),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ─── Row 2: Unit price + Stepper + Delete ───
            Row(
              children: [
                // Unit price
                Text(
                  '${CurrencyFormatter.format(item.price)} each',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),

                const Spacer(),

                // Quantity stepper — large touch targets
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Minus button
                      _StepperButton(
                        icon: Icons.remove_rounded,
                        iconColor: cs.onSurfaceVariant,
                        onTap: () {
                          ref.read(multiCartProvider.notifier)
                              .decrementQuantity(item.productId);
                        },
                      ),
                      // Quantity
                      Container(
                        width: 36,
                        alignment: Alignment.center,
                        child: Text(
                          '${item.quantity}',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                      // Plus button
                      _StepperButton(
                        icon: Icons.add_rounded,
                        iconColor: cs.primary,
                        onTap: () {
                          ref.read(multiCartProvider.notifier)
                              .incrementQuantity(item.productId);
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // ─── Explicit Delete Button ───
                GestureDetector(
                  onTap: () {
                    ref.read(multiCartProvider.notifier)
                        .removeItem(item.productId);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: pos.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: pos.error.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: pos.error,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Large 40×40 stepper button with tap feedback
class _StepperButton extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _StepperButton({
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  State<_StepperButton> createState() => _StepperButtonState();
}

class _StepperButtonState extends State<_StepperButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: Icon(widget.icon, size: 20, color: widget.iconColor),
          ),
        ),
      ),
    );
  }
}
