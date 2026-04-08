import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Full-screen loading overlay with blur effect — Apple HIG style.
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Stack(
      children: [
        child,
        if (isLoading)
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: Colors.black.withValues(alpha: 0.2),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 32,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 36,
                        height: 36,
                        child: CircularProgressIndicator(
                          color: cs.primary,
                          strokeWidth: 2.5,
                        ),
                      ),
                      if (message != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          message!,
                          style: GoogleFonts.inter(
                            color: cs.onSurface,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
