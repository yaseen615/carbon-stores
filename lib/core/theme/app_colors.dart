import 'package:flutter/material.dart';

/// CarbonGurukulam brand colors derived from the CG logo
/// Logo: cream "Cg" monogram on warm brown background
class AppColors {
  AppColors._();

  // ─── Brand Primary (Warm Brown from logo) ───
  static const Color primary = Color(0xFFA0722B);
  static const Color primaryLight = Color(0xFFD4A76A);
  static const Color primaryDark = Color(0xFF7A5520);
  static const Color primaryContainer = Color(0xFF2E2117);

  // ─── Brand Secondary (Cream from logo text) ───
  static const Color secondary = Color(0xFFF5E6C8);
  static const Color secondaryLight = Color(0xFFFFF8ED);
  static const Color secondaryDark = Color(0xFFD4C4A0);

  // ─── Surfaces (Dark Theme) ───
  static const Color background = Color(0xFF121010);
  static const Color surface = Color(0xFF1A1614);
  static const Color surfaceVariant = Color(0xFF231F1B);
  static const Color surfaceContainer = Color(0xFF2A2420);
  static const Color surfaceContainerHigh = Color(0xFF342D28);
  static const Color surfaceBright = Color(0xFF3E3630);

  // ─── Text ───
  static const Color onBackground = Color(0xFFF5E6C8);
  static const Color onSurface = Color(0xFFEDE0D0);
  static const Color onSurfaceVariant = Color(0xFFB5A898);
  static const Color onPrimary = Color(0xFFFFF8ED);
  static const Color onSecondary = Color(0xFF2E2117);

  // ─── Semantic Colors ───
  static const Color success = Color(0xFF4CAF50);       // Green → Paid
  static const Color successLight = Color(0xFF81C784);
  static const Color successContainer = Color(0xFF1B3A1B);

  static const Color error = Color(0xFFEF5350);         // Red → Debt
  static const Color errorLight = Color(0xFFE57373);
  static const Color errorContainer = Color(0xFF3A1B1B);

  static const Color info = Color(0xFF42A5F5);           // Blue → Wallet
  static const Color infoLight = Color(0xFF64B5F6);
  static const Color infoContainer = Color(0xFF1B2A3A);

  static const Color warning = Color(0xFFFFB74D);        // Orange → Low stock
  static const Color warningContainer = Color(0xFF3A2E1B);

  // ─── Borders & Dividers ───
  static const Color border = Color(0xFF3E3630);
  static const Color divider = Color(0xFF2A2420);

  // ─── Shadows ───
  static const Color shadow = Color(0x40000000);

  // ─── Category Colors ───
  static const List<Color> categoryColors = [
    Color(0xFFA0722B),  // Brown
    Color(0xFF5C8A4D),  // Green
    Color(0xFF4A7A8C),  // Teal
    Color(0xFF8C6B4A),  // Warm Brown
    Color(0xFF6B5A8C),  // Purple
    Color(0xFF8C4A5A),  // Rose
    Color(0xFF4A6B8C),  // Steel Blue
    Color(0xFF8C8A4A),  // Olive
  ];
}
