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
import '../../core/widgets/section_toggle.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/store_section.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/audit_repository.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/repositories/expense_repository.dart';
import '../../data/models/expense_model.dart';
import '../../providers/product_providers.dart';
import '../../providers/store_section_provider.dart';
import '../../providers/supplier_providers.dart';
import '../../data/models/supplier_model.dart';
import '../../data/repositories/supplier_repository.dart';
import '../../core/services/local_storage_service.dart';
import '../../core/utils/csv_exporter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsStreamProvider);
    final filtered = ref.watch(filteredProductsProvider);
    final categories = ref.watch(categoriesProvider);
    final suppliersAsync = ref.watch(suppliersStreamProvider);
    final suppliers = suppliersAsync.valueOrNull ?? [];
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
                const SizedBox(width: 16),
                const SectionToggle(),
                const Spacer(),
                if (lowStockProducts.isNotEmpty)
                  InkWell(
                    onTap: () => _showLowStockDetails(context, ref, lowStockProducts),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
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
                  ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _showProductForm(context, ref, suppliers),
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
                    const SectionToggle(compact: true),
                    if (lowStockProducts.isNotEmpty)
                      InkWell(
                        onTap: () => _showLowStockDetails(context, ref, lowStockProducts),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
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
                      ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _showProductForm(context, ref, suppliers),
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
                        onEdit: () => _showProductForm(context, ref, suppliers, product: product),
                        onStockIn: () => _showStockInDialog(context, product, suppliers),
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
                    child: Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: isDesktop,
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        scrollDirection: Axis.vertical,
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
                              label: Text('Supplier',
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12))),
                          DataColumn(
                              label: Text('Retail ₹',
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12)),
                              numeric: true),
                          DataColumn(
                              label: Text('Wholesale ₹',
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
                                  product.supplier.isNotEmpty ? product.supplier : '—',
                                  style: GoogleFonts.inter(
                                      color: product.supplier.isNotEmpty
                                          ? cs.onSurface
                                          : cs.onSurfaceVariant.withValues(alpha: 0.3)))),
                              DataCell(Text(
                                  CurrencyFormatter.format(product.price),
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600))),
                              DataCell(Text(
                                  product.wholesalePrice > 0
                                      ? CurrencyFormatter.format(product.wholesalePrice)
                                      : '—',
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w500,
                                      color: product.wholesalePrice > 0
                                          ? cs.onSurfaceVariant
                                          : cs.onSurfaceVariant.withValues(alpha: 0.3)))),
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
                                        _showStockInDialog(context, product, suppliers),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.edit_rounded,
                                        size: 16, color: cs.primary),
                                    tooltip: 'Edit',
                                    onPressed: () => _showProductForm(context, ref, suppliers,
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

  void _showProductForm(BuildContext context, WidgetRef ref, List<Supplier> suppliers, {Product? product}) {
    final isEdit = product != null;
    final nameController = TextEditingController(text: product?.name ?? '');
    final priceController =
        TextEditingController(text: product?.price.toString() ?? '');
    final wholesalePriceController =
        TextEditingController(text: product != null && product.wholesalePrice > 0 ? product.wholesalePrice.toString() : '');
    final stockController =
        TextEditingController(text: product?.stock.toString() ?? '0');
    final categoryController =
        TextEditingController(text: product?.category ?? '');
    
    // We will find supplier ID from name for backwards compatibility, or default to null
    String? selectedSupplierId;
    if (product != null && product.supplier.isNotEmpty) {
      final s = suppliers.where((element) => element.name == product.supplier).firstOrNull;
      if (s != null) selectedSupplierId = s.id;
    }
    final cs = Theme.of(context).colorScheme;
    final pos = context.pos;
    XFile? pickedImage;
    String? existingImageId = product?.imageId;
    StoreSection selectedSection = product != null
        ? StoreSection.fromString(product.section)
        : (ref.read(storeSectionProvider) == StoreSection.all
            ? StoreSection.store
            : ref.read(storeSectionProvider));
    bool isSaving = false;
    DateTime selectedDate = DateTime.now();

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
                    DropdownButtonFormField<String?>(
                      initialValue: selectedSupplierId,
                      decoration: const InputDecoration(labelText: 'Supplier (Optional)'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('No Supplier')),
                        ...suppliers.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
                      ],
                      onChanged: (val) => setState(() => selectedSupplierId = val),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: priceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                                labelText: 'Retail Price (₹)', prefixText: '₹ '),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: wholesalePriceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                                labelText: 'Wholesale Price (₹)', prefixText: '₹ '),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: stockController,
                            keyboardType: TextInputType.number,
                            decoration:
                                const InputDecoration(labelText: 'Stock'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                              controller: categoryController,
                              decoration:
                                  const InputDecoration(labelText: 'Category')),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: selectedDate,
                          firstDate: DateTime(2024),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() => selectedDate = picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Stock Date (Expense Date)',
                          suffixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                        ),
                        child: Text(DateFormatter.formatDate(selectedDate)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Section Picker
                    Text('Section',
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurfaceVariant)),
                    const SizedBox(height: 8),
                    SectionPicker(
                      value: selectedSection,
                      onChanged: (s) => setState(() => selectedSection = s),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : () async {
                          setState(() => isSaving = true);
                          final name = nameController.text.trim();
                          final price =
                              double.tryParse(priceController.text) ?? 0;
                          final wholesalePrice =
                              double.tryParse(wholesalePriceController.text) ?? 0;
                          final stock =
                              int.tryParse(stockController.text) ?? 0;
                          final category = categoryController.text.trim();
                          
                          String supplierName = '';
                          if (selectedSupplierId != null) {
                            supplierName = suppliers.firstWhere((s) => s.id == selectedSupplierId).name;
                          }

                          if (name.isEmpty || price <= 0 || category.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                    'Please fill out all fields with valid values'),
                                backgroundColor: cs.error,
                              ),
                            );
                            setState(() => isSaving = false);
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
                            final int stockDifference = stock - product.stock;
                            await repo.updateProduct(product.id, {
                              'name': name,
                              'price': price,
                              'wholesale_price': wholesalePrice,
                              'stock': stock,
                              'category': category,
                              'section': selectedSection.firestoreValue,
                              'supplier': supplierName,
                              'imageId': imageId,
                            });
                            
                            // Track expense if stock was increased during edit
                            if (stockDifference > 0 && wholesalePrice > 0) {
                              final expense = Expense(
                                id: '',
                                productName: name,
                                productId: product.id,
                                quantity: stockDifference,
                                cost: wholesalePrice,
                                section: selectedSection.firestoreValue,
                                type: 'product',
                                remark: supplierName.isNotEmpty ? 'Supplier: $supplierName (Restock)' : 'Manual Stock Update',
                                date: selectedDate,
                                createdAt: DateTime.now(),
                                supplierId: selectedSupplierId,
                                supplierName: supplierName.isNotEmpty ? supplierName : null,
                                paidAmount: 0, // Unpaid by default
                              );
                              await ExpenseRepository().addExpense(expense);
                              
                              if (selectedSupplierId != null) {
                                final totalCost = stockDifference * wholesalePrice;
                                await SupplierRepository().updateSupplierBalance(selectedSupplierId!, totalCost);
                              }
                            }
                          } else {
                            final newProduct = Product(
                              id: '',
                              name: name,
                              price: price,
                              wholesalePrice: wholesalePrice,
                              stock: stock,
                              category: category,
                              section: selectedSection.firestoreValue,
                              supplier: supplierName,
                              updatedAt: DateTime.now(),
                              imageId: imageId,
                            );
                            final newId = await repo.addProduct(newProduct);

                            // Auto-create expense from wholesale price × stock
                            if (wholesalePrice > 0 && stock > 0) {
                              final expense = Expense(
                                id: '',
                                productName: name,
                                productId: newId,
                                quantity: stock,
                                cost: wholesalePrice,
                                section: selectedSection.firestoreValue,
                                type: 'product',
                                remark: supplierName.isNotEmpty ? 'Supplier: $supplierName' : '',
                                date: selectedDate,
                                createdAt: DateTime.now(),
                                supplierId: selectedSupplierId,
                                supplierName: supplierName.isNotEmpty ? supplierName : null,
                                paidAmount: 0,
                              );
                              await ExpenseRepository().addExpense(expense);

                              if (selectedSupplierId != null) {
                                final totalCost = stock * wholesalePrice;
                                await SupplierRepository().updateSupplierBalance(selectedSupplierId!, totalCost);
                              }
                            }
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
                          disabledBackgroundColor: cs.primary.withValues(alpha: 0.5),
                        ),
                        child: isSaving
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(isEdit ? 'Update' : 'Add Product',
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

  void _showStockInDialog(BuildContext context, Product product, List<Supplier> suppliers) {
    final qtyController = TextEditingController();
    final wholesalePriceController = TextEditingController(text: product.wholesalePrice > 0 ? product.wholesalePrice.toString() : '');
    final pos = context.pos;
    final cs = Theme.of(context).colorScheme;
    DateTime selectedDate = DateTime.now();
    bool isSaving = false;
    
    // We will find supplier ID from name for backwards compatibility, or default to null
    String? selectedSupplierId;
    if (product.supplier.isNotEmpty) {
      final s = suppliers.where((element) => element.name == product.supplier).firstOrNull;
      if (s != null) selectedSupplierId = s.id;
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Dialog(
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
                const SizedBox(height: 12),
                TextField(
                  controller: wholesalePriceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Wholesale Price (₹)'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: selectedSupplierId,
                  decoration: const InputDecoration(labelText: 'Supplier (Optional)'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('No Supplier')),
                    ...suppliers.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
                  ],
                  onChanged: (val) => setState(() => selectedSupplierId = val),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime(2024),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => selectedDate = picked);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Stock Date (Expense Date)',
                      suffixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                    ),
                    child: Text(DateFormatter.formatDate(selectedDate)),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : () async {
                      final qty = int.tryParse(qtyController.text) ?? 0;
                      final wholesalePrice = double.tryParse(wholesalePriceController.text) ?? 0;
                      if (qty <= 0) return;
                      
                      setState(() => isSaving = true);
                      
                      await ProductRepository().updateStock(product.id, qty);

                      // Sync updated wholesale price
                      if (wholesalePrice > 0 && wholesalePrice != product.wholesalePrice) {
                        await ProductRepository().updateProduct(product.id, {'wholesale_price': wholesalePrice});
                      }

                      // Auto-create expense for restocked items
                      if (wholesalePrice > 0) {
                        String supplierName = '';
                        if (selectedSupplierId != null) {
                          supplierName = suppliers.firstWhere((s) => s.id == selectedSupplierId).name;
                        }

                        final expense = Expense(
                          id: '',
                          productName: product.name,
                          productId: product.id,
                          quantity: qty,
                          cost: wholesalePrice,
                          section: product.section,
                          type: 'product',
                          remark: supplierName.isNotEmpty ? 'Supplier: $supplierName' : 'Restock',
                          date: selectedDate,
                          createdAt: DateTime.now(),
                          supplierId: selectedSupplierId,
                          supplierName: supplierName.isNotEmpty ? supplierName : null,
                          paidAmount: 0,
                        );
                        await ExpenseRepository().addExpense(expense);
                        
                        if (selectedSupplierId != null) {
                          final totalCost = qty * wholesalePrice;
                          await SupplierRepository().updateSupplierBalance(selectedSupplierId!, totalCost);
                        }
                      }

                      await AuditRepository().log(
                        action: AppConstants.auditStockIn,
                        description: 'Stock-in: ${product.name} +$qty',
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: pos.success,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: pos.success.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text('Add Stock',
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
    );
  }

  void _confirmDelete(BuildContext context, Product product) {
    final pos = context.pos;
    bool isDeleting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Delete Product',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          content: Text('Are you sure you want to delete "${product.name}"?',
              style: GoogleFonts.inter(fontSize: 14)),
          actions: [
            TextButton(
              onPressed: isDeleting ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isDeleting
                  ? null
                  : () async {
                      setState(() => isDeleting = true);
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
                disabledBackgroundColor: pos.error.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: isDeleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Delete'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLowStockDetails(BuildContext context, WidgetRef ref, List<Product> lowStockProducts) {
    final cs = Theme.of(context).colorScheme;
    final pos = context.pos;
    bool isExporting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
          backgroundColor: cs.surface,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Low Stock Items',
                        style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4)),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: isExporting
                          ? null
                          : () async {
                              setState(() => isExporting = true);
                              try {
                                await CsvExporter.exportLowStockReport(
                                    lowStockProducts);
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Exported Low Stock Report to CSV')),
                                  );
                                }
                              } finally {
                                if (ctx.mounted) {
                                  setState(() => isExporting = false);
                                }
                              }
                            },
                      icon: isExporting
                          ? SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: cs.primary,
                              ),
                            )
                          : const Icon(Icons.download_rounded, size: 16),
                      label: const Text('Export CSV'),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(width: 12),
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
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.separated(
                    itemCount: lowStockProducts.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final product = lowStockProducts[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(product.name,
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                        subtitle: Text(product.category,
                            style: GoogleFonts.inter(fontSize: 12, color: cs.onSurfaceVariant)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: pos.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text('${product.stock} in stock',
                                  style: GoogleFonts.inter(
                                      color: pos.error,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.add_shopping_cart_rounded, size: 20),
                              color: cs.primary,
                              tooltip: 'Restock',
                              onPressed: () {
                                Navigator.pop(ctx);
                                // Can't pass suppliers easily here since it's inside another dialog,
                                // but we can just use the provider manually or re-fetch.
                                // For simplicity, we just pass the empty list and let user select
                                _showStockInDialog(context, product, ref.read(suppliersStreamProvider).valueOrNull ?? []);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
                    if (product.wholesalePrice > 0) ...[
                      const SizedBox(width: 6),
                      Text(
                        '(Cost: ${CurrencyFormatter.format(product.wholesalePrice)})',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
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
                if (product.supplier.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Supplier: ${product.supplier}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
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

