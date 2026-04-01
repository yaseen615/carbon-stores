import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Reusable CG logo widget that renders the logo as a styled monogram
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
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(size * 0.25),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            )
          : null,
      child: Center(
        child: Text(
          'Cg',
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: size * 0.45,
            fontWeight: FontWeight.w300,
            color: AppColors.secondary,
            letterSpacing: -1,
            height: 1,
          ),
        ),
      ),
    );
  }
}
