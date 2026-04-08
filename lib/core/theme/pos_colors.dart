import 'package:flutter/material.dart';
import 'app_colors.dart';

/// POS-specific semantic colors that extend beyond Material's ColorScheme.
/// These are added as a ThemeExtension so they adapt to light/dark mode.
/// Uses Apple HIG-inspired muted tones with opacity-based containers.
@immutable
class POSColors extends ThemeExtension<POSColors> {
  final Color successContainer;
  final Color errorContainer;
  final Color infoContainer;
  final Color warningContainer;
  final Color success;
  final Color successLight;
  final Color error;
  final Color errorLight;
  final Color info;
  final Color infoLight;
  final Color warning;
  final Color warningLight;
  final Color divider;
  final Color border;
  final Color fill;
  final Color fillSecondary;
  final Color labelSecondary;
  final Color labelTertiary;

  const POSColors({
    required this.successContainer,
    required this.errorContainer,
    required this.infoContainer,
    required this.warningContainer,
    required this.success,
    required this.successLight,
    required this.error,
    required this.errorLight,
    required this.info,
    required this.infoLight,
    required this.warning,
    required this.warningLight,
    required this.divider,
    required this.border,
    required this.fill,
    required this.fillSecondary,
    required this.labelSecondary,
    required this.labelTertiary,
  });

  // ─── Light Theme POS Colors (Apple HIG) ───
  static const light = POSColors(
    success: AppColors.lightSuccess,
    successLight: Color(0xFF4CD964),
    successContainer: Color(0x1A34C759),    // Green @ 10%
    error: AppColors.lightError,
    errorLight: Color(0xFFFF6961),
    errorContainer: Color(0x1AFF3B30),      // Red @ 10%
    info: AppColors.lightInfo,
    infoLight: Color(0xFF7A78E0),
    infoContainer: Color(0x1A5856D6),       // Indigo @ 10%
    warning: AppColors.lightWarning,
    warningLight: Color(0xFFFFB340),
    warningContainer: Color(0x1AFF9500),    // Orange @ 10%
    divider: AppColors.lightSeparator,
    border: AppColors.lightSeparatorOpaque,
    fill: AppColors.lightFill,
    fillSecondary: AppColors.lightFillSecondary,
    labelSecondary: AppColors.lightLabelSecondary,
    labelTertiary: AppColors.lightLabelTertiary,
  );

  // ─── Dark Theme POS Colors (Apple HIG) ───
  static const dark = POSColors(
    success: AppColors.darkSuccess,
    successLight: Color(0xFF4ADE80),
    successContainer: Color(0x2630D158),    // Green @ 15%
    error: AppColors.darkError,
    errorLight: Color(0xFFFF6B6B),
    errorContainer: Color(0x26FF453A),      // Red @ 15%
    info: AppColors.darkInfo,
    infoLight: Color(0xFF8583F0),
    infoContainer: Color(0x265E5CE6),       // Indigo @ 15%
    warning: AppColors.darkWarning,
    warningLight: Color(0xFFFFB347),
    warningContainer: Color(0x26FF9F0A),    // Orange @ 15%
    divider: AppColors.darkSeparator,
    border: AppColors.darkSeparatorOpaque,
    fill: AppColors.darkFill,
    fillSecondary: AppColors.darkFillSecondary,
    labelSecondary: AppColors.darkLabelSecondary,
    labelTertiary: AppColors.darkLabelTertiary,
  );

  @override
  POSColors copyWith({
    Color? successContainer,
    Color? errorContainer,
    Color? infoContainer,
    Color? warningContainer,
    Color? success,
    Color? successLight,
    Color? error,
    Color? errorLight,
    Color? info,
    Color? infoLight,
    Color? warning,
    Color? warningLight,
    Color? divider,
    Color? border,
    Color? fill,
    Color? fillSecondary,
    Color? labelSecondary,
    Color? labelTertiary,
  }) {
    return POSColors(
      successContainer: successContainer ?? this.successContainer,
      errorContainer: errorContainer ?? this.errorContainer,
      infoContainer: infoContainer ?? this.infoContainer,
      warningContainer: warningContainer ?? this.warningContainer,
      success: success ?? this.success,
      successLight: successLight ?? this.successLight,
      error: error ?? this.error,
      errorLight: errorLight ?? this.errorLight,
      info: info ?? this.info,
      infoLight: infoLight ?? this.infoLight,
      warning: warning ?? this.warning,
      warningLight: warningLight ?? this.warningLight,
      divider: divider ?? this.divider,
      border: border ?? this.border,
      fill: fill ?? this.fill,
      fillSecondary: fillSecondary ?? this.fillSecondary,
      labelSecondary: labelSecondary ?? this.labelSecondary,
      labelTertiary: labelTertiary ?? this.labelTertiary,
    );
  }

  @override
  POSColors lerp(ThemeExtension<POSColors>? other, double t) {
    if (other is! POSColors) return this;
    return POSColors(
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      errorContainer: Color.lerp(errorContainer, other.errorContainer, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      warningContainer: Color.lerp(warningContainer, other.warningContainer, t)!,
      success: Color.lerp(success, other.success, t)!,
      successLight: Color.lerp(successLight, other.successLight, t)!,
      error: Color.lerp(error, other.error, t)!,
      errorLight: Color.lerp(errorLight, other.errorLight, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoLight: Color.lerp(infoLight, other.infoLight, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningLight: Color.lerp(warningLight, other.warningLight, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      border: Color.lerp(border, other.border, t)!,
      fill: Color.lerp(fill, other.fill, t)!,
      fillSecondary: Color.lerp(fillSecondary, other.fillSecondary, t)!,
      labelSecondary: Color.lerp(labelSecondary, other.labelSecondary, t)!,
      labelTertiary: Color.lerp(labelTertiary, other.labelTertiary, t)!,
    );
  }
}

/// Extension on BuildContext to easily access POSColors
extension POSColorsExtension on BuildContext {
  POSColors get pos => Theme.of(this).extension<POSColors>()!;
}
