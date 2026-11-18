import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/intervention_model.dart';

/// Intervention Card displaying proactive directive and user action levers
class InterventionCard extends StatelessWidget {
  final InterventionModel intervention;
  final bool isSubmitting;
  final VoidCallback? onAccept;
  final VoidCallback? onPostpone;
  final VoidCallback? onDismiss;
  final VoidCallback? onDelegateToAgent;

  const InterventionCard({
    super.key,
    required this.intervention,
    this.isSubmitting = false,
    this.onAccept,
    this.onPostpone,
    this.onDismiss,
    this.onDelegateToAgent,
  });

  Color get _priorityColor {
    if (intervention.isCritical) return AppColors.accentDanger;
    if (intervention.isHighPriority) return AppColors.accentWarning;
    return AppColors.tessTeal;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final priorityColor = _priorityColor;

    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final chipBg = isDark ? AppColors.darkSurfaceElevated : AppColors.lightSecondary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6.0),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: AppRadius.card,
        border: Border.all(
          color: priorityColor.withOpacity(0.35),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: priorityColor.withOpacity(0.04),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Priority, Value Score, and Time
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.12),
                  borderRadius: AppRadius.xs,
                  border: Border.all(color: priorityColor.withOpacity(0.35)),
                ),
                child: Text(
                  intervention.priority,
                  style: TextStyle(
                    color: priorityColor,
                    fontSize: 10.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                decoration: BoxDecoration(
                  color: chipBg,
                  borderRadius: AppRadius.xs,
                  border: Border.all(color: borderColor),
                ),
                child: Text(
                  intervention.formattedValueScore,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 10.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                intervention.formattedTime,
                style: TextStyle(
                  color: textMuted,
                  fontSize: 11.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Title & Message
          Text(
            intervention.title,
            style: TextStyle(
              color: textPrimary,
              fontSize: 15.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6.0),
          Text(
            intervention.message,
            style: TextStyle(
              color: textSecondary,
              fontSize: 13.0,
              height: 1.4,
            ),
          ),

          // Triggering Reason / Context
          if (intervention.reason != null && intervention.reason!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: chipBg,
                borderRadius: AppRadius.sm,
                border: Border.all(color: borderColor),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.psychology_outlined, size: 16.0, color: AppColors.tessTeal),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Triggered by: ${intervention.reason}',
                      style: TextStyle(
                        color: textMuted,
                        fontSize: 11.5,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.md),
          Divider(color: borderColor, height: 1.0),
          const SizedBox(height: AppSpacing.sm),

          // Action Bar (for pending interventions)
          if (intervention.isPending)
            _buildActionButtons(context)
          else
            _buildStatusFooter(textMuted),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    if (isSubmitting) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: SizedBox(
            width: 20.0,
            height: 20.0,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.tessTeal),
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Dismiss
        TextButton(
          onPressed: onDismiss,
          child: const Text(
            'Dismiss',
            style: TextStyle(color: AppColors.accentDanger, fontSize: 12.0),
          ),
        ),
        const SizedBox(width: 6.0),
        // Later
        OutlinedButton(
          onPressed: onPostpone,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.tessTeal),
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.pill),
          ),
          child: const Text(
            'Later (4h)',
            style: TextStyle(color: AppColors.tessTeal, fontSize: 12.0, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 8.0),
        // Accept / Fix It
        ElevatedButton.icon(
          onPressed: onAccept,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.tessTeal,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.pill),
          ),
          icon: const Icon(Icons.check_rounded, size: 16.0),
          label: const Text(
            'FIX IT / ACT',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12.0,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusFooter(Color mutedColor) {
    Color statusColor = mutedColor;
    String label = intervention.status;
    IconData icon = Icons.info_outline;

    if (intervention.isActed) {
      statusColor = AppColors.accentSuccess;
      label = 'ACCEPTED & ACTED';
      icon = Icons.check_circle_outline_rounded;
    } else if (intervention.isDeferred) {
      statusColor = AppColors.tessTeal;
      label = 'DEFERRED (POSTPONED)';
      icon = Icons.snooze_rounded;
    } else if (intervention.isDismissed) {
      statusColor = mutedColor;
      label = 'DISMISSED';
      icon = Icons.close_rounded;
    }

    return Row(
      children: [
        Icon(icon, size: 14.0, color: statusColor),
        const SizedBox(width: 6.0),
        Text(
          label,
          style: TextStyle(
            color: statusColor,
            fontSize: 11.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (intervention.isActed && onDelegateToAgent != null) ...[
          const Spacer(),
          TextButton.icon(
            onPressed: onDelegateToAgent,
            icon: const Icon(Icons.psychology_rounded, size: 14.0, color: AppColors.tessTeal),
            label: const Text(
              'PLAN WITH AGENT',
              style: TextStyle(
                fontSize: 11.0,
                fontWeight: FontWeight.bold,
                color: AppColors.tessTeal,
              ),
            ),
          ),
        ] else if (intervention.deferredUntil != null) ...[
          const Spacer(),
          Text(
            'Until ${intervention.deferredUntil!.hour}:${intervention.deferredUntil!.minute.toString().padLeft(2, '0')}',
            style: TextStyle(
              color: mutedColor,
              fontSize: 10.5,
            ),
          ),
        ],
      ],
    );
  }
}
