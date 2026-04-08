import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/widgets/search_field.dart';
import '../../providers/product_providers.dart';
import 'widgets/product_grid.dart';
import 'widgets/cart_panel.dart';
import 'widgets/category_tabs.dart';

class PosScreen extends ConsumerWidget {
  const PosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        // ─── Left Panel: Products ───
        Expanded(
          flex: 70,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 12, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
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
                
                // Search bar row
                Row(
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
                    // Trailing list icon button
                    Consumer(
                      builder: (context, ref, child) {
                        final isListView = ref.watch(isProductListViewProvider);
                        return Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: cs.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: cs.onSurfaceVariant.withValues(alpha: 0.1)),
                          ),
                          child: IconButton(
                            icon: Icon(
                              isListView ? Icons.grid_view_rounded : Icons.list_alt_rounded, 
                              size: 22
                            ),
                            color: cs.onSurfaceVariant,
                            onPressed: () {
                              ref.read(isProductListViewProvider.notifier).state = !isListView;
                            },
                          ),
                        );
                      }
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Category tabs
                const CategoryTabs(),
                const SizedBox(height: 16),

                // Product grid
                const Expanded(child: ProductGrid()),
              ],
            ),
          ),
        ),

        // ─── Right Panel: Cart ───
        const SizedBox(
          width: 320,
          child: CartPanel(),
        ),
      ],
    );
  }
}
