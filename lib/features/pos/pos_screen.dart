import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/utils/responsive_helper.dart';
import '../../core/widgets/search_field.dart';
import '../../providers/product_providers.dart';
import '../../providers/cart_providers.dart';
import 'widgets/product_grid.dart';
import 'widgets/cart_panel.dart';
import 'widgets/category_tabs.dart';

class PosScreen extends ConsumerWidget {
  const PosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isPhone = Responsive.isPhone(context);
    final topPadding = isPhone ? MediaQuery.paddingOf(context).top + 16 : 20.0;

    final searchRow = Row(
      children: [
        Expanded(
          child: SearchField(
            hintText: 'Search Products',
            onChanged: (val) {
              ref.read(productSearchQueryProvider.notifier).state = val;
            },
          ),
        ),
        const SizedBox(width: 12),
        Consumer(builder: (context, ref, child) {
          final isListView = ref.watch(isProductListViewProvider);
          return Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.1)),
            ),
            child: IconButton(
              icon: Icon(
                  isListView
                      ? Icons.grid_view_rounded
                      : Icons.list_alt_rounded,
                  size: 22),
              color: cs.onSurfaceVariant,
              onPressed: () {
                ref.read(isProductListViewProvider.notifier).state =
                    !isListView;
              },
            ),
          );
        }),
      ],
    );

    // ─── Phone Layout: Portrait-first product browsing ───
    if (isPhone) {
      return Stack(
        children: [
          Padding(
            // Extra bottom padding for the bottom tab bar + cart button
            padding: EdgeInsets.fromLTRB(16, topPadding, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Compact page title for phone
                Text(
                  'Point of Sale',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 12),
                searchRow,
                const SizedBox(height: 12),
                const CategoryTabs(),
                const SizedBox(height: 12),
                const Expanded(child: ProductGrid()),
              ],
            ),
          ),
          // Floating cart button
          Positioned(
            left: 16,
            right: 16,
            bottom: 88, // above bottom tab bar
            child: _MobileCartButton(),
          ),
        ],
      );
    }

    // ─── Tablet / non-desktop: existing mobile layout ───
    if (!Responsive.isDesktop(context)) {
      return Stack(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, topPadding, 16, 88),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                searchRow,
                const SizedBox(height: 16),
                const CategoryTabs(),
                const SizedBox(height: 16),
                const Expanded(child: ProductGrid()),
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _MobileCartButton(),
          ),
        ],
      );
    }

    // ─── Desktop: Side-by-side layout ───
    return Row(
      children: [
        Expanded(
          flex: 70,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 12, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Point of Sale',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                searchRow,
                const SizedBox(height: 16),
                const CategoryTabs(),
                const SizedBox(height: 16),
                const Expanded(child: ProductGrid()),
              ],
            ),
          ),
        ),
        const SizedBox(
          width: 320,
          child: CartPanel(),
        ),
      ],
    );
  }
}

class _MobileCartButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final cart = ref.watch(cartProvider);
    final count = cart.fold<int>(0, (sum, item) => sum + item.quantity);
    final total =
        cart.fold<double>(0.0, (sum, item) => sum + (item.price * item.quantity));

    if (count == 0) return const SizedBox.shrink();

    return Material(
      color: cs.primary,
      borderRadius: BorderRadius.circular(16),
      elevation: 6,
      shadowColor: cs.primary.withValues(alpha: 0.4),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => Scaffold(
                appBar: AppBar(
                  title: Text(
                    'Cart & Checkout',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                    ),
                  ),
                  leading: IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                body: const CartPanel(),
              ),
              fullscreenDialog: true,
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: cs.onPrimary.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$count',
                      style: GoogleFonts.inter(
                        color: cs.onPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'View Cart',
                    style: GoogleFonts.inter(
                      color: cs.onPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Text(
                '₹${total.toStringAsFixed(2)}',
                style: GoogleFonts.inter(
                  color: cs.onPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
