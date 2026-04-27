import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Premium Apple-style full-screen overlay that blocks the app when offline.
/// Monitors connectivity changes and shows/hides automatically.
class ConnectivityOverlay extends StatefulWidget {
  final Widget child;

  const ConnectivityOverlay({super.key, required this.child});

  @override
  State<ConnectivityOverlay> createState() => _ConnectivityOverlayState();
}

class _ConnectivityOverlayState extends State<ConnectivityOverlay>
    with SingleTickerProviderStateMixin {
  late final StreamSubscription<List<ConnectivityResult>> _subscription;
  late final AnimationController _pulseController;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // Check initial state
    Connectivity().checkConnectivity().then((results) {
      if (mounted) {
        setState(() {
          _isOffline = results.contains(ConnectivityResult.none);
        });
      }
    });

    // Listen to changes
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      if (mounted) {
        setState(() {
          _isOffline = results.contains(ConnectivityResult.none);
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isOffline)
          _NoInternetOverlay(pulseController: _pulseController),
      ],
    );
  }
}

class _NoInternetOverlay extends StatelessWidget {
  final AnimationController pulseController;

  const _NoInternetOverlay({required this.pulseController});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);

    return Material(
      type: MaterialType.transparency,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: size.width,
          height: size.height,
          color: isDark
              ? const Color(0xFF000000).withValues(alpha: 0.85)
              : const Color(0xFFFFFFFF).withValues(alpha: 0.88),
          child: Center(
            child: _OfflineCard(
              isDark: isDark,
              pulseController: pulseController,
            ),
          ),
        ),
      ),
    );
  }
}

class _OfflineCard extends StatelessWidget {
  final bool isDark;
  final AnimationController pulseController;

  const _OfflineCard({
    required this.isDark,
    required this.pulseController,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1C1C1E);
    final textSecondary =
        isDark ? Colors.white.withValues(alpha: 0.6) : const Color(0xFF8E8E93);
    final accentRed = const Color(0xFFFF3B30);

    return Container(
      width: 360,
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 44),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.12),
            blurRadius: 60,
            offset: const Offset(0, 20),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: isDark
            ? Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 0.5,
              )
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pulsing icon container
          AnimatedBuilder(
            animation: pulseController,
            builder: (context, child) {
              final scale = 1.0 + (pulseController.value * 0.06);
              final glowOpacity = 0.08 + (pulseController.value * 0.12);
              return Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentRed.withValues(alpha: 0.1),
                  boxShadow: [
                    BoxShadow(
                      color: accentRed.withValues(alpha: glowOpacity),
                      blurRadius: 30,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Transform.scale(
                  scale: scale,
                  child: Icon(
                    Icons.wifi_off_rounded,
                    size: 40,
                    color: accentRed,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 28),

          // Title
          Text(
            'No Connection',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: textPrimary,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),

          const SizedBox(height: 12),

          // Description
          Text(
            'Please check your internet connection.\nThe app requires a network to function.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              height: 1.5,
              color: textSecondary,
              fontWeight: FontWeight.w400,
            ),
          ),

          const SizedBox(height: 32),

          // Status indicator
          AnimatedBuilder(
            animation: pulseController,
            builder: (context, _) {
              final dotOpacity = 0.4 + (pulseController.value * 0.6);
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accentRed.withValues(alpha: dotOpacity),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Waiting for connection…',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
