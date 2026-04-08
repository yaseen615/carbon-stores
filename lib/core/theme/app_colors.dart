import 'package:flutter/material.dart';

/// Apple Human Interface Guidelines — Inspired Color System
/// Dual adaptive palette: Light & Dark are independently designed.
/// Dark mode is NOT inverted light — it's a separate intentional design.
class AppColors {
  AppColors._();

  // ─── Brand Colors (Constant across themes) ───
  static const Color brandPrimary = Color(0xFFA0722B);
  static const Color brandSecondary = Color(0xFFF5E6C8);

  // ═══════════════════════════════════════════════════════════════
  //  LIGHT THEME PALETTE
  // ═══════════════════════════════════════════════════════════════

  // Backgrounds
  static const Color lightBackground = Color(0xFFF4F5F7);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightElevatedSurface = Color(0xFFFFFFFF);
  static const Color lightGroupedBackground = Color(0xFFF4F5F7);

  // Primary
  static const Color lightPrimary = Color(0xFF1E58FF);
  static const Color lightPrimaryContainer = Color(0xFFE5F1FF);

  // Labels (Text)
  static const Color lightLabelPrimary = Color(0xFF1D1D1F);
  static const Color lightLabelSecondary = Color(0xFF6E6E73);
  static const Color lightLabelTertiary = Color(0xFFAEAEB2);
  static const Color lightLabelQuaternary = Color(0xFFC7C7CC);

  // Fills
  static const Color lightFill = Color(0x14787880);         // 8% opacity
  static const Color lightFillSecondary = Color(0x0A787880); // 4% opacity
  static const Color lightFillTertiary = Color(0x1F787880);  // 12% opacity

  // Separator
  static const Color lightSeparator = Color(0x1F3C3C43);     // 12% opacity
  static const Color lightSeparatorOpaque = Color(0xFFC6C6C8);

  // ═══════════════════════════════════════════════════════════════
  //  DARK THEME PALETTE
  // ═══════════════════════════════════════════════════════════════

  // Backgrounds
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF1C1C1E);
  static const Color darkElevatedSurface = Color(0xFF2C2C2E);
  static const Color darkGroupedBackground = Color(0xFF1C1C1E);

  // Primary
  static const Color darkPrimary = Color(0xFF0A84FF);
  static const Color darkPrimaryContainer = Color(0xFF003A70);

  // Labels (Text)
  static const Color darkLabelPrimary = Color(0xFFFFFFFF);
  static const Color darkLabelSecondary = Color(0xFF8E8E93);
  static const Color darkLabelTertiary = Color(0xFF48484A);
  static const Color darkLabelQuaternary = Color(0xFF3A3A3C);

  // Fills
  static const Color darkFill = Color(0x5C787880);           // 36% opacity
  static const Color darkFillSecondary = Color(0x52787880);   // 32% opacity
  static const Color darkFillTertiary = Color(0x3D787880);    // 24% opacity

  // Separator
  static const Color darkSeparator = Color(0xA6545458);       // 65% opacity
  static const Color darkSeparatorOpaque = Color(0xFF38383A);

  // ═══════════════════════════════════════════════════════════════
  //  SEMANTIC COLORS (Adaptive — used via POSColors)
  // ═══════════════════════════════════════════════════════════════

  // Apple System Colors — Light
  static const Color lightSuccess = Color(0xFF34C759);
  static const Color lightError = Color(0xFFFF3B30);
  static const Color lightWarning = Color(0xFFFF9500);
  static const Color lightInfo = Color(0xFF5856D6);

  // Apple System Colors — Dark
  static const Color darkSuccess = Color(0xFF30D158);
  static const Color darkError = Color(0xFFFF453A);
  static const Color darkWarning = Color(0xFFFF9F0A);
  static const Color darkInfo = Color(0xFF5E5CE6);

  // ─── Category Colors (Muted, works on both themes) ───
  static const List<Color> categoryColors = [
    Color(0xFF007AFF), // Blue
    Color(0xFF34C759), // Green
    Color(0xFFFF9500), // Orange
    Color(0xFF5856D6), // Indigo
    Color(0xFFFF2D55), // Pink
    Color(0xFFAF52DE), // Purple
    Color(0xFF00C7BE), // Teal
    Color(0xFFFF9500), // Orange variant
  ];
}
