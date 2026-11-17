import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/tess_button.dart';
import '../../../shared/widgets/tess_card.dart';
import '../models/agent_plan_model.dart';
import 'step_review_card.dart';

/// PlanReviewCard: Main interface for inspecting an Agent Plan and controlling its lifecycle.
class PlanReviewCard extends StatelessWidget {
  final AgentPlanModel plan;
  final VoidCallback onConfirm;
  final VoidCallback onExecute;
  final VoidCallback onCancel;
  final bool isSubmitting;

  const PlanReviewCard({
    super.key,
    required this.plan,
    required this.onConfirm,
    required this.onExecute,
    required this.onCancel,
    this.isSubmitting = false,
  });

  Color _getStatusColor() {
    switch (plan.status) {
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
    final statusColor = _getStatusColor();

    return TessCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Plan Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  plan.status,
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${plan.totalSteps} STEP(S)',
                style: const TextStyle(
                  fontSize: 11,
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

          const SizedBox(height: 12),

          // Objective Headline
          Text(
            plan.objective,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 14),

          // Plan Steps Section
          const Text(
            'SEQUENTIAL EXECUTION STEPS',
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              color: AppColors.cyan,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),

          if (plan.steps.isEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'No steps generated for this plan.',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ),
          ] else ...[
            ...plan.steps.map((step) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: StepReviewCard(step: step),
                )),
          ],

          const SizedBox(height: 12),

          // Lifecycle Control Levers
          if (!plan.isTerminal) ...[
            // Status helper notice
            if (plan.hasPendingConfirmation) ...[
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_clock_rounded, size: 16, color: AppColors.warning),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This plan includes operations requiring explicit user authorization. Review steps above and confirm before execution.',
                        style: TextStyle(fontSize: 11, color: AppColors.warning),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Action Buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (plan.hasPendingConfirmation)
                  TessButton(
                    label: 'Approve & Confirm',
                    icon: Icons.check_circle_outline,
                    variant: TessButtonVariant.cyan,
                    onPressed: isSubmitting ? null : onConfirm,
                  ),
                if (plan.isExecutable)
                  TessButton(
                    label: isSubmitting ? 'Executing Operations...' : 'Execute Approved Plan',
                    icon: Icons.play_arrow_rounded,
                    variant: TessButtonVariant.primary,
                    onPressed: isSubmitting ? null : onExecute,
                  ),
                TessButton(
                  label: 'Cancel Plan',
                  icon: Icons.close_rounded,
                  variant: TessButtonVariant.secondary,
                  onPressed: isSubmitting ? null : onCancel,
                ),
              ],
            ),
          ] else ...[
            // Terminal Status Badge / Replay Prevention Notice
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    plan.isSuccess
                        ? Icons.verified_rounded
                        : (plan.isCancelled ? Icons.cancel_outlined : Icons.error_outline),
                    size: 16,
                    color: statusColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      plan.isSuccess
                          ? 'Plan completed successfully. Replay protection active: Tokens invalidated.'
                          : (plan.isCancelled
                              ? 'Plan was cancelled by user. No further actions permitted.'
                              : 'Plan execution encountered an error.'),
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
