import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/responsive_metric_card.dart';
import '../models/dashboard_model.dart';

/// ProductivityOverview renders real OpenProject task telemetry returned from:
/// GET /api/v1/productivity/summary
class ProductivityOverview extends StatelessWidget {
  final ProductivitySummaryModel summary;

  const ProductivityOverview({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.bolt_rounded, color: AppColors.tessTeal, size: 18),
            const SizedBox(width: 6),
            Text(
              'TODAY\'S PRODUCTIVITY SUMMARY',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
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
                title: 'Active Tasks',
                value: '${summary.totalActive}',
                subtitle: 'Active backlog',
                icon: Icons.task_alt_rounded,
                accentColor: AppColors.tessTeal,
              ),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: ResponsiveMetricCard(
                title: 'Overdue',
                value: '${summary.overdue}',
                subtitle: summary.hasOverdue ? 'Requires focus' : 'Nominal zero',
                icon: Icons.warning_amber_rounded,
                accentColor: summary.hasOverdue ? AppColors.danger : AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8.0),

        // Row 2: Due Today & Completed Recently
        Row(
          children: [
            Expanded(
              child: ResponsiveMetricCard(
                title: 'Due Today',
                value: '${summary.dueToday}',
                subtitle: 'Immediate horizon',
                icon: Icons.calendar_today_rounded,
                accentColor: AppColors.vibrantMint,
              ),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: ResponsiveMetricCard(
                title: 'Completed',
                value: '${summary.completedRecently}',
                subtitle: 'Recent velocity',
                icon: Icons.check_circle_outline_rounded,
                accentColor: AppColors.success,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
