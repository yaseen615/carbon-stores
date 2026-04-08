import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/pos_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/services/local_storage_service.dart';
import '../../../data/models/cart_item_model.dart';
import '../../../providers/cart_providers.dart';

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
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: pos.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.delete_outline_rounded, color: pos.error, size: 20),
      ),
      onDismissed: (_) {
        ref.read(cartProvider.notifier).removeItem(item.productId);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            // Dynamic image placeholder
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF4F5F7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: item.imageId == null
                  ? Icon(
                      Icons.image_outlined,
                      size: 20,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                    )
                  : FutureBuilder<Uint8List?>(
                      future: LocalStorageService()
                          .getProductImageBytes(item.imageId!),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data != null) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              snapshot.data!,
                              fit: BoxFit.cover,
                            ),
                          );
                        }
                        return Icon(
                          Icons.image_outlined,
                          size: 20,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                        );
                      },
                    ),
            ),
            const SizedBox(width: 12),
            // Product info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    CurrencyFormatter.format(item.price),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Quantity stepper
            _QuantityStepper(item: item),

            const SizedBox(width: 12),

            // Subtotal
            SizedBox(
              width: 64,
              child: Text(
                CurrencyFormatter.format(subtotal),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantityStepper extends ConsumerWidget {
  final CartItem item;

  const _QuantityStepper({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final pos = context.pos;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.onSurfaceVariant.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(
            icon: item.quantity == 1
                ? Icons.delete_outline_rounded
                : Icons.remove_rounded,
            iconColor: item.quantity == 1 ? pos.error : cs.onSurfaceVariant,
            onTap: () {
              ref.read(cartProvider.notifier).decrementQuantity(item.productId);
            },
          ),
          SizedBox(
            width: 24,
            child: Text(
              '${item.quantity}',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ),
          _StepperButton(
            icon: Icons.add_rounded,
            iconColor: cs.onSurfaceVariant,
            onTap: () {
              ref.read(cartProvider.notifier).incrementQuantity(item.productId);
            },
          ),
        ],
      ),
    );
  }
}

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
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Center(
            child: Icon(widget.icon, size: 16, color: widget.iconColor),
          ),
        ),
      ),
    );
  }
}
