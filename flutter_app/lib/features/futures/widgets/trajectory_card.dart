import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/future_prediction_model.dart';

/// Prediction Card displaying trajectory, confidence, and evidence
class TrajectoryCard extends StatefulWidget {
  final FuturePredictionModel prediction;

  const TrajectoryCard({super.key, required this.prediction});

  @override
  State<TrajectoryCard> createState() => _TrajectoryCardState();
}

class _TrajectoryCardState extends State<TrajectoryCard> {
  bool _isExpanded = false;

  Color get _statusColor {
    if (widget.prediction.isRisk) return AppColors.accentDanger;
    if (widget.prediction.isPositive) return AppColors.accentSuccess;
    return AppColors.tessTeal;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = _statusColor;

    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final badgeBg = isDark ? AppColors.darkSurfaceElevated : AppColors.lightSecondary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6.0),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: AppRadius.card,
        border: Border.all(
          color: color.withOpacity(0.35),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.04),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Horizon Pill, Type Pill, and Probability / Confidence Badges
          Row(
            children: [
              // Horizon pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: AppRadius.xs,
                  border: Border.all(color: borderColor),
                ),
                child: Text(
                  widget.prediction.timeHorizon.toUpperCase(),
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 10.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              // Type pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: AppRadius.xs,
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Text(
                  widget.prediction.predictionType,
                  style: TextStyle(
                    color: color,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              // Probability Badge
              Text(
                widget.prediction.formattedProbability,
                style: TextStyle(
                  color: color,
                  fontSize: 12.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              // Confidence Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: AppRadius.xs,
                  border: Border.all(color: borderColor),
                ),
                child: Text(
                  'CONF: ${widget.prediction.confidence}',
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Title
          Text(
            widget.prediction.title,
            style: TextStyle(
              color: textPrimary,
              fontSize: 15.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (widget.prediction.description.isNotEmpty) ...[
            const SizedBox(height: 4.0),
            Text(
              widget.prediction.description,
              style: TextStyle(
                color: textSecondary,
                fontSize: 13.0,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          // Expand / Collapse Details (Evidence & Reasoning)
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isExpanded ? 'Hide evidence & reasoning' : 'View evidence & reasoning',
                  style: const TextStyle(
                    color: AppColors.tessTeal,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(
                  _isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  size: 18.0,
                  color: AppColors.tessTeal,
                ),
              ],
            ),
          ),
          if (_isExpanded) ...[
            const SizedBox(height: AppSpacing.xs),
            Divider(color: borderColor, height: 16.0),
            if (widget.prediction.reasoning.isNotEmpty) ...[
              Text(
                'COMPANION REASONING',
                style: TextStyle(
                  fontSize: 10.0,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: textMuted,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                widget.prediction.reasoning,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 12.5,
                  fontStyle: FontStyle.italic,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
            if (widget.prediction.evidence.isNotEmpty) ...[
              Text(
                'SUPPORTING EVIDENCE',
                style: TextStyle(
                  fontSize: 10.0,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: textMuted,
                ),
              ),
              const SizedBox(height: 4.0),
              ...widget.prediction.evidence.map(
                (ev) => Padding(
                  padding: const EdgeInsets.only(bottom: 3.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '• ',
                        style: TextStyle(color: AppColors.tessTeal, fontSize: 13.0),
                      ),
                      Expanded(
                        child: Text(
                          ev,
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 12.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
