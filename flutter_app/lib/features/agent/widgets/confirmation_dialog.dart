import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/tess_button.dart';
import '../models/agent_plan_model.dart';

/// ConfirmationDialog: Explicit authorization sheet before approving consequential operations.
class ConfirmationDialog extends StatelessWidget {
  final AgentPlanModel plan;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final bool isSubmitting;

  const ConfirmationDialog({
    super.key,
    required this.plan,
    required this.onApprove,
    required this.onReject,
    this.isSubmitting = false,
  });

  static Future<bool?> show(
    BuildContext context, {
    required AgentPlanModel plan,
    required Future<void> Function() onApprove,
    required Future<void> Function() onReject,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            bool isBusy = false;
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: ConfirmationDialog(
                plan: plan,
                isSubmitting: isBusy,
                onApprove: () async {
                  setModalState(() => isBusy = true);
                  await onApprove();
                  if (ctx.mounted) Navigator.pop(ctx, true);
                },
                onReject: () async {
                  setModalState(() => isBusy = true);
                  await onReject();
                  if (ctx.mounted) Navigator.pop(ctx, false);
                },
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingSteps = plan.steps.where((s) => s.isPendingConfirmation).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Modal Handle
        Center(
          child: Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Title Row
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.security_rounded, color: AppColors.warning, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SECURITY AUTHORIZATION REQUIRED',
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      color: AppColors.warning,
                      letterSpacing: 1.0,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Explicit user confirmation is mandatory before executing high-leverage operations.',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Objective summary
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.bgSecondary,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'OBJECTIVE',
                style: TextStyle(
                  fontSize: 9,
                  fontFamily: 'monospace',
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                plan.objective,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Items requiring authorization
        const Text(
          'PENDING OPERATIONS FOR APPROVAL:',
          style: TextStyle(
            fontSize: 10,
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            color: AppColors.cyan,
          ),
        ),
        const SizedBox(height: 8),

        ...pendingSteps.map((step) {
          final fp = step.confirmation?.fingerprint;
          final exp = step.confirmation?.expiresAt;
          String expStr = '15 minutes';
          if (exp != null) {
            final diff = exp.difference(DateTime.now().toUtc());
            expStr = '${diff.inMinutes.clamp(0, 15)}m remaining';
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.bgSecondary.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Step #${step.stepOrder}: ${step.actionDisplayName}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        step.riskLevel,
                        style: const TextStyle(
                          fontSize: 9,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  step.confirmation?.displaySummary ?? 'Action details',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (fp != null) ...[
                      Text(
                        'fp:$fp',
                        style: const TextStyle(
                          fontSize: 9,
                          fontFamily: 'monospace',
                          color: AppColors.cyan,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      'Expires in: $expStr',
                      style: const TextStyle(
                        fontSize: 9,
                        fontFamily: 'monospace',
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 16),

        // Action Buttons
        Row(
          children: [
            Expanded(
              child: TessButton(
                label: 'Reject / Cancel',
                variant: TessButtonVariant.secondary,
                onPressed: isSubmitting ? null : onReject,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TessButton(
                label: 'Approve Actions',
                variant: TessButtonVariant.cyan,
                icon: Icons.check_circle_outline,
                onPressed: isSubmitting ? null : onApprove,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
