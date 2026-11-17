import 'package:flutter/material.dart';
import '../../../core/models/task_model.dart';
import '../../../core/theme/app_colors.dart';

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
        return AppColors.danger;
      case TaskPriority.medium:
        return AppColors.warning;
      case TaskPriority.low:
        return AppColors.cyan;
    }
  }

  String get priorityText => priority.code;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isCompleted
              ? AppColors.border
              : priorityColor.withOpacity(0.25),
        ),
      ),
      child: Row(
        children: [
          Transform.scale(
            scale: 0.9,
            child: Checkbox(
              value: isCompleted,
              activeColor: AppColors.violet,
              checkColor: Colors.white,
              side: const BorderSide(color: AppColors.textMuted),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
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
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isCompleted
                        ? AppColors.textMuted
                        : AppColors.textPrimary,
                    decoration: isCompleted
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  category,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: priorityColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: priorityColor.withOpacity(0.3)),
            ),
            child: Text(
              priorityText,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: priorityColor,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

