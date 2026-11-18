import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/tess_card.dart';
import '../models/agent_step_model.dart';

/// StepReviewCard: Detailed inspectable card for each atomic action step.
class StepReviewCard extends StatelessWidget {
  final AgentStepModel step;

  const StepReviewCard({super.key, required this.step});

  Color _getRiskColor() {
    switch (step.riskLevel) {
      case 'HIGH':
        return AppColors.accentDanger;
      case 'MEDIUM':
        return AppColors.accentWarning;
      case 'LOW':
      default:
        return AppColors.accentSuccess;
    }
  }

  Color _getStatusColor() {
    switch (step.status) {
      case 'SUCCESS':
        return AppColors.accentSuccess;
      case 'RUNNING':
        return AppColors.tessTeal;
      case 'FAILED':
        return AppColors.accentDanger;
      case 'PENDING':
      default:
        return AppColors.tessTeal;
    }
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

    final riskColor = _getRiskColor();
    final statusColor = _getStatusColor();
    final safeParams = step.safeParameters;

    return TessCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderColor: riskColor.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Header
          Row(
            children: [
              // Step Order Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.tessTeal.withOpacity(0.12),
                  borderRadius: AppRadius.xs,
                  border: Border.all(color: AppColors.tessTeal.withOpacity(0.35)),
                ),
                child: Text(
                  '#${step.stepOrder}',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.tessTeal,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),

              // Action Display Name
              Expanded(
                child: Text(
                  step.actionDisplayName,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
              ),

              // Risk Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: riskColor.withOpacity(0.12),
                  borderRadius: AppRadius.xs,
                  border: Border.all(color: riskColor.withOpacity(0.35)),
                ),
                child: Text(
                  '${step.riskLevel} RISK',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: riskColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Target Resource & Tool name
          Row(
            children: [
              const Icon(Icons.hub_outlined, size: 14, color: AppColors.tessTeal),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Target: ${step.targetResource}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.tessTeal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: AppRadius.xs,
                ),
                child: Text(
                  step.status,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Safe Parameter Inspection Box
          if (safeParams.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: chipBg,
                borderRadius: AppRadius.sm,
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PARAMETERS (AUDITED)',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...safeParams.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '• ${entry.key}: ',
                            style: TextStyle(
                              fontSize: 11,
                              color: textSecondary,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              entry.value.toString(),
                              style: TextStyle(
                                fontSize: 11,
                                color: textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Confirmation Requirement Banner
          if (step.requiresConfirmation) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (step.isConfirmed ? AppColors.accentSuccess : AppColors.accentWarning).withOpacity(0.08),
                borderRadius: AppRadius.sm,
                border: Border.all(
                  color: (step.isConfirmed ? AppColors.accentSuccess : AppColors.accentWarning).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    step.isConfirmed ? Icons.verified_user_rounded : Icons.gavel_rounded,
                    size: 16,
                    color: step.isConfirmed ? AppColors.accentSuccess : AppColors.accentWarning,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.isConfirmed
                              ? 'CONFIRMED: Execution Authorized'
                              : (step.confirmation?.isExpired == true
                                  ? 'CONFIRMATION EXPIRED'
                                  : 'AUTHORIZATION REQUIRED'),
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: step.isConfirmed
                                ? AppColors.accentSuccess
                                : (step.confirmation?.isExpired == true ? AppColors.accentDanger : AppColors.accentWarning),
                          ),
                        ),
                        if (step.confirmation != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            step.confirmation!.displaySummary,
                            style: TextStyle(fontSize: 10.5, color: textMuted),
                          ),
                          if (step.confirmation!.fingerprint != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Fingerprint: [fp:${step.confirmation!.fingerprint}]',
                              style: const TextStyle(
                                fontSize: 9.5,
                                color: AppColors.tessTeal,
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const Row(
              children: [
                Icon(Icons.shield_outlined, size: 14, color: AppColors.accentSuccess),
                SizedBox(width: 6),
                Text(
                  'Low risk operation: Pre-authorized by policy',
                  style: TextStyle(fontSize: 11, color: AppColors.accentSuccess),
                ),
              ],
            ),
          ],

          // Execution Result / Error Display
          if (step.result != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (step.status == 'SUCCESS' ? AppColors.accentSuccess : AppColors.accentDanger).withOpacity(0.08),
                borderRadius: AppRadius.sm,
                border: Border.all(
                  color: (step.status == 'SUCCESS' ? AppColors.accentSuccess : AppColors.accentDanger).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    step.status == 'SUCCESS' ? Icons.check_circle_outline : Icons.error_outline,
                    size: 14,
                    color: step.status == 'SUCCESS' ? AppColors.accentSuccess : AppColors.accentDanger,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Result: ${step.result.toString()}',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: step.status == 'SUCCESS' ? AppColors.accentSuccess : AppColors.accentDanger,
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
