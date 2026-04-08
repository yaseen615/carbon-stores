import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Apple HIG-inspired button system with tap scale animation.
/// Variants: filled, tinted, ghost, destructive
enum AppButtonVariant { filled, tinted, ghost, destructive }
enum AppButtonSize { small, medium, large }

class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool expand;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.filled,
    this.size = AppButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.expand = false,
  });

  /// Primary CTA (Pay, Confirm)
  const AppButton.filled({
    super.key,
    required this.label,
    this.onPressed,
    this.size = AppButtonSize.large,
    this.icon,
    this.isLoading = false,
    this.expand = true,
  }) : variant = AppButtonVariant.filled;

  /// Secondary action (Recharge, Add)
  const AppButton.tinted({
    super.key,
    required this.label,
    this.onPressed,
    this.size = AppButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.expand = false,
  }) : variant = AppButtonVariant.tinted;

  /// Tertiary (Cancel, Back)
  const AppButton.ghost({
    super.key,
    required this.label,
    this.onPressed,
    this.size = AppButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.expand = false,
  }) : variant = AppButtonVariant.ghost;

  /// Destructive (Delete, Void)
  const AppButton.destructive({
    super.key,
    required this.label,
    this.onPressed,
    this.size = AppButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.expand = false,
  }) : variant = AppButtonVariant.destructive;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
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

  double get _height {
    switch (widget.size) {
      case AppButtonSize.small:
        return 36.0;
      case AppButtonSize.medium:
        return 44.0;
      case AppButtonSize.large:
        return 50.0;
    }
  }

  double get _fontSize {
    switch (widget.size) {
      case AppButtonSize.small:
        return 13.0;
      case AppButtonSize.medium:
        return 15.0;
      case AppButtonSize.large:
        return 16.0;
    }
  }

  double get _iconSize {
    switch (widget.size) {
      case AppButtonSize.small:
        return 16.0;
      case AppButtonSize.medium:
        return 18.0;
      case AppButtonSize.large:
        return 20.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDisabled = widget.onPressed == null;

    Color bgColor;
    Color fgColor;

    switch (widget.variant) {
      case AppButtonVariant.filled:
        bgColor = cs.primary;
        fgColor = cs.onPrimary;
        break;
      case AppButtonVariant.tinted:
        bgColor = cs.primary.withValues(alpha: 0.12);
        fgColor = cs.primary;
        break;
      case AppButtonVariant.ghost:
        bgColor = Colors.transparent;
        fgColor = cs.primary;
        break;
      case AppButtonVariant.destructive:
        bgColor = cs.error;
        fgColor = Colors.white;
        break;
    }

    if (isDisabled) {
      bgColor = bgColor.withValues(alpha: 0.4);
      fgColor = fgColor.withValues(alpha: 0.4);
    }

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: child,
      ),
      child: GestureDetector(
        onTapDown: isDisabled ? null : (_) => _scaleController.forward(),
        onTapUp: isDisabled ? null : (_) => _scaleController.reverse(),
        onTapCancel: isDisabled ? null : () => _scaleController.reverse(),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.isLoading ? null : widget.onPressed,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: _height,
              width: widget.expand ? double.infinity : null,
              padding: EdgeInsets.symmetric(
                horizontal: widget.size == AppButtonSize.small ? 16 : 24,
              ),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.isLoading) ...[
                    SizedBox(
                      width: _iconSize,
                      height: _iconSize,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: fgColor,
                      ),
                    ),
                  ] else ...[
                    if (widget.icon != null) ...[
                      Icon(widget.icon, size: _iconSize, color: fgColor),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.label,
                      style: GoogleFonts.inter(
                        fontSize: _fontSize,
                        fontWeight: FontWeight.w600,
                        color: fgColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
