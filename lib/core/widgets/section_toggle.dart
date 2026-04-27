import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/store_section.dart';
import '../../providers/store_section_provider.dart';

/// Apple-style segmented control for toggling between Cafe / Store / All.
/// Reads and writes to the global [storeSectionProvider].
///
/// Set [compact] to true for tighter padding (e.g., inside dialogs).
class SectionToggle extends ConsumerWidget {
  final bool compact;

  const SectionToggle({super.key, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(storeSectionProvider);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 'combined' is a data-only value — not a user-selectable filter
    const uiSections = [StoreSection.all, StoreSection.cafe, StoreSection.store];
    return Container(
      height: compact ? 34 : 38,
      decoration: BoxDecoration(
        color: isDark
            ? cs.surfaceContainerHighest.withValues(alpha: 0.4)
            : cs.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: uiSections.map((section) {
          final isSelected = section == current;
          return GestureDetector(
            onTap: () {
              ref.read(storeSectionProvider.notifier).state = section;
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 12 : 16,
                vertical: compact ? 4 : 6,
              ),
              decoration: BoxDecoration(
                color: isSelected ? cs.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: isDark ? 0.25 : 0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                section.label,
                style: GoogleFonts.inter(
                  fontSize: compact ? 12 : 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? cs.primary : cs.onSurfaceVariant,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Standalone section picker for use in dialogs/forms.
/// Does NOT use the global provider — returns the selected value via callback.
class SectionPicker extends StatelessWidget {
  final StoreSection value;
  final ValueChanged<StoreSection> onChanged;
  final bool showAll;

  const SectionPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.showAll = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final sections = showAll
        ? StoreSection.values
        : [StoreSection.cafe, StoreSection.store];

    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: isDark
            ? cs.surfaceContainerHighest.withValues(alpha: 0.4)
            : cs.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: sections.map((section) {
          final isSelected = section == value;
          return GestureDetector(
            onTap: () => onChanged(section),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? cs.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: isDark ? 0.25 : 0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                section.label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? cs.primary : cs.onSurfaceVariant,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
