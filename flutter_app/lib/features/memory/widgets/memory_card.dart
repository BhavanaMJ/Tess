import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/memory_model.dart';

/// Memory Card displaying a saved personal context entity
class MemoryCard extends StatelessWidget {
  final MemoryModel memory;
  final VoidCallback onDelete;

  const MemoryCard({
    super.key,
    required this.memory,
    required this.onDelete,
  });

  Color get _categoryColor {
    switch (memory.category.toUpperCase()) {
      case 'WORK':
      case 'PROJECT':
        return AppColors.tessTeal;
      case 'PERSONAL':
        return AppColors.vibrantMint;
      case 'PREFERENCE':
        return AppColors.accentWarning;
      case 'HEALTH':
        return AppColors.accentSuccess;
      default:
        return AppColors.tessTeal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final catColor = _categoryColor;

    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6.0),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: AppRadius.card,
        border: Border.all(
          color: catColor.withOpacity(0.3),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: catColor.withOpacity(0.04),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Category Pill, Importance Indicator, and Delete Action
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                decoration: BoxDecoration(
                  color: catColor.withOpacity(0.12),
                  borderRadius: AppRadius.xs,
                  border: Border.all(color: catColor.withOpacity(0.35)),
                ),
                child: Text(
                  memory.category,
                  style: TextStyle(
                    color: catColor,
                    fontSize: 10.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Importance Stars
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  final filled = index < memory.importance;
                  return Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 15.0,
                    color: filled ? AppColors.accentWarning : textMuted.withOpacity(0.3),
                  );
                }),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 18.0),
                color: textMuted,
                splashRadius: 18.0,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Delete Memory',
                onPressed: () => _confirmDelete(context, isDark),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Content
          SelectableText(
            memory.content,
            style: TextStyle(
              color: textPrimary,
              fontSize: 13.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Footer: Provenance & Date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PROVENANCE: ${memory.provenance}',
                style: TextStyle(
                  color: textMuted,
                  fontSize: 10.0,
                ),
              ),
              Text(
                memory.formattedDate,
                style: TextStyle(
                  color: textMuted,
                  fontSize: 10.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, bool isDark) {
    final dialogBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: dialogBg,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.card,
        ),
        title: Text(
          'Delete Memory?',
          style: TextStyle(color: textPrimary, fontSize: 16.0, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'This will permanently remove this context from TESS personal memory bank.',
          style: TextStyle(color: textSecondary, fontSize: 13.0),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentDanger,
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(borderRadius: AppRadius.pill),
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              onDelete();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
