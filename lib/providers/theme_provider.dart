import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Key used to persist the theme preference
const _kThemePrefKey = 'pos_theme_mode';

/// Provider for the theme notifier
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

/// Manages theme state and persists to SharedPreferences
class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.light) {
    _loadTheme();
  }

  /// Load saved theme preference
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_kThemePrefKey) ?? false; // Default: light
    state = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  /// Toggle between light and dark
  Future<void> toggle() async {
    final newMode = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    state = newMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kThemePrefKey, newMode == ThemeMode.dark);
  }

  /// Check if currently dark
  bool get isDark => state == ThemeMode.dark;
}
