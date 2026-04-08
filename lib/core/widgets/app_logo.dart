import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

/// Refined CG logo monogram — Apple-inspired treatment.
class AppLogo extends StatelessWidget {
  final double size;
  final bool showBackground;

  const AppLogo({
    super.key,
    this.size = 48,
    this.showBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: showBackground
          ? BoxDecoration(
              color: AppColors.brandPrimary,
              borderRadius: BorderRadius.circular(size * 0.28),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brandPrimary.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            )
          : null,
      child: Center(
        child: Text(
          'Cg',
          style: GoogleFonts.inter(
            fontSize: size * 0.42,
            fontWeight: FontWeight.w300,
            color: AppColors.brandSecondary,
            letterSpacing: -1,
            height: 1,
          ),
        ),
      ),
    );
  }
}
