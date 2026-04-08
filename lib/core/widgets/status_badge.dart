import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/pos_colors.dart';

enum BadgeType { success, error, info, warning }

/// Apple HIG-inspired pill-shaped status badge.
/// Uses opacity-based backgrounds for visual calmness.
class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeType type;
  final IconData? icon;
  final double fontSize;

  const StatusBadge({
    super.key,
    required this.label,
    required this.type,
    this.icon,
    this.fontSize = 12,
  });

  // Convenience constructors
  const StatusBadge.paid({super.key, this.label = 'Paid', this.fontSize = 12})
      : type = BadgeType.success,
        icon = null;

  const StatusBadge.debt({super.key, required this.label, this.fontSize = 12})
      : type = BadgeType.error,
        icon = null;

  const StatusBadge.wallet({super.key, required this.label, this.fontSize = 12})
      : type = BadgeType.info,
        icon = null;

  const StatusBadge.lowStock({super.key, this.label = 'Low Stock', this.fontSize = 12})
      : type = BadgeType.warning,
        icon = null;

  const StatusBadge.outOfStock({super.key, this.label = 'Out of Stock', this.fontSize = 12})
      : type = BadgeType.error,
        icon = null;

  Color _backgroundColor(POSColors pos) {
    switch (type) {
      case BadgeType.success:
        return pos.success.withValues(alpha: 0.12);
      case BadgeType.error:
        return pos.error.withValues(alpha: 0.12);
      case BadgeType.info:
        return pos.info.withValues(alpha: 0.12);
      case BadgeType.warning:
        return pos.warning.withValues(alpha: 0.12);
    }
  }

  Color _foregroundColor(POSColors pos) {
    switch (type) {
      case BadgeType.success:
        return pos.success;
      case BadgeType.error:
        return pos.error;
      case BadgeType.info:
        return pos.info;
      case BadgeType.warning:
        return pos.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pos = context.pos;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _backgroundColor(pos),
        borderRadius: BorderRadius.circular(999), // Full pill
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: _foregroundColor(pos)),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.inter(
              color: _foregroundColor(pos),
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
