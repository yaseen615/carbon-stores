import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/product_providers.dart';

class CategoryTabs extends ConsumerWidget {
  const CategoryTabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final selected = ref.watch(selectedCategoryProvider);

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _CategoryChip(
            label: 'All',
            isSelected: selected == null,
            onTap: () => ref.read(selectedCategoryProvider.notifier).state = null,
          ),
          ...categories.map((cat) => Padding(
            padding: const EdgeInsets.only(left: 8),
            child: _CategoryChip(
              label: cat,
              isSelected: selected == cat,
              onTap: () => ref.read(selectedCategoryProvider.notifier).state = cat,
            ),
          )),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends State<_CategoryChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? cs.primary
                : _isHovered 
                    ? cs.onSurfaceVariant.withValues(alpha: 0.05)
                    : cs.surface,
            borderRadius: BorderRadius.circular(999), // Pill
            border: Border.all(
              color: widget.isSelected
                  ? Colors.transparent
                  : cs.onSurfaceVariant.withValues(alpha: 0.15),
            ),
          ),
          child: Center(
            child: Text(
              widget.label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: widget.isSelected ? FontWeight.w500 : FontWeight.w400,
                color: widget.isSelected
                    ? cs.onPrimary
                    : cs.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
