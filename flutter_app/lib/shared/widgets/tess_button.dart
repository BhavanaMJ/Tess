import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum TessButtonVariant { primary, secondary, cyan }

/// Reusable futuristic styled action button
class TessButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final TessButtonVariant variant;

  const TessButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = TessButtonVariant.primary,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    BorderSide borderSide = BorderSide.none;

    switch (variant) {
      case TessButtonVariant.primary:
        bg = AppColors.violet;
        fg = Colors.white;
        break;
      case TessButtonVariant.cyan:
        bg = AppColors.cyan;
        fg = Colors.black;
        break;
      case TessButtonVariant.secondary:
        bg = const Color(0x0FFFFFFF);
        fg = AppColors.textSecondary;
        borderSide = const BorderSide(color: AppColors.border);
        break;
    }

    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: bg,
      foregroundColor: fg,
      side: borderSide,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
    );

    if (icon != null) {
      return ElevatedButton.icon(
        style: buttonStyle,
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      );
    }

    return ElevatedButton(
      style: buttonStyle,
      onPressed: onPressed,
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }
}

