import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum TessBadgeVariant {
  neutral,
  success,
  warning,
  danger,
  info,
  mint,
}

/// A compact, semantic pill badge for status, categories, and horizons.
class TessBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final TessBadgeVariant variant;
  final Color? customColor;

  const TessBadge({
    super.key,
    required this.label,
    this.icon,
    this.variant = TessBadgeVariant.neutral,
    this.customColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color color;
    if (customColor != null) {
      color = customColor!;
    } else {
      switch (variant) {
        case TessBadgeVariant.success:
        case TessBadgeVariant.mint:
          color = AppColors.vibrantMint;
          break;
        case TessBadgeVariant.warning:
          color = AppColors.warning;
          break;
        case TessBadgeVariant.danger:
          color = AppColors.danger;
          break;
        case TessBadgeVariant.info:
          color = AppColors.tessTeal;
          break;
        case TessBadgeVariant.neutral:
          color = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.35 : 0.22),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
