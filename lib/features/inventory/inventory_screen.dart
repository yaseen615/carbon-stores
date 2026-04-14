import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/pos_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/responsive_helper.dart';
import '../../core/widgets/search_field.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/audit_repository.dart';
import '../../providers/product_providers.dart';
import '../../core/services/local_storage_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsStreamProvider);
    final filtered = ref.watch(filteredProductsProvider);
    final categories = ref.watch(categoriesProvider);
    final lowStockProducts = ref.watch(lowStockProductsProvider);
    final cs = Theme.of(context).colorScheme;
    final pos = context.pos;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = Responsive.isTabletOrDesktop(context);
    final isPhone = Responsive.isPhone(context);
    final topPadding = isPhone ? MediaQuery.paddingOf(context).top + 16 : 20.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(isDesktop ? 24 : 16, topPadding, isDesktop ? 24 : 16, isPhone ? 8 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header ───
          if (isDesktop)
            Row(
              children: [
                Text('Inventory',
                    style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4)),
                const Spacer(),
                if (lowStockProducts.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: pos.warning.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_rounded, size: 14, color: pos.warning),
                        const SizedBox(width: 6),
                        Text('${lowStockProducts.length} low stock',
                            style: GoogleFonts.inter(
                                color: pos.warning,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _showProductForm(context),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add Product'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            )
          else
            // Phone Header
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Inventory',
                        style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4)),
                    const Spacer(),
                    if (lowStockProducts.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: pos.warning.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.warning_rounded, size: 12, color: pos.warning),
                            const SizedBox(width: 4),
                            Text('${lowStockProducts.length} low',
                                style: GoogleFonts.inter(
                                    color: pos.warning,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _showProductForm(context),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Add'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          const SizedBox(height: 16),

          // Search + Filter
          if (isDesktop)
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: pos.fill,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _buildCategoryDropdown(context, ref, categories, cs),
                ),
              ],
            )
          else
            Column(
              children: [
                SearchField(
                  hintText: 'Search products...',
                  onChanged: (query) {
                    ref.read(productSearchQueryProvider.notifier).state = query;
                  },
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: pos.fill,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _buildCategoryDropdown(context, ref, categories, cs),
                ),
              ],
            ),
          const SizedBox(height: 16),

          // ─── Products: Card list (Phone) / DataTable (Tablet/Desktop) ───
          Expanded(
            child: productsAsync.when(
              loading: () => Center(
                  child: CircularProgressIndicator(
                      color: cs.primary, strokeWidth: 2.5)),
              error: (error, _) => Center(
                  child: Text('Error: $error',
                      style: TextStyle(color: pos.error))),
              data: (_) {
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 56,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.2)),
                        const SizedBox(height: 16),
                        Text('No products found',
                            style: GoogleFonts.inter(
                                color: cs.onSurfaceVariant, fontSize: 16)),
                      ],
                    ),
                  );
                }

                // ─── Phone: Apple-style card list ───
                if (isPhone) {
                  return ListView.separated(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final product = filtered[index];
                      return _PhoneProductCard(
                        product: product,
                        pos: pos,
                        isDark: isDark,
                        onEdit: () => _showProductForm(context, product: product),
                        onStockIn: () => _showStockInDialog(context, product),
                        onDelete: () => _confirmDelete(context, product),
                      );
                    },
                  );
                }

                // ─── Tablet / Desktop: DataTable ───
                return Container(
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: isDark
                        ? Border.all(
                            color: Colors.white.withValues(alpha: 0.06), width: 0.5)
                        : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(
                          isDark
                              ? Colors.white.withValues(alpha: 0.04)
                              : Colors.black.withValues(alpha: 0.02),
                        ),
                        headingTextStyle: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurfaceVariant,
                        ),
                        dataTextStyle: GoogleFonts.inter(
                          fontSize: 14,
                          color: cs.onSurface,
                        ),
                        columnSpacing: 24,
                        dividerThickness: 0.5,
                        columns: [
                          DataColumn(
                              label: Text('Product',
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12))),
                          DataColumn(
                              label: Text('Category',
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12))),
                          DataColumn(
                              label: Text('Price',
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12)),
                              numeric: true),
                          DataColumn(
                              label: Text('Stock',
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12)),
                              numeric: true),
                          DataColumn(
                              label: Text('Status',
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12))),
                          DataColumn(
                              label: Text('Actions',
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12))),
                        ],
                        rows: filtered.map((product) {
                          return DataRow(
                            color: product.isOutOfStock
                                ? WidgetStateProperty.all(
                                    pos.error.withValues(alpha: 0.04))
                                : product.isLowStock
                                    ? WidgetStateProperty.all(
                                        pos.warning.withValues(alpha: 0.04))
                                    : null,
                            cells: [
                              DataCell(Text(product.name,
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w500))),
                              DataCell(Text(product.category,
                                  style: GoogleFonts.inter(
                                      color: cs.onSurfaceVariant))),
                              DataCell(Text(
                                  CurrencyFormatter.format(product.price),
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600))),
                              DataCell(Text('${product.stock}',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                    color: product.isOutOfStock
                                        ? pos.error
                                        : product.isLowStock
                                            ? pos.warning
                                            : cs.onSurface,
                                  ))),
                              DataCell(
                                product.isOutOfStock
                                    ? const StatusBadge.outOfStock()
                                    : product.isLowStock
                                        ? const StatusBadge.lowStock()
                                        : const StatusBadge(
                                            label: 'In Stock',
                                            type: BadgeType.success),
                              ),
                              DataCell(Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                        Icons.add_circle_outline_rounded,
                                        size: 18,
                                        color: pos.success),
                                    tooltip: 'Add Stock',
                                    onPressed: () =>
                                        _showStockInDialog(context, product),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.edit_rounded,
                                        size: 16, color: cs.primary),
                                    tooltip: 'Edit',
                                    onPressed: () => _showProductForm(context,
                                        product: product),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete_outline_rounded,
                                        size: 16, color: pos.error),
                                    tooltip: 'Delete',
                                    onPressed: () =>
                                        _confirmDelete(context, product),
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

  Widget _buildCategoryDropdown(BuildContext context, WidgetRef ref, List<String> categories, ColorScheme cs) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String?>(
        value: ref.watch(selectedCategoryProvider),
        hint: Text('All Categories',
            style: GoogleFonts.inter(
                color: cs.onSurfaceVariant, fontSize: 14)),
        dropdownColor: cs.surface,
        borderRadius: BorderRadius.circular(14),
        items: [
          DropdownMenuItem<String?>(
            value: null,
            child: Text('All Categories',
                style: GoogleFonts.inter(
                    fontSize: 14, color: cs.onSurface)),
          ),
          ...categories.map((c) => DropdownMenuItem(
                value: c,
                child: Text(c,
                    style: GoogleFonts.inter(
                        fontSize: 14, color: cs.onSurface)),
              )),
        ],
        onChanged: (value) {
          ref.read(selectedCategoryProvider.notifier).state = value;
        },
      ),
    );
  }

  void _showProductForm(BuildContext context, {Product? product}) {
    final isEdit = product != null;
    final nameController = TextEditingController(text: product?.name ?? '');
    final priceController =
        TextEditingController(text: product?.price.toString() ?? '');
    final stockController =
        TextEditingController(text: product?.stock.toString() ?? '0');
    final categoryController =
        TextEditingController(text: product?.category ?? '');
    final cs = Theme.of(context).colorScheme;
    final pos = context.pos;
    XFile? pickedImage;
    String? existingImageId = product?.imageId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
          backgroundColor: Theme.of(ctx).colorScheme.surface,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(isEdit ? 'Edit Product' : 'Add Product',
                            style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.4)),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: cs.onSurfaceVariant.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.close_rounded,
                                size: 16, color: cs.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ─── Image Picker ───
                    Center(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () async {
                          try {
                            final picker = ImagePicker();
                            final image = await picker.pickImage(
                                source: ImageSource.gallery, imageQuality: 70);
                            if (image != null) {
                              setState(() => pickedImage = image);
                            }
                          } catch (e) {
                            debugPrint('Error picking image: $e');
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error picking image: $e')),
                              );
                            }
                          }
                        },
                        child: Column(
                          children: [
                            Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                color: pos.fill.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: cs.primary.withValues(alpha: 0.2), width: 2),
                              ),
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: () {
                                      final img = pickedImage;
                                      if (img != null) {
                                        return ClipRRect(
                                          borderRadius: BorderRadius.circular(18),
                                          child: kIsWeb
                                              ? FutureBuilder<Uint8List>(
                                                  future: img.readAsBytes(),
                                                  builder: (context, snapshot) {
                                                    if (snapshot.hasData) {
                                                      return Image.memory(
                                                          snapshot.data!,
                                                          fit: BoxFit.cover);
                                                    }
                                                    return const Center(
                                                        child:
                                                            CircularProgressIndicator());
                                                  },
                                                )
                                              : Image.file(File(img.path),
                                                  fit: BoxFit.cover),
                                        );
                                      }
                                      if (existingImageId != null) {
                                        return ClipRRect(
                                          borderRadius: BorderRadius.circular(18),
                                          child: FutureBuilder<Uint8List?>(
                                            future: LocalStorageService()
                                                .getProductImageBytes(
                                                    existingImageId),
                                            builder: (context, snapshot) {
                                              if (snapshot.connectionState ==
                                                      ConnectionState.done &&
                                                  snapshot.data != null) {
                                                return Image.memory(snapshot.data!,
                                                    fit: BoxFit.cover);
                                              }
                                              return Center(
                                                child: Icon(Icons.add_a_photo_rounded,
                                                    size: 40,
                                                    color: cs.primary
                                                        .withValues(alpha: 0.5)),
                                              );
                                            },
                                          ),
                                        );
                                      }
                                      return Center(
                                        child: Icon(Icons.add_a_photo_rounded,
                                            size: 40,
                                            color:
                                                cs.primary.withValues(alpha: 0.5)),
                                      );
                                    }(),
                                  ),
                                  Positioned(
                                    bottom: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: cs.primary,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withValues(alpha: 0.2),
                                            blurRadius: 4,
                                          )
                                        ],
                                      ),
                                      child: const Icon(Icons.edit_rounded,
                                          size: 14, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              pickedImage != null || existingImageId != null
                                  ? 'Change Product Image'
                                  : 'Add Product Image',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: cs.primary,
                              ),
                            ),
                            Text(
                              'Tap to browse gallery',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    TextField(
                        controller: nameController,
                        decoration:
                            const InputDecoration(labelText: 'Product Name')),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: priceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                                labelText: 'Price (₹)', prefixText: '₹ '),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: stockController,
                            keyboardType: TextInputType.number,
                            decoration:
                                const InputDecoration(labelText: 'Stock'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                        controller: categoryController,
                        decoration:
                            const InputDecoration(labelText: 'Category')),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          final name = nameController.text.trim();
                          final price =
                              double.tryParse(priceController.text) ?? 0;
                          final stock =
                              int.tryParse(stockController.text) ?? 0;
                          final category = categoryController.text.trim();
                          if (name.isEmpty || price <= 0 || category.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                    'Please fill out all fields with valid values'),
                                backgroundColor: cs.error,
                              ),
                            );
                            return;
                          }

                          // Save image if path picked
                          String? imageId = existingImageId;
                          if (pickedImage != null) {
                            imageId = const Uuid().v4();
                            await LocalStorageService()
                                .saveProductImage(imageId, pickedImage!);
                          }

                          final repo = ProductRepository();
                          if (isEdit) {
                            await repo.updateProduct(product.id, {
                              'name': name,
                              'price': price,
                              'stock': stock,
                              'category': category,
                              'imageId': imageId,
                            });
                          } else {
                            final newProduct = Product(
                              id: '',
                              name: name,
                              price: price,
                              stock: stock,
                              category: category,
                              updatedAt: DateTime.now(),
                              imageId: imageId,
                            );
                            await repo.addProduct(newProduct);
                          }

                          await AuditRepository().log(
                            action: AppConstants.auditEdit,
                            description:
                                '${isEdit ? "Updated" : "Added"} product: $name',
                          );

                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(isEdit ? 'Update' : 'Add Product',
                            style: GoogleFonts.inter(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showStockInDialog(BuildContext context, Product product) {
    final qtyController = TextEditingController();
    final pos = context.pos;
    final cs = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        backgroundColor: Theme.of(ctx).colorScheme.surface,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add Stock',
                    style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4)),
                const SizedBox(height: 8),
                Text('${product.name} — Current: ${product.stock}',
                    style: GoogleFonts.inter(
                        color: cs.onSurfaceVariant, fontSize: 14)),
                const SizedBox(height: 16),
                TextField(
                  controller: qtyController,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration:
                      const InputDecoration(labelText: 'Quantity to Add'),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      final qty = int.tryParse(qtyController.text) ?? 0;
                      if (qty <= 0) return;
                      await ProductRepository()
                          .updateStock(product.id, qty);
                      await AuditRepository().log(
                        action: AppConstants.auditStockIn,
                        description: 'Stock-in: ${product.name} +$qty',
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: pos.success,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Add Stock',
                        style: GoogleFonts.inter(
                            fontSize: 16, fontWeight: FontWeight.w600)),
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
    final pos = context.pos;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Product',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text(
            'Are you sure you want to delete "${product.name}"?',
            style: GoogleFonts.inter(fontSize: 14)),
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
              backgroundColor: pos.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

/// Apple HIG-inspired product card for phone inventory view
class _PhoneProductCard extends StatelessWidget {
  final Product product;
  final dynamic pos;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onStockIn;
  final VoidCallback onDelete;

  const _PhoneProductCard({
    required this.product,
    required this.pos,
    required this.isDark,
    required this.onEdit,
    required this.onStockIn,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Color stockColor;
    String stockLabel;
    if (product.isOutOfStock) {
      stockColor = pos.error;
      stockLabel = 'Out of Stock';
    } else if (product.isLowStock) {
      stockColor = pos.warning;
      stockLabel = '${product.stock} left';
    } else {
      stockColor = pos.success;
      stockLabel = '${product.stock} in stock';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: product.isOutOfStock
            ? pos.error.withValues(alpha: 0.03)
            : cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: isDark
            ? Border.all(
                color: Colors.white.withValues(alpha: 0.06), width: 0.5)
            : null,
      ),
      child: Row(
        children: [
          // Product info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + Category row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        product.category,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: cs.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Price + Stock row
                Row(
                  children: [
                    Text(
                      CurrencyFormatter.format(product.price),
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: stockColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        stockLabel,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: stockColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action buttons
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PhoneActionButton(
                icon: Icons.add_rounded,
                color: pos.success,
                onTap: onStockIn,
                tooltip: 'Stock In',
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PhoneActionButton(
                    icon: Icons.edit_rounded,
                    color: cs.primary,
                    onTap: onEdit,
                    tooltip: 'Edit',
                    size: 32,
                  ),
                  const SizedBox(width: 6),
                  _PhoneActionButton(
                    icon: Icons.delete_outline_rounded,
                    color: pos.error,
                    onTap: onDelete,
                    tooltip: 'Delete',
                    size: 32,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PhoneActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;
  final double size;

  const _PhoneActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: size * 0.5, color: color),
        ),
      ),
    );
  }
}

