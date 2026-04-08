import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'features/splash/splash_screen.dart';
import 'providers/theme_provider.dart';

class CarbonGurukulamStoreApp extends ConsumerWidget {
  const CarbonGurukulamStoreApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      // Smooth animation when switching themes
      themeAnimationDuration: const Duration(milliseconds: 350),
      themeAnimationCurve: Curves.easeInOut,
      home: const SplashScreen(),
    );
  }
}
