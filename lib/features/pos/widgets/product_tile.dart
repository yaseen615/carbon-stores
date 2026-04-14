import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/pos_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/services/local_storage_service.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/cart_item_model.dart';
import '../../../providers/cart_providers.dart';

/// Apple HIG-inspired product tile with:
/// - 0.97 scale tap feedback
/// - Borderless card with subtle shadow
/// - Cart-state tinted background
/// - Animated add-to-cart bounce effect
class ProductTile extends ConsumerStatefulWidget {
  final Product product;
  final bool isListView;

  const ProductTile({super.key, required this.product, this.isListView = false});

  @override
  ConsumerState<ProductTile> createState() => _ProductTileState();
}

class _ProductTileState extends ConsumerState<ProductTile>
    with TickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;
  late final AnimationController _addToCartController;
  late final Animation<double> _addToCartScale;
  Future<Uint8List?>? _imageFuture;

  @override
  void initState() {
    super.initState();
    if (widget.product.imageId != null) {
      _imageFuture = LocalStorageService().getProductImageBytes(widget.product.imageId!);
    }
    // Tap scale (super fast for instant POS feedback)
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 60),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    // Add-to-cart bounce (snappy hardware-like pop)
    _addToCartController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _addToCartScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.04), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.04, end: 0.98), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.98, end: 1.0), weight: 40),
    ]).animate(CurvedAnimation(parent: _addToCartController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _addToCartController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ProductTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.imageId != widget.product.imageId) {
      if (widget.product.imageId != null) {
        _imageFuture = LocalStorageService().getProductImageBytes(widget.product.imageId!);
      } else {
        _imageFuture = null;
      }
    }
  }

  void _onTap() {
    if (widget.product.isOutOfStock) return;

    ref.read(cartProvider.notifier).addProduct(widget.product);

    // Trigger add-to-cart bounce
    _addToCartController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pos = context.pos;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cart = ref.watch(cartProvider);
    final cartItem = cart.cast<CartItem?>().firstWhere(
      (item) => item?.productId == widget.product.id,
      orElse: () => null,
    );
    final cartQty = cartItem?.quantity ?? 0;
    final isInCart = cartQty > 0;

    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) {
        _scaleController.reverse();
        _onTap();
      },
      onTapCancel: () => _scaleController.reverse(),
      child: AnimatedBuilder(
        animation: Listenable.merge([_scaleAnimation, _addToCartScale]),
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value *
                (_addToCartController.isAnimating ? _addToCartScale.value : 1.0),
            child: child,
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.transparent,
            ),
          ),
          child: widget.isListView
              ? _buildListView(context, pos, isInCart, cartQty, cs, isDark)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image block with Stack for trailing FAB
                    Expanded(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Product Image or placeholder
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: isDark ? pos.fill : const Color(0xFFF4F5F7),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                                bottomLeft: Radius.circular(4),
                                bottomRight: Radius.circular(4),
                              ),
                            ),
                            child: widget.product.imageId == null
                                ? Icon(
                                    Icons.image_outlined,
                                    size: 40,
                                    color: cs.onSurfaceVariant.withValues(alpha: 0.2),
                                  )
                                : FutureBuilder<Uint8List?>(
                                    future: _imageFuture,
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData && snapshot.data != null) {
                                        return ClipRRect(
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(16),
                                            topRight: Radius.circular(16),
                                          ),
                                          child: Image.memory(
                                            snapshot.data!,
                                            fit: BoxFit.cover,
                                          ),
                                        );
                                      }
                                      return Icon(
                                        Icons.image_outlined,
                                        size: 40,
                                        color: cs.onSurfaceVariant.withValues(alpha: 0.2),
                                      );
                                    },
                                  ),
                          ),
                          
                          // Out of stock overlay
                          if (widget.product.isOutOfStock)
                            Container(
                              decoration: BoxDecoration(
                                color: pos.error.withValues(alpha: 0.1),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                  bottomLeft: Radius.circular(4),
                                  bottomRight: Radius.circular(4),
                                ),
                              ),
                            ),
                            
                          // Cart quantity badge top-left
                          if (isInCart)
                             Positioned(
                               top: 8,
                               left: 8,
                               child: Container(
                                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                 decoration: BoxDecoration(
                                   color: cs.primary,
                                   borderRadius: BorderRadius.circular(999),
                                 ),
                                 child: Text(
                                   '$cartQty',
                                   style: GoogleFonts.inter(
                                     fontSize: 12,
                                     fontWeight: FontWeight.w700,
                                     color: cs.onPrimary,
                                   ),
                                 ),
                               ),
                             ),

                          // Add FAB bottom-right overlapping
                          Positioned(
                            bottom: -16,
                            right: 12,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: cs.surface,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.add_rounded,
                                size: 20,
                                color: cs.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Text Content block
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 18, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.product.name,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  CurrencyFormatter.format(widget.product.price),
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (!widget.product.isOutOfStock) ...[
                                const SizedBox(width: 4),
                                _StockBadge(product: widget.product),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildListView(BuildContext context, dynamic pos, bool isInCart, int cartQty, ColorScheme cs, bool isDark) {
    return Row(
      children: [
        // Image
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            color: isDark ? pos.fill : const Color(0xFFF4F5F7),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              bottomLeft: Radius.circular(16),
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: widget.product.imageId == null
                    ? Icon(
                        Icons.image_outlined,
                        size: 32,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.2),
                      )
                    : FutureBuilder<Uint8List?>(
                        future: _imageFuture,
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data != null) {
                            return ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                bottomLeft: Radius.circular(16),
                              ),
                              child: Image.memory(
                                snapshot.data!,
                                fit: BoxFit.cover,
                              ),
                            );
                          }
                          return Icon(
                            Icons.image_outlined,
                            size: 32,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.2),
                          );
                        },
                      ),
              ),
              if (widget.product.isOutOfStock)
                Container(
                  decoration: BoxDecoration(
                    color: pos.error.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        // Content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.product.name,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!widget.product.isOutOfStock)
                       _StockBadge(product: widget.product),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  CurrencyFormatter.format(widget.product.price),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Trailing Add Button & Qty
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isInCart) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$cartQty',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: cs.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: cs.onSurfaceVariant.withValues(alpha: 0.15)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.add_rounded,
                  size: 24,
                  color: cs.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StockBadge extends StatelessWidget {
  final Product product;

  const _StockBadge({required this.product});

  @override
  Widget build(BuildContext context) {
    final pos = context.pos;

    Color bgColor;
    Color fgColor;

    if (product.isOutOfStock) {
      bgColor = pos.error.withValues(alpha: 0.12);
      fgColor = pos.error;
    } else if (product.isLowStock) {
      bgColor = pos.warning.withValues(alpha: 0.12);
      fgColor = pos.warning;
    } else {
      bgColor = pos.success.withValues(alpha: 0.10);
      fgColor = pos.success;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        product.isOutOfStock ? 'Out' : '${product.stock}',
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fgColor,
        ),
      ),
    );
  }
}
