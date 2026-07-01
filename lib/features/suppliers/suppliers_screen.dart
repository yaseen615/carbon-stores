import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/pos_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/responsive_helper.dart';
import '../../data/models/supplier_model.dart';
import '../../data/repositories/supplier_repository.dart';
import '../../providers/supplier_providers.dart';
import 'supplier_details_screen.dart';

class SuppliersScreen extends ConsumerStatefulWidget {
  const SuppliersScreen({super.key});

  @override
  ConsumerState<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends ConsumerState<SuppliersScreen> {
  @override
  Widget build(BuildContext context) {
    final suppliersAsync = ref.watch(suppliersStreamProvider);
    final cs = Theme.of(context).colorScheme;
    final pos = context.pos;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final isDesktop = Responsive.isTabletOrDesktop(context);
    final isPhone = Responsive.isPhone(context);
    final topPadding = isPhone ? MediaQuery.paddingOf(context).top + 16 : 20.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(isDesktop ? 24 : 16, topPadding, isDesktop ? 24 : 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          if (isDesktop)
            Row(
              children: [
                Text('Suppliers',
                    style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4)),
                const Spacer(),
                _buildAddButton(context),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Suppliers',
                    style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: _buildAddButton(context),
                ),
              ],
            ),
          const SizedBox(height: 20),

          // Suppliers List
          Expanded(
            child: suppliersAsync.when(
              loading: () => Center(
                  child: CircularProgressIndicator(
                      color: cs.primary, strokeWidth: 2.5)),
              error: (error, _) => Center(
                  child:
                      Text('Error: $error', style: TextStyle(color: pos.error))),
              data: (suppliers) {
                if (suppliers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.local_shipping_outlined,
                            size: 56,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.2)),
                        const SizedBox(height: 16),
                        Text('No suppliers added yet',
                            style: GoogleFonts.inter(
                                color: cs.onSurfaceVariant, fontSize: 16)),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isDesktop ? 3 : 1,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: isDesktop ? 2.5 : 3.5,
                  ),
                  itemCount: suppliers.length,
                  itemBuilder: (context, index) {
                    final supplier = suppliers[index];
                    return _buildSupplierCard(context, supplier, cs, pos, isDark);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierCard(BuildContext context, Supplier supplier, ColorScheme cs, POSColors pos, bool isDark) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SupplierDetailsScreen(supplier: supplier),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
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
              ? Border.all(color: Colors.white.withValues(alpha: 0.06), width: 0.5)
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.business_rounded, color: cs.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    supplier.name,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (supplier.remark.isNotEmpty)
                    Text(
                      supplier.remark,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Balance',
                  style: GoogleFonts.inter(fontSize: 11, color: cs.onSurfaceVariant)),
                const SizedBox(height: 2),
                Text(
                  CurrencyFormatter.format(supplier.balance),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: supplier.balance > 0 ? pos.error : pos.success,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _showAddSupplierDialog(context),
      icon: const Icon(Icons.add_rounded, size: 18),
      label: const Text('Add Supplier'),
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }

  void _showAddSupplierDialog(BuildContext context) {
    final nameController = TextEditingController();
    final remarkController = TextEditingController();
    final balanceController = TextEditingController();
    final cs = Theme.of(context).colorScheme;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: cs.surface,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Add New Supplier',
                          style: GoogleFonts.inter(
                              fontSize: 20, fontWeight: FontWeight.w700)),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded),
                        splashRadius: 20,
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Supplier Name *'),
                    autofocus: true,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: remarkController,
                    decoration: const InputDecoration(labelText: 'Contact / Address / Remarks'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: balanceController,
                    decoration: const InputDecoration(
                      labelText: 'Opening Balance (₹)',
                      hintText: 'Amount you currently owe them',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isSaving ? null : () async {
                        final name = nameController.text.trim();
                        if (name.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: const Text('Name is required'), backgroundColor: cs.error),
                          );
                          return;
                        }

                        setState(() => isSaving = true);
                        
                        final balance = double.tryParse(balanceController.text) ?? 0.0;
                        
                        final supplier = Supplier(
                          id: '',
                          name: name,
                          remark: remarkController.text.trim(),
                          balance: balance,
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                        );

                        await SupplierRepository().addSupplier(supplier);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isSaving 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text('Save Supplier', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
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
