import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';

enum TessButtonVariant { primary, secondary, outline, destructive, cyan }

/// Reusable polished action button for TESS.
/// Features tactile feedback, proper minimum touch targets, and theme adaptation.
class TessButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final TessButtonVariant variant;
  final bool isLoading;
  final double? width;
  final double height;

  const TessButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = TessButtonVariant.primary,
    this.isLoading = false,
    this.width,
    this.height = 46.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg;
    Color fg;
    BorderSide borderSide = BorderSide.none;

    switch (variant) {
      case TessButtonVariant.primary:
        bg = AppColors.vibrantMint;
        fg = isDark ? Colors.black : Colors.white;
        break;
      case TessButtonVariant.secondary:
        bg = isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle;
        fg = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
        borderSide = BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1.0,
        );
        break;
      case TessButtonVariant.outline:
        bg = Colors.transparent;
        fg = AppColors.tessTeal;
        borderSide = const BorderSide(color: AppColors.tessTeal, width: 1.5);
        break;
      case TessButtonVariant.destructive:
        bg = isDark ? AppColors.danger.withValues(alpha: 0.15) : AppColors.dangerLight;
        fg = AppColors.danger;
        borderSide = BorderSide(color: AppColors.danger.withValues(alpha: 0.3), width: 1.0);
        break;
      case TessButtonVariant.cyan:
        bg = AppColors.tessTeal;
        fg = Colors.white;
        break;
    }

    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: bg,
      foregroundColor: fg,
      disabledBackgroundColor: bg.withValues(alpha: 0.4),
      disabledForegroundColor: fg.withValues(alpha: 0.4),
      elevation: 0,
      shadowColor: Colors.transparent,
      side: borderSide,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.radiusMd,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
    );

    Widget childWidget;
    if (isLoading) {
      childWidget = SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          valueColor: AlwaysStoppedAnimation<Color>(fg),
        ),
      );
    } else if (icon != null) {
      childWidget = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              color: fg,
            ),
          ),
        ],
      );
    } else {
      childWidget = Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
          color: fg,
        ),
      );
    }

    final button = SizedBox(
      height: height,
      child: ElevatedButton(
        style: buttonStyle,
        onPressed: isLoading ? null : onPressed,
        child: childWidget,
      ),
    );

    if (width != null) {
      return SizedBox(width: width, child: button);
    }

    return button;
  }
}
