import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/tess_card.dart';
import '../models/agent_plan_model.dart';

/// ExecutionHistoryView: Historical log of generated plans, approved actions, and execution results.
class ExecutionHistoryView extends StatelessWidget {
  final List<AgentPlanModel> plans;
  final Function(AgentPlanModel) onSelectPlan;

  const ExecutionHistoryView({
    super.key,
    required this.plans,
    required this.onSelectPlan,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'SUCCESS':
        return AppColors.accentSuccess;
      case 'EXECUTING':
        return AppColors.tessTeal;
      case 'FAILED':
        return AppColors.accentDanger;
      case 'CANCELLED':
        return AppColors.textMuted;
      case 'READY':
      default:
        return AppColors.tessTeal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final chipBg = isDark ? AppColors.darkSurfaceElevated : AppColors.lightSecondary;

    if (plans.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history_toggle_off_rounded, size: 48, color: textMuted.withOpacity(0.5)),
              const SizedBox(height: 12),
              Text(
                'No Agent History',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Plans generated through the objective composer will be preserved here with complete audit trails.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: textMuted),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: plans.length,
      itemBuilder: (context, index) {
        final plan = plans[index];
        final statusColor = _getStatusColor(plan.status);

        return Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: InkWell(
            onTap: () => onSelectPlan(plan),
            borderRadius: AppRadius.card,
            child: TessCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: AppRadius.xs,
                          border: Border.all(color: statusColor.withOpacity(0.35)),
                        ),
                        child: Text(
                          plan.status,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '${plan.totalSteps} Step(s)',
                        style: TextStyle(
                          fontSize: 11,
                          color: textMuted,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        plan.formattedDate,
                        style: TextStyle(
                          fontSize: 11,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    plan.objective,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ...plan.steps.take(3).map((step) {
                        return Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: chipBg,
                            borderRadius: AppRadius.xs,
                          ),
                          child: Text(
                            step.toolName.split('_').first.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppColors.tessTeal,
                            ),
                          ),
                        );
                      }),
                      if (plan.steps.length > 3)
                        Text(
                          '+${plan.steps.length - 3} more',
                          style: TextStyle(fontSize: 10, color: textMuted),
                        ),
                      const Spacer(),
                      Icon(Icons.chevron_right_rounded, size: 18, color: textMuted),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
