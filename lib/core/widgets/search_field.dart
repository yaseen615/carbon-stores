import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/pos_colors.dart';

/// Apple HIG-style search bar — borderless, filled, rounded.
class SearchField extends StatelessWidget {
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;
  final TextEditingController? controller;
  final bool autofocus;

  const SearchField({
    super.key,
    this.hintText = 'Search...',
    required this.onChanged,
    this.onClear,
    this.controller,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pos = context.pos;

    return TextField(
      controller: controller,
      autofocus: autofocus,
      onChanged: onChanged,
      style: GoogleFonts.inter(color: cs.onSurface, fontSize: 15),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.inter(
          color: pos.labelTertiary,
          fontSize: 15,
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          color: pos.labelTertiary,
          size: 20,
        ),
        suffixIcon: controller != null && controller!.text.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.close_rounded, size: 18, color: pos.labelSecondary),
                onPressed: () {
                  controller?.clear();
                  onChanged('');
                  onClear?.call();
                },
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        filled: true,
        fillColor: pos.fill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
      ),
    );
  }
}
