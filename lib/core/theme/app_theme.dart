import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'pos_colors.dart';

class AppTheme {
  AppTheme._();

  // ═══════════════════════════════════════════════════════════════════
  //  LIGHT THEME — Apple HIG Inspired
  // ═══════════════════════════════════════════════════════════════════
  static ThemeData get lightTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      // Primary
      primary: AppColors.lightPrimary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.lightPrimaryContainer,
      onPrimaryContainer: AppColors.lightPrimary,
      // Secondary (brand)
      secondary: AppColors.brandPrimary,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFFFF3E0),
      onSecondaryContainer: Color(0xFF7A5520),
      // Surface
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightLabelPrimary,
      onSurfaceVariant: AppColors.lightLabelSecondary,
      surfaceContainerHighest: Color(0xFFF2F2F7),
      // Error
      error: AppColors.lightError,
      onError: Colors.white,
      errorContainer: Color(0x1AFF3B30),
      onErrorContainer: AppColors.lightError,
      // Outline
      outline: AppColors.lightSeparatorOpaque,
      outlineVariant: AppColors.lightSeparator,
      // Shadow
      shadow: Color(0x0A000000),
      // Inverse
      inverseSurface: Color(0xFF1D1D1F),
      onInverseSurface: Color(0xFFF5F5F5),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.lightBackground,
      textTheme: _buildTextTheme(Brightness.light),
      appBarTheme: _buildAppBarTheme(colorScheme),
      cardTheme: _buildCardTheme(colorScheme),
      elevatedButtonTheme: _buildElevatedButtonTheme(colorScheme),
      outlinedButtonTheme: _buildOutlinedButtonTheme(colorScheme),
      textButtonTheme: _buildTextButtonTheme(colorScheme),
      inputDecorationTheme: _buildInputDecorationTheme(colorScheme),
      dialogTheme: _buildDialogTheme(colorScheme),
      chipTheme: _buildChipTheme(colorScheme),
      floatingActionButtonTheme: _buildFabTheme(colorScheme),
      dividerTheme: DividerThemeData(
        color: AppColors.lightSeparator,
        thickness: 0.5,
        space: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF1D1D1F),
        contentTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: const Color(0xFF1D1D1F),
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: GoogleFonts.inter(color: Colors.white, fontSize: 13),
      ),
      extensions: const [POSColors.light],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  DARK THEME — Apple HIG Inspired
  // ═══════════════════════════════════════════════════════════════════
  static ThemeData get darkTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      // Primary
      primary: AppColors.darkPrimary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.darkPrimaryContainer,
      onPrimaryContainer: Color(0xFF82B1FF),
      // Secondary
      secondary: Color(0xFFD4A76A),
      onSecondary: Color(0xFF2E2117),
      secondaryContainer: Color(0xFF3A2E1B),
      onSecondaryContainer: Color(0xFFF5E6C8),
      // Surface
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkLabelPrimary,
      onSurfaceVariant: AppColors.darkLabelSecondary,
      surfaceContainerHighest: AppColors.darkElevatedSurface,
      // Error
      error: AppColors.darkError,
      onError: Colors.white,
      errorContainer: Color(0x26FF453A),
      onErrorContainer: Color(0xFFFF8A80),
      // Outline
      outline: AppColors.darkSeparatorOpaque,
      outlineVariant: AppColors.darkSeparator,
      // Shadow
      shadow: Color(0x40000000),
      // Inverse
      inverseSurface: Color(0xFFE0E0E0),
      onInverseSurface: Color(0xFF1D1D1F),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.darkBackground,
      textTheme: _buildTextTheme(Brightness.dark),
      appBarTheme: _buildAppBarTheme(colorScheme),
      cardTheme: _buildCardTheme(colorScheme),
      elevatedButtonTheme: _buildElevatedButtonTheme(colorScheme),
      outlinedButtonTheme: _buildOutlinedButtonTheme(colorScheme),
      textButtonTheme: _buildTextButtonTheme(colorScheme),
      inputDecorationTheme: _buildInputDecorationTheme(colorScheme),
      dialogTheme: _buildDialogTheme(colorScheme),
      chipTheme: _buildChipTheme(colorScheme),
      floatingActionButtonTheme: _buildFabTheme(colorScheme),
      dividerTheme: DividerThemeData(
        color: AppColors.darkSeparator,
        thickness: 0.5,
        space: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkElevatedSurface,
        contentTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.darkElevatedSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: GoogleFonts.inter(color: Colors.white, fontSize: 13),
      ),
      extensions: const [POSColors.dark],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  TYPOGRAPHY — Unified Inter (≈ SF Pro)
  //  Apple HIG Type Scale:
  //    Large Title: 34 / w700
  //    Title 1:     28 / w700
  //    Title 2:     22 / w700
  //    Title 3:     20 / w600
  //    Headline:    17 / w600
  //    Body:        17 / w400
  //    Callout:     16 / w400
  //    Subhead:     15 / w400
  //    Footnote:    13 / w400
  //    Caption 1:   12 / w400
  //    Caption 2:   11 / w400
  // ═══════════════════════════════════════════════════════════════════
  static TextTheme _buildTextTheme(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkLabelPrimary : AppColors.lightLabelPrimary;
    final secondaryColor = isDark ? AppColors.darkLabelSecondary : AppColors.lightLabelSecondary;
    final tertiaryColor = isDark ? AppColors.darkLabelTertiary : AppColors.lightLabelTertiary;

    return TextTheme(
      // Large Title
      displayLarge: GoogleFonts.inter(fontSize: 34, fontWeight: FontWeight.w700, color: primaryColor, letterSpacing: -0.4),
      // Title 1
      displayMedium: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700, color: primaryColor, letterSpacing: -0.4),
      // Title 2
      displaySmall: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: primaryColor, letterSpacing: -0.4),
      // Title 3
      headlineLarge: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w600, color: primaryColor, letterSpacing: -0.4),
      // Headline
      headlineMedium: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: primaryColor, letterSpacing: -0.4),
      // Subhead
      headlineSmall: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600, color: primaryColor, letterSpacing: -0.4),
      // Title Large (Headline in body)
      titleLarge: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: primaryColor, letterSpacing: -0.4),
      // Title Medium (Callout bold)
      titleMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: primaryColor),
      // Title Small
      titleSmall: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: primaryColor),
      // Body
      bodyLarge: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w400, color: primaryColor),
      // Callout
      bodyMedium: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w400, color: primaryColor),
      // Footnote
      bodySmall: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400, color: secondaryColor),
      // Label Large (Subhead semibold)
      labelLarge: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: primaryColor),
      // Caption 1
      labelMedium: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: secondaryColor),
      // Caption 2
      labelSmall: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w400, color: tertiaryColor),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  COMPONENT BUILDERS
  // ═══════════════════════════════════════════════════════════════════

  static AppBarTheme _buildAppBarTheme(ColorScheme cs) => AppBarTheme(
    backgroundColor: cs.surface,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    centerTitle: false,
    titleTextStyle: GoogleFonts.inter(
      color: cs.onSurface,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.4,
    ),
    iconTheme: IconThemeData(color: cs.onSurface),
  );

  /// Cards: Borderless with subtle shadow
  static CardThemeData _buildCardTheme(ColorScheme cs) => CardThemeData(
    color: cs.surface,
    elevation: 0,
    shadowColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      // No border — Apple HIG uses shadow separation
    ),
    margin: const EdgeInsets.all(0),
  );

  /// Primary button: Filled with primary color
  static ElevatedButtonThemeData _buildElevatedButtonTheme(ColorScheme cs) =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          minimumSize: const Size(120, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      );

  /// Outlined button: Subtle border, no fill
  static OutlinedButtonThemeData _buildOutlinedButtonTheme(ColorScheme cs) =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cs.primary,
          minimumSize: const Size(120, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          side: BorderSide(color: cs.primary.withValues(alpha: 0.3), width: 1),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      );

  /// Text button: Ghost style
  static TextButtonThemeData _buildTextButtonTheme(ColorScheme cs) =>
      TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: cs.primary,
          minimumSize: const Size(80, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      );

  /// Input fields: Borderless, filled
  static InputDecorationTheme _buildInputDecorationTheme(ColorScheme cs) {
    final bool isDark = cs.brightness == Brightness.dark;
    final fillColor = isDark ? AppColors.darkFill : AppColors.lightFill;

    return InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.error, width: 2),
      ),
      hintStyle: GoogleFonts.inter(
        color: isDark ? AppColors.darkLabelTertiary : AppColors.lightLabelTertiary,
        fontSize: 15,
      ),
      labelStyle: GoogleFonts.inter(
        color: isDark ? AppColors.darkLabelSecondary : AppColors.lightLabelSecondary,
        fontSize: 15,
      ),
    );
  }

  /// Dialogs: Rounded with no surface tint
  static DialogThemeData _buildDialogTheme(ColorScheme cs) => DialogThemeData(
    backgroundColor: cs.surface,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    titleTextStyle: GoogleFonts.inter(
      color: cs.onSurface,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.4,
    ),
    contentTextStyle: GoogleFonts.inter(
      color: cs.onSurface,
      fontSize: 15,
    ),
  );

  static ChipThemeData _buildChipTheme(ColorScheme cs) {
    final bool isDark = cs.brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkFill : AppColors.lightFill;

    return ChipThemeData(
      backgroundColor: bgColor,
      selectedColor: cs.primaryContainer,
      disabledColor: bgColor,
      labelStyle: GoogleFonts.inter(
        color: cs.onSurface,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide.none,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    );
  }

  static FloatingActionButtonThemeData _buildFabTheme(ColorScheme cs) =>
      FloatingActionButtonThemeData(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      );
}
