import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/responsive_metric_card.dart';
import '../models/dashboard_model.dart';

/// ProductivityOverview renders real task intelligence returned from FastAPI backend:
/// GET /api/v1/productivity/summary
class ProductivityOverview extends StatelessWidget {
  final ProductivitySummaryModel summary;

  const ProductivityOverview({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.bolt, color: AppColors.cyan, size: 16),
            SizedBox(width: 6),
            Text(
              'REAL-TIME PRODUCTIVITY TELEMETRY',
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                color: AppColors.textMuted,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10.0),

        // Row 1: Active Tasks & Overdue
        Row(
          children: [
            Expanded(
              child: ResponsiveMetricCard(
                title: 'ACTIVE TASKS',
                value: '${summary.totalActive}',
                subtitle: 'Active backlog',
                icon: Icons.task_alt,
                accentColor: AppColors.violet,
              ),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: ResponsiveMetricCard(
                title: 'OVERDUE',
                value: '${summary.overdue}',
                subtitle: summary.hasOverdue ? 'Requires focus' : 'Nominal zero',
                icon: Icons.warning_amber_rounded,
                accentColor: summary.hasOverdue ? AppColors.danger : AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8.0),

        // Row 2: Due Today & Recently Completed
        Row(
          children: [
            Expanded(
              child: ResponsiveMetricCard(
                title: 'DUE TODAY',
                value: '${summary.dueToday}',
                subtitle: 'Immediate horizon',
                icon: Icons.schedule,
                accentColor: AppColors.cyan,
              ),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: ResponsiveMetricCard(
                title: 'COMPLETED',
                value: '${summary.completedRecently}',
                subtitle: 'Recent velocity',
                icon: Icons.check_circle_outline,
                accentColor: AppColors.success,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
