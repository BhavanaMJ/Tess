import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/memory_model.dart';

/// Holographic Memory Card displaying a saved personal context entity
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
        return AppColors.violetLight;
      case 'PERSONAL':
        return AppColors.cyan;
      case 'PREFERENCE':
        return AppColors.amber;
      case 'HEALTH':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final catColor = _categoryColor;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: catColor.withOpacity(0.3),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: catColor.withOpacity(0.04),
            blurRadius: 10.0,
            spreadRadius: 1.0,
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
                  color: catColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6.0),
                  border: Border.all(color: catColor.withOpacity(0.5)),
                ),
                child: Text(
                  memory.category,
                  style: TextStyle(
                    color: catColor,
                    fontSize: 10.0,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              // Importance Stars
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  final filled = index < memory.importance;
                  return Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 14.0,
                    color: filled ? AppColors.amber : AppColors.textMuted.withOpacity(0.3),
                  );
                }),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 18.0),
                color: AppColors.textMuted,
                splashRadius: 18.0,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Purge Memory',
                onPressed: () => _confirmDelete(context),
              ),
            ],
          ),
          const SizedBox(height: 10.0),
          // Content
          SelectableText(
            memory.content,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10.0),
          // Footer: Provenance & Date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PROVENANCE: ${memory.provenance}',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10.0,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                memory.formattedDate,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10.0,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
          side: const BorderSide(color: AppColors.border),
        ),
        title: const Text(
          'Purge Memory Entity?',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 16.0),
        ),
        content: const Text(
          'This will permanently remove this context entity from TESS continuous memory bank.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13.0),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              onDelete();
            },
            child: const Text('Purge'),
          ),
        ],
      ),
    );
  }
}
