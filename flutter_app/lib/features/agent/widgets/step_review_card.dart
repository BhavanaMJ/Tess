import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/tess_card.dart';
import '../models/agent_step_model.dart';

/// StepReviewCard: Detailed inspectable card for each atomic action step.
class StepReviewCard extends StatelessWidget {
  final AgentStepModel step;

  const StepReviewCard({super.key, required this.step});

  Color _getRiskColor() {
    switch (step.riskLevel) {
      case 'HIGH':
        return AppColors.danger;
      case 'MEDIUM':
        return AppColors.warning;
      case 'LOW':
      default:
        return AppColors.success;
    }
  }

  Color _getStatusColor() {
    switch (step.status) {
      case 'SUCCESS':
        return AppColors.success;
      case 'RUNNING':
        return AppColors.cyan;
      case 'FAILED':
        return AppColors.danger;
      case 'PENDING':
      default:
        return AppColors.violet;
    }
  }

  @override
  Widget build(BuildContext context) {
    final riskColor = _getRiskColor();
    final statusColor = _getStatusColor();
    final safeParams = step.safeParameters;

    return TessCard(
      padding: const EdgeInsets.all(12),
      borderColor: riskColor.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Header
          Row(
            children: [
              // Step Order Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.violet.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.violet.withValues(alpha: 0.4)),
                ),
                child: Text(
                  '#${step.stepOrder}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    color: AppColors.violet,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Action Display Name
              Expanded(
                child: Text(
                  step.actionDisplayName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontFamily: 'monospace',
                  ),
                ),
              ),

              // Risk Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: riskColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  '${step.riskLevel} RISK',
                  style: TextStyle(
                    fontSize: 9,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    color: riskColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Target Resource & Tool name
          Row(
            children: [
              const Icon(Icons.hub_outlined, size: 14, color: AppColors.cyan),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Target: ${step.targetResource}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.cyan,
                    fontFamily: 'monospace',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  step.status,
                  style: TextStyle(
                    fontSize: 9,
                    fontFamily: 'monospace',
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
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.bgSecondary.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PARAMETERS (AUDITED)',
                    style: TextStyle(
                      fontSize: 9,
                      fontFamily: 'monospace',
                      color: AppColors.textMuted,
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
                            style: const TextStyle(
                              fontSize: 10,
                              fontFamily: 'monospace',
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              entry.value.toString(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontFamily: 'monospace',
                                color: AppColors.textPrimary,
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
                color: (step.isConfirmed ? AppColors.success : AppColors.warning).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: (step.isConfirmed ? AppColors.success : AppColors.warning).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    step.isConfirmed ? Icons.verified_user_rounded : Icons.gavel_rounded,
                    size: 16,
                    color: step.isConfirmed ? AppColors.success : AppColors.warning,
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
                            fontSize: 10,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            color: step.isConfirmed
                                ? AppColors.success
                                : (step.confirmation?.isExpired == true ? AppColors.danger : AppColors.warning),
                          ),
                        ),
                        if (step.confirmation != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            step.confirmation!.displaySummary,
                            style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                          ),
                          if (step.confirmation!.fingerprint != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Fingerprint: [fp:${step.confirmation!.fingerprint}]',
                              style: const TextStyle(
                                fontSize: 9,
                                fontFamily: 'monospace',
                                color: AppColors.cyan,
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
                Icon(Icons.shield_outlined, size: 14, color: AppColors.success),
                SizedBox(width: 6),
                Text(
                  'Low risk operation: Pre-authorized by policy',
                  style: TextStyle(fontSize: 10, color: AppColors.success),
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
                color: (step.status == 'SUCCESS' ? AppColors.success : AppColors.danger).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: (step.status == 'SUCCESS' ? AppColors.success : AppColors.danger).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    step.status == 'SUCCESS' ? Icons.check_circle_outline : Icons.error_outline,
                    size: 14,
                    color: step.status == 'SUCCESS' ? AppColors.success : AppColors.danger,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Result: ${step.result.toString()}',
                      style: TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                        color: step.status == 'SUCCESS' ? AppColors.success : AppColors.danger,
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
