import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/search_field.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/audit_repository.dart';
import '../../providers/product_providers.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsStreamProvider);
    final filtered = ref.watch(filteredProductsProvider);
    final categories = ref.watch(categoriesProvider);
    final lowStockProducts = ref.watch(lowStockProductsProvider);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header ───
          Row(
            children: [
              Text('Inventory',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppColors.onBackground)),
              const Spacer(),
              if (lowStockProducts.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.warningContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning_rounded, size: 16, color: AppColors.warning),
                      const SizedBox(width: 6),
                      Text('${lowStockProducts.length} low stock',
                          style: const TextStyle(color: AppColors.warning, fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => _showProductForm(context),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Product'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search + Filter
          Row(
            children: [
              SizedBox(
                width: 280,
                child: SearchField(
                  hintText: 'Search products...',
                  onChanged: (query) {
                    ref.read(productSearchQueryProvider.notifier).state = query;
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Category filter
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: ref.watch(selectedCategoryProvider),
                    hint: const Text('All Categories',
                        style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14)),
                    dropdownColor: AppColors.surfaceVariant,
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All Categories', style: TextStyle(fontSize: 14)),
                      ),
                      ...categories.map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c, style: const TextStyle(fontSize: 14)),
                      )),
                    ],
                    onChanged: (value) {
                      ref.read(selectedCategoryProvider.notifier).state = value;
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ─── Products Table ───
          Expanded(
            child: productsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (error, _) => Center(child: Text('Error: $error', style: const TextStyle(color: AppColors.error))),
              data: (_) {
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64,
                            color: AppColors.onSurfaceVariant.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        const Text('No products found',
                            style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 18)),
                      ],
                    ),
                  );
                }

                return Card(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SingleChildScrollView(
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(AppColors.surfaceContainer),
                        columnSpacing: 24,
                        columns: const [
                          DataColumn(label: Text('Product', style: TextStyle(fontWeight: FontWeight.w600))),
                          DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.w600))),
                          DataColumn(label: Text('Price', style: TextStyle(fontWeight: FontWeight.w600)), numeric: true),
                          DataColumn(label: Text('Stock', style: TextStyle(fontWeight: FontWeight.w600)), numeric: true),
                          DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w600))),
                          DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.w600))),
                        ],
                        rows: filtered.map((product) {
                          return DataRow(
                            color: product.isOutOfStock
                                ? WidgetStateProperty.all(AppColors.errorContainer.withValues(alpha: 0.3))
                                : product.isLowStock
                                    ? WidgetStateProperty.all(AppColors.warningContainer.withValues(alpha: 0.3))
                                    : null,
                            cells: [
                              DataCell(Text(product.name,
                                  style: const TextStyle(fontWeight: FontWeight.w500))),
                              DataCell(Text(product.category,
                                  style: const TextStyle(color: AppColors.onSurfaceVariant))),
                              DataCell(Text(CurrencyFormatter.format(product.price),
                                  style: const TextStyle(fontWeight: FontWeight.w600))),
                              DataCell(Text('${product.stock}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: product.isOutOfStock
                                        ? AppColors.error
                                        : product.isLowStock
                                            ? AppColors.warning
                                            : AppColors.onSurface,
                                  ))),
                              DataCell(
                                product.isOutOfStock
                                    ? const StatusBadge.outOfStock()
                                    : product.isLowStock
                                        ? const StatusBadge.lowStock()
                                        : const StatusBadge(
                                            label: 'In Stock',
                                            type: BadgeType.success,
                                            icon: Icons.check_circle_rounded,
                                          ),
                              ),
                              DataCell(Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                                    color: AppColors.success,
                                    tooltip: 'Add Stock',
                                    onPressed: () => _showStockInDialog(context, product),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_rounded, size: 18),
                                    color: AppColors.primary,
                                    tooltip: 'Edit',
                                    onPressed: () => _showProductForm(context, product: product),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                                    color: AppColors.error,
                                    tooltip: 'Delete',
                                    onPressed: () => _confirmDelete(context, product),
                                  ),
                                ],
                              )),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showProductForm(BuildContext context, {Product? product}) {
    final isEdit = product != null;
    final nameController = TextEditingController(text: product?.name ?? '');
    final priceController = TextEditingController(text: product?.price.toString() ?? '');
    final stockController = TextEditingController(text: product?.stock.toString() ?? '0');
    final categoryController = TextEditingController(text: product?.category ?? '');

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isEdit ? 'Edit Product' : 'Add Product',
                    style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Product Name'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Price (₹)', prefixText: '₹ '),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: stockController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Stock'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final name = nameController.text.trim();
                      final price = double.tryParse(priceController.text) ?? 0;
                      final stock = int.tryParse(stockController.text) ?? 0;
                      final category = categoryController.text.trim();

                      if (name.isEmpty || price <= 0 || category.isEmpty) return;

                      final repo = ProductRepository();
                      if (isEdit) {
                        await repo.updateProduct(product.id, {
                          'name': name,
                          'price': price,
                          'stock': stock,
                          'category': category,
                        });
                      } else {
                        final newProduct = Product(
                          id: '',
                          name: name,
                          price: price,
                          stock: stock,
                          category: category,
                          updatedAt: DateTime.now(),
                        );
                        await repo.addProduct(newProduct);
                      }

                      await AuditRepository().log(
                        action: AppConstants.auditEdit,
                        description: '${isEdit ? "Updated" : "Added"} product: $name',
                      );

                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: Text(isEdit ? 'Update' : 'Add Product'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showStockInDialog(BuildContext context, Product product) {
    final qtyController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add Stock', style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text('${product.name} — Current: ${product.stock}',
                    style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14)),
                const SizedBox(height: 16),
                TextField(
                  controller: qtyController,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Quantity to Add'),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final qty = int.tryParse(qtyController.text) ?? 0;
                      if (qty <= 0) return;
                      await ProductRepository().updateStock(product.id, qty);
                      await AuditRepository().log(
                        action: AppConstants.auditStockIn,
                        description: 'Stock-in: ${product.name} +$qty',
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Add Stock'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ProductRepository().deleteProduct(product.id);
              await AuditRepository().log(
                action: AppConstants.auditEdit,
                description: 'Deleted product: ${product.name}',
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
