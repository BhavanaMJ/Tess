import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Reusable futuristic spatial card container
class TessCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;
  final Color? backgroundColor;
  final Gradient? gradient;
  final VoidCallback? onTap;

  const TessCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16.0),
    this.borderColor,
    this.backgroundColor,
    this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final border = Border.all(
      color: borderColor ?? AppColors.border,
      width: 1.0,
    );

    final boxDecoration = BoxDecoration(
      color: gradient == null ? (backgroundColor ?? AppColors.bgSurface) : null,
      gradient: gradient,
      borderRadius: BorderRadius.circular(14.0),
      border: border,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.0),
        child: Container(
          padding: padding,
          decoration: boxDecoration,
          child: child,
        ),
      );
    }

    return Container(
      padding: padding,
      decoration: boxDecoration,
      child: child,
    );
  }
}

