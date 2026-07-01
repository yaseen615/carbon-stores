import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/pos_colors.dart';
import '../../../core/constants/store_section.dart';
import '../../../data/models/product_model.dart';
import '../../../providers/multi_cart_provider.dart';

class CustomBillDialog extends ConsumerStatefulWidget {
  const CustomBillDialog({super.key});

  @override
  ConsumerState<CustomBillDialog> createState() => _CustomBillDialogState();
}

class _CustomBillDialogState extends ConsumerState<CustomBillDialog> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  StoreSection _selectedSection = StoreSection.store;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _addToCart() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final price = double.parse(_priceController.text.trim());
      
      final customProduct = Product(
        id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
        name: name.isEmpty ? 'Custom Item' : name,
        price: price,
        stock: 9999, // practically infinite for custom items
        category: 'Custom',
        section: _selectedSection.name,
        updatedAt: DateTime.now(),
      );

      ref.read(multiCartProvider.notifier).addProduct(customProduct);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pos = context.pos;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: cs.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.add_shopping_cart_rounded, color: cs.primary),
                        const SizedBox(width: 12),
                        Text(
                          'Add Custom Bill',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                      color: cs.onSurfaceVariant,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: cs.onSurfaceVariant.withValues(alpha: 0.1)),
                const SizedBox(height: 16),
                
                // Name Field
                Text(
                  'Item Name (Optional)',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: pos.labelTertiary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'e.g., Special Service',
                    hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                    filled: true,
                    fillColor: pos.fillSecondary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: cs.onSurface,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Price Field
                Text(
                  'Amount',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: pos.labelTertiary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.currency_rupee_rounded, size: 16, color: cs.primary),
                    hintText: '0.00',
                    hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                    filled: true,
                    fillColor: pos.fillSecondary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: cs.onSurface,
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Enter an amount';
                    final num = double.tryParse(val);
                    if (num == null || num <= 0) return 'Enter a valid amount';
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Section Selection
                Text(
                  'Section',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: pos.labelTertiary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _SectionChip(
                        title: 'Store',
                        icon: Icons.storefront_rounded,
                        isSelected: _selectedSection == StoreSection.store,
                        onTap: () => setState(() => _selectedSection = StoreSection.store),
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SectionChip(
                        title: 'Cafe',
                        icon: Icons.local_cafe_rounded,
                        isSelected: _selectedSection == StoreSection.cafe,
                        onTap: () => setState(() => _selectedSection = StoreSection.cafe),
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _addToCart,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Add to Cart',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionChip extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;

  const _SectionChip({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? color 
                : cs.onSurfaceVariant.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? color : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? color : cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
