import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import 'widgets/category_tabs.dart';
import 'widgets/product_grid.dart';
import 'widgets/cart_panel.dart';
import '../../core/widgets/search_field.dart';
import '../../providers/product_providers.dart';

class PosScreen extends ConsumerWidget {
  const PosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        // ─── LEFT PANEL (70%) — Products ───
        Expanded(
          flex: 70,
          child: Container(
            color: AppColors.background,
            child: Column(
              children: [
                // App Bar area
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    children: [
                      Text(
                        'Point of Sale',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.onBackground,
                        ),
                      ),
                      const Spacer(),
                      // Search bar
                      SizedBox(
                        width: 280,
                        child: SearchField(
                          hintText: 'Search products...',
                          onChanged: (query) {
                            ref.read(productSearchQueryProvider.notifier).state = query;
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Category Tabs
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: CategoryTabs(),
                ),

                const SizedBox(height: 12),

                // Product Grid
                const Expanded(
                  child: ProductGrid(),
                ),
              ],
            ),
          ),
        ),

        // ─── Divider ───
        Container(
          width: 1,
          color: AppColors.divider,
        ),

        // ─── RIGHT PANEL (30%) — Cart ───
        const Expanded(
          flex: 30,
          child: CartPanel(),
        ),
      ],
    );
  }
}
