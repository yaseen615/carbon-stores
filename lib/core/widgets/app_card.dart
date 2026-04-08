import 'package:flutter/material.dart';

/// Apple HIG-inspired card with layered shadow system.
/// Replaces Material Card's border-based separation with shadows.
///
/// Shadow levels:
///  0 = flat (no shadow)
///  1 = subtle card (default)
///  2 = raised panel
///  3 = floating/modal
class AppCard extends StatefulWidget {
  final Widget child;
  final EdgeInsets padding;
  final int elevation;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double borderRadius;
  final Color? color;
  final Border? border;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.elevation = 1,
    this.onTap,
    this.onLongPress,
    this.borderRadius = 16,
    this.color,
    this.border,
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  List<BoxShadow> _buildShadow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isDark) {
      // Dark mode: very subtle shadow + slight border glow
      switch (widget.elevation) {
        case 0:
          return [];
        case 1:
          return [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ];
        case 2:
          return [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ];
        case 3:
        default:
          return [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ];
      }
    }

    // Light mode: Apple-style soft shadows
    switch (widget.elevation) {
      case 0:
        return [];
      case 1:
        return [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ];
      case 2:
        return [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ];
      case 3:
      default:
        return [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasInteraction = widget.onTap != null || widget.onLongPress != null;

    final cardColor = widget.color ?? cs.surface;

    // Dark mode cards get a very subtle border for definition
    final darkBorder = isDark && widget.elevation > 0
        ? Border.all(color: Colors.white.withValues(alpha: 0.06), width: 0.5)
        : null;

    final effectiveBorder = widget.border ?? darkBorder;

    Widget card = Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        boxShadow: _buildShadow(context),
        border: effectiveBorder,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Material(
          color: Colors.transparent,
          child: hasInteraction
              ? InkWell(
                  onTap: widget.onTap,
                  onLongPress: widget.onLongPress,
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  child: Padding(
                    padding: widget.padding,
                    child: widget.child,
                  ),
                )
              : Padding(
                  padding: widget.padding,
                  child: widget.child,
                ),
        ),
      ),
    );

    if (!hasInteraction) return card;

    // Tap scale feedback
    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) => _scaleController.reverse(),
      onTapCancel: () => _scaleController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: card,
      ),
    );
  }
}
