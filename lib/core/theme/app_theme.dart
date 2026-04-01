import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: _colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: _textTheme,
      appBarTheme: _appBarTheme,
      cardTheme: _cardTheme,
      elevatedButtonTheme: _elevatedButtonTheme,
      outlinedButtonTheme: _outlinedButtonTheme,
      textButtonTheme: _textButtonTheme,
      inputDecorationTheme: _inputDecorationTheme,
      dialogTheme: _dialogTheme,
      chipTheme: _chipTheme,
      floatingActionButtonTheme: _fabTheme,
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceContainerHigh,
        contentTextStyle: GoogleFonts.inter(
          color: AppColors.onSurface,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.surfaceBright,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: GoogleFonts.inter(
          color: AppColors.onSurface,
          fontSize: 12,
        ),
      ),
    );
  }

  // ─── Color Scheme ───
  static const ColorScheme _colorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.primaryLight,
    secondary: AppColors.secondary,
    onSecondary: AppColors.onSecondary,
    secondaryContainer: AppColors.surfaceContainerHigh,
    onSecondaryContainer: AppColors.secondary,
    surface: AppColors.surface,
    onSurface: AppColors.onSurface,
    onSurfaceVariant: AppColors.onSurfaceVariant,
    error: AppColors.error,
    onError: Colors.white,
    errorContainer: AppColors.errorContainer,
    onErrorContainer: AppColors.errorLight,
    outline: AppColors.border,
    outlineVariant: AppColors.divider,
    shadow: AppColors.shadow,
  );

  // ─── Typography ───
  static TextTheme get _textTheme {
    final headingFont = GoogleFonts.outfit(color: AppColors.onBackground);
    final bodyFont = GoogleFonts.inter(color: AppColors.onSurface);

    return TextTheme(
      // Display
      displayLarge: headingFont.copyWith(fontSize: 40, fontWeight: FontWeight.w700),
      displayMedium: headingFont.copyWith(fontSize: 34, fontWeight: FontWeight.w600),
      displaySmall: headingFont.copyWith(fontSize: 28, fontWeight: FontWeight.w600),

      // Headline
      headlineLarge: headingFont.copyWith(fontSize: 26, fontWeight: FontWeight.w600),
      headlineMedium: headingFont.copyWith(fontSize: 22, fontWeight: FontWeight.w600),
      headlineSmall: headingFont.copyWith(fontSize: 18, fontWeight: FontWeight.w600),

      // Title
      titleLarge: headingFont.copyWith(fontSize: 20, fontWeight: FontWeight.w600),
      titleMedium: headingFont.copyWith(fontSize: 16, fontWeight: FontWeight.w500),
      titleSmall: headingFont.copyWith(fontSize: 14, fontWeight: FontWeight.w500),

      // Body
      bodyLarge: bodyFont.copyWith(fontSize: 16, fontWeight: FontWeight.w400),
      bodyMedium: bodyFont.copyWith(fontSize: 14, fontWeight: FontWeight.w400),
      bodySmall: bodyFont.copyWith(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.onSurfaceVariant),

      // Label
      labelLarge: bodyFont.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
      labelMedium: bodyFont.copyWith(fontSize: 12, fontWeight: FontWeight.w500),
      labelSmall: bodyFont.copyWith(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.onSurfaceVariant),
    );
  }

  // ─── AppBar ───
  static AppBarTheme get _appBarTheme => AppBarTheme(
    backgroundColor: AppColors.surface,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    centerTitle: false,
    titleTextStyle: GoogleFonts.outfit(
      color: AppColors.onBackground,
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
    iconTheme: const IconThemeData(color: AppColors.onSurface),
  );

  // ─── Cards ───
  static CardThemeData get _cardTheme => CardThemeData(
    color: AppColors.surfaceVariant,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: const BorderSide(color: AppColors.border, width: 0.5),
    ),
    margin: const EdgeInsets.all(4),
  );

  // ─── Elevated Button ───
  static ElevatedButtonThemeData get _elevatedButtonTheme => ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
      minimumSize: const Size(120, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      textStyle: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  // ─── Outlined Button ───
  static OutlinedButtonThemeData get _outlinedButtonTheme => OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primary,
      minimumSize: const Size(120, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: const BorderSide(color: AppColors.primary, width: 1.5),
      textStyle: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  // ─── Text Button ───
  static TextButtonThemeData get _textButtonTheme => TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primary,
      minimumSize: const Size(80, 44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      textStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  // ─── Input Decoration ───
  static InputDecorationTheme get _inputDecorationTheme => InputDecorationTheme(
    filled: true,
    fillColor: AppColors.surfaceContainer,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border, width: 0.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.error),
    ),
    hintStyle: GoogleFonts.inter(
      color: AppColors.onSurfaceVariant,
      fontSize: 14,
    ),
    labelStyle: GoogleFonts.inter(
      color: AppColors.onSurfaceVariant,
      fontSize: 14,
    ),
  );

  // ─── Dialog ───
  static DialogThemeData get _dialogTheme => DialogThemeData(
    backgroundColor: AppColors.surfaceVariant,
    surfaceTintColor: Colors.transparent,
    elevation: 8,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    titleTextStyle: GoogleFonts.outfit(
      color: AppColors.onBackground,
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
    contentTextStyle: GoogleFonts.inter(
      color: AppColors.onSurface,
      fontSize: 14,
    ),
  );

  // ─── Chip ───
  static ChipThemeData get _chipTheme => ChipThemeData(
    backgroundColor: AppColors.surfaceContainer,
    selectedColor: AppColors.primaryContainer,
    disabledColor: AppColors.surfaceContainer,
    labelStyle: GoogleFonts.inter(
      color: AppColors.onSurface,
      fontSize: 13,
      fontWeight: FontWeight.w500,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: const BorderSide(color: AppColors.border, width: 0.5),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  );

  // ─── FAB ───
  static FloatingActionButtonThemeData get _fabTheme => FloatingActionButtonThemeData(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.onPrimary,
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  );
}
