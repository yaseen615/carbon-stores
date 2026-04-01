import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum BadgeType { success, error, info, warning }

/// Colored status badge for paid/debt/wallet/warning states
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
        icon = Icons.check_circle_rounded;

  const StatusBadge.debt({super.key, required this.label, this.fontSize = 12})
      : type = BadgeType.error,
        icon = Icons.warning_rounded;

  const StatusBadge.wallet({super.key, required this.label, this.fontSize = 12})
      : type = BadgeType.info,
        icon = Icons.account_balance_wallet_rounded;

  const StatusBadge.lowStock({super.key, this.label = 'Low Stock', this.fontSize = 12})
      : type = BadgeType.warning,
        icon = Icons.inventory_2_rounded;

  const StatusBadge.outOfStock({super.key, this.label = 'Out of Stock', this.fontSize = 12})
      : type = BadgeType.error,
        icon = Icons.remove_shopping_cart_rounded;

  Color get _backgroundColor {
    switch (type) {
      case BadgeType.success:
        return AppColors.successContainer;
      case BadgeType.error:
        return AppColors.errorContainer;
      case BadgeType.info:
        return AppColors.infoContainer;
      case BadgeType.warning:
        return AppColors.warningContainer;
    }
  }

  Color get _foregroundColor {
    switch (type) {
      case BadgeType.success:
        return AppColors.successLight;
      case BadgeType.error:
        return AppColors.errorLight;
      case BadgeType.info:
        return AppColors.infoLight;
      case BadgeType.warning:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: _foregroundColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: _foregroundColor,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
