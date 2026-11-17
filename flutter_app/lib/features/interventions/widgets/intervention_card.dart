import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/intervention_model.dart';

/// Holographic Intervention Card displaying proactive directive and user action levers
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
    if (intervention.isCritical) return AppColors.danger;
    if (intervention.isHighPriority) return AppColors.amber;
    return AppColors.cyan;
  }

  @override
  Widget build(BuildContext context) {
    final priorityColor = _priorityColor;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(
          color: priorityColor.withOpacity(0.35),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: priorityColor.withOpacity(0.05),
            blurRadius: 12.0,
            spreadRadius: 1.0,
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
                  color: priorityColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6.0),
                  border: Border.all(color: priorityColor.withOpacity(0.5)),
                ),
                child: Text(
                  intervention.priority,
                  style: TextStyle(
                    color: priorityColor,
                    fontSize: 10.0,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                decoration: BoxDecoration(
                  color: AppColors.bgSecondary,
                  borderRadius: BorderRadius.circular(6.0),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  intervention.formattedValueScore,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10.0,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                intervention.formattedTime,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10.5,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),

          // Title & Message
          Text(
            intervention.title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6.0),
          Text(
            intervention.message,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13.0,
              height: 1.4,
            ),
          ),

          // Triggering Reason / Context
          if (intervention.reason != null && intervention.reason!.isNotEmpty) ...[
            const SizedBox(height: 10.0),
            Container(
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.psychology_outlined, size: 14.0, color: AppColors.violetLight),
                  const SizedBox(width: 6.0),
                  Expanded(
                    child: Text(
                      'Triggered by: ${intervention.reason}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11.5,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16.0),
          const Divider(color: AppColors.border, height: 1.0),
          const SizedBox(height: 12.0),

          // Action Bar (for pending interventions)
          if (intervention.isPending)
            _buildActionButtons(context)
          else
            _buildStatusFooter(),
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
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.cyan),
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
            style: TextStyle(color: AppColors.textMuted, fontSize: 12.0),
          ),
        ),
        const SizedBox(width: 6.0),
        // Later
        OutlinedButton(
          onPressed: onPostpone,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.border),
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
          ),
          child: const Text(
            'Later (4h)',
            style: TextStyle(color: AppColors.violetLight, fontSize: 12.0),
          ),
        ),
        const SizedBox(width: 8.0),
        // Accept / Fix It
        ElevatedButton.icon(
          onPressed: onAccept,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.cyan,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
          ),
          icon: const Icon(Icons.check_rounded, size: 16.0),
          label: const Text(
            'FIX IT / ACT',
            style: TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              fontSize: 12.0,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusFooter() {
    Color statusColor = AppColors.textMuted;
    String label = intervention.status;
    IconData icon = Icons.info_outline;

    if (intervention.isActed) {
      statusColor = AppColors.success;
      label = 'ACCEPTED & ACTED';
      icon = Icons.check_circle_outline_rounded;
    } else if (intervention.isDeferred) {
      statusColor = AppColors.violetLight;
      label = 'DEFERRED (POSTPONED)';
      icon = Icons.snooze_rounded;
    } else if (intervention.isDismissed) {
      statusColor = AppColors.textMuted;
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
            fontFamily: 'monospace',
            fontSize: 11.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (intervention.isActed && onDelegateToAgent != null) ...[
          const Spacer(),
          TextButton.icon(
            onPressed: onDelegateToAgent,
            icon: const Icon(Icons.psychology_rounded, size: 14.0, color: AppColors.cyan),
            label: const Text(
              'PLAN WITH AGENT',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: AppColors.cyan,
              ),
            ),
          ),
        ] else if (intervention.deferredUntil != null) ...[
          const Spacer(),
          Text(
            'Until ${intervention.deferredUntil!.hour}:${intervention.deferredUntil!.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10.0,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ],
    );
  }
}

