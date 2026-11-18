import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sheetBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            bool isBusy = false;
            return Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.md,
                right: AppSpacing.md,
                top: AppSpacing.md,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final chipBg = isDark ? AppColors.darkSurfaceElevated : AppColors.lightSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

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
              color: borderColor,
              borderRadius: AppRadius.pill,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Title Row
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accentWarning.withOpacity(0.12),
                borderRadius: AppRadius.sm,
                border: Border.all(color: AppColors.accentWarning.withOpacity(0.3)),
              ),
              child: const Icon(Icons.security_rounded, color: AppColors.accentWarning, size: 22),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SECURITY AUTHORIZATION REQUIRED',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentWarning,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Explicit user confirmation is mandatory before executing high-leverage operations.',
                    style: TextStyle(fontSize: 11.5, color: textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.md),

        // Objective summary
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: chipBg,
            borderRadius: AppRadius.card,
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'OBJECTIVE',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: textMuted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                plan.objective,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // Items requiring authorization
        const Text(
          'PENDING OPERATIONS FOR APPROVAL:',
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: AppColors.tessTeal,
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: chipBg,
              borderRadius: AppRadius.card,
              border: Border.all(color: AppColors.accentWarning.withOpacity(0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Step #${step.stepOrder}: ${step.actionDisplayName}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accentWarning.withOpacity(0.15),
                        borderRadius: AppRadius.xs,
                      ),
                      child: Text(
                        step.riskLevel,
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentWarning,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  step.confirmation?.displaySummary ?? 'Action details',
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (fp != null) ...[
                      Text(
                        'fp:$fp',
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: AppColors.tessTeal,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      'Expires in: $expStr',
                      style: TextStyle(
                        fontSize: 9.5,
                        color: textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: AppSpacing.md),

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
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TessButton(
                label: 'Approve Actions',
                variant: TessButtonVariant.primary,
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
