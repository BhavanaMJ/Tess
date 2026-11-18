import 'package:flutter/material.dart';
import '../../../core/models/task_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';

class TaskTile extends StatelessWidget {
  final String title;
  final String category;
  final TaskPriority priority;
  final bool isCompleted;
  final ValueChanged<bool?>? onToggle;

  const TaskTile({
    super.key,
    required this.title,
    required this.category,
    this.priority = TaskPriority.medium,
    this.isCompleted = false,
    this.onToggle,
  });

  Color get priorityColor {
    switch (priority) {
      case TaskPriority.high:
        return AppColors.accentDanger;
      case TaskPriority.medium:
        return AppColors.accentWarning;
      case TaskPriority.low:
        return AppColors.tessTeal;
    }
  }

  String get priorityText => priority.code;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: AppRadius.card,
        border: Border.all(
          color: isCompleted
              ? borderColor
              : priorityColor.withOpacity(0.25),
        ),
      ),
      child: Row(
        children: [
          Transform.scale(
            scale: 0.95,
            child: Checkbox(
              value: isCompleted,
              activeColor: AppColors.tessTeal,
              checkColor: Colors.white,
              side: BorderSide(color: textMuted),
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadius.xs,
              ),
              onChanged: onToggle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: isCompleted
                        ? textMuted
                        : textPrimary,
                    decoration: isCompleted
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  category,
                  style: TextStyle(
                    fontSize: 11,
                    color: textMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: priorityColor.withOpacity(0.12),
              borderRadius: AppRadius.pill,
              border: Border.all(color: priorityColor.withOpacity(0.3)),
            ),
            child: Text(
              priorityText,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: priorityColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
