import 'dart:ui';
import 'package:flutter/material.dart';

/// iOS-style modal with backdrop blur, scale+fade entry animation.
/// Use [showAppModal] helper function instead of showDialog.
Future<T?> showAppModal<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  double maxWidth = 440,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (context, animation, secondaryAnimation) {
      return _AppModalWrapper(
        animation: animation,
        maxWidth: maxWidth,
        child: builder(context),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return child;
    },
  );
}

class _AppModalWrapper extends StatelessWidget {
  final Animation<double> animation;
  final double maxWidth;
  final Widget child;

  const _AppModalWrapper({
    required this.animation,
    required this.maxWidth,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );

    final scaleAnimation = Tween<double>(begin: 0.92, end: 1.0)
        .animate(curvedAnimation);
    final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(curvedAnimation);
    final blurAnimation = Tween<double>(begin: 0.0, end: 20.0)
        .animate(curvedAnimation);
    final barrierAnimation = Tween<double>(begin: 0.0, end: 0.3)
        .animate(curvedAnimation);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // Blurred + dimmed backdrop
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: blurAnimation.value,
                  sigmaY: blurAnimation.value,
                ),
                child: Container(
                  color: Colors.black.withValues(alpha: barrierAnimation.value),
                ),
              ),
            ),
            // Modal content
            Center(
              child: FadeTransition(
                opacity: fadeAnimation,
                child: ScaleTransition(
                  scale: scaleAnimation,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: Material(
                      color: Colors.transparent,
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Standard modal container with Apple-style header.
/// Wraps modal content with consistent padding, shape, and close button.
class AppModalContent extends StatelessWidget {
  final String title;
  final IconData? titleIcon;
  final List<Widget> children;
  final double maxWidth;
  final EdgeInsets padding;

  const AppModalContent({
    super.key,
    required this.title,
    this.titleIcon,
    required this.children,
    this.maxWidth = 440,
    this.padding = const EdgeInsets.all(24),
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
        border: isDark
            ? Border.all(color: Colors.white.withValues(alpha: 0.08), width: 0.5)
            : null,
      ),
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                if (titleIcon != null) ...[
                  Icon(titleIcon, color: cs.primary, size: 22),
                  const SizedBox(width: 10),
                ],
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                _CloseButton(onTap: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 24),
            // Content
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Apple-style close button (circle with X)
class _CloseButton extends StatefulWidget {
  final VoidCallback onTap;

  const _CloseButton({required this.onTap});

  @override
  State<_CloseButton> createState() => _CloseButtonState();
}

class _CloseButtonState extends State<_CloseButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: _isHovered
                ? cs.onSurfaceVariant.withValues(alpha: 0.15)
                : cs.onSurfaceVariant.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.close_rounded,
            size: 16,
            color: cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
