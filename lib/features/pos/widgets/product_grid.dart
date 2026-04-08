import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/product_providers.dart';

import 'product_tile.dart';

class ProductGrid extends ConsumerWidget {
  const ProductGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsStreamProvider);
    final filtered = ref.watch(filteredProductsProvider);
    final cs = Theme.of(context).colorScheme;

    return productsAsync.when(
      loading: () => Center(
        child: CircularProgressIndicator(color: cs.primary, strokeWidth: 2.5),
      ),
      error: (error, _) => Center(
        child: Text('Error: $error', style: TextStyle(color: cs.error)),
      ),
      data: (_) {
        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 56,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.2),
                ),
                const SizedBox(height: 16),
                Text(
                  'No products found',
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        final isListView = ref.watch(isProductListViewProvider);

        if (isListView) {
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: filtered.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return SizedBox(
                height: 110, // Fixed height for list item
                child: ProductTile(product: filtered[index], isListView: true),
              );
            },
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.only(bottom: 24),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 180,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8, // Decreased to clear 2.9px vertical overflow of product text
          ),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            return ProductTile(product: filtered[index]);
          },
        );
      },
    );
  }
}
