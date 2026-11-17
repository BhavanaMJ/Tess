import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
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
        return AppColors.success;
      case 'EXECUTING':
        return AppColors.cyan;
      case 'FAILED':
        return AppColors.danger;
      case 'CANCELLED':
        return AppColors.textMuted;
      case 'READY':
      default:
        return AppColors.violet;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (plans.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history_toggle_off_rounded, size: 48, color: AppColors.textMuted.withValues(alpha: 0.5)),
              const SizedBox(height: 12),
              const Text(
                'NO AGENT HISTORY',
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Plans generated through the objective composer will be preserved here with complete audit trails.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
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
            borderRadius: BorderRadius.circular(10),
            child: TessCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          plan.status,
                          style: TextStyle(
                            fontSize: 9,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${plan.totalSteps} Step(s)',
                        style: const TextStyle(
                          fontSize: 10,
                          fontFamily: 'monospace',
                          color: AppColors.textMuted,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        plan.formattedDate,
                        style: const TextStyle(
                          fontSize: 10,
                          fontFamily: 'monospace',
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    plan.objective,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      ...plan.steps.take(3).map((step) {
                        return Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.bgSecondary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            step.toolName.split('_').first.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 8,
                              fontFamily: 'monospace',
                              color: AppColors.cyan,
                            ),
                          ),
                        );
                      }),
                      if (plan.steps.length > 3)
                        Text(
                          '+${plan.steps.length - 3} more',
                          style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
                        ),
                      const Spacer(),
                      const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textMuted),
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
