import 'package:flutter/material.dart';
import '../theme/wardrobe_theme.dart';

/// Filter chip for Wardrobe categories.
class CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  const CategoryChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? WardrobeTheme.electricViolet.withValues(alpha: 0.22)
              : WardrobeTheme.spatialSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? WardrobeTheme.electricViolet : WardrobeTheme.border,
            width: 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: WardrobeTheme.electricViolet.withValues(alpha: 0.30),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected
                    ? WardrobeTheme.softViolet
                    : WardrobeTheme.textMuted,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? WardrobeTheme.textPrimary
                    : WardrobeTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
