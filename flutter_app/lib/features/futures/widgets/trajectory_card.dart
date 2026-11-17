import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/future_prediction_model.dart';

/// Holographic Prediction Card displaying trajectory, confidence, and evidence
class TrajectoryCard extends StatefulWidget {
  final FuturePredictionModel prediction;

  const TrajectoryCard({super.key, required this.prediction});

  @override
  State<TrajectoryCard> createState() => _TrajectoryCardState();
}

class _TrajectoryCardState extends State<TrajectoryCard> {
  bool _isExpanded = false;

  Color get _statusColor {
    if (widget.prediction.isRisk) return AppColors.danger;
    if (widget.prediction.isPositive) return AppColors.success;
    return AppColors.cyan;
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: color.withOpacity(0.35),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.04),
            blurRadius: 10.0,
            spreadRadius: 1.0,
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
                  color: AppColors.bgSecondary,
                  borderRadius: BorderRadius.circular(6.0),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  widget.prediction.timeHorizon.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 10.0,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              // Type pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6.0),
                  border: Border.all(color: color.withOpacity(0.4)),
                ),
                child: Text(
                  widget.prediction.predictionType,
                  style: TextStyle(
                    color: color,
                    fontSize: 10.0,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const Spacer(),
              // Probability Badge
              Text(
                widget.prediction.formattedProbability,
                style: TextStyle(
                  color: color,
                  fontSize: 11.0,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(width: 6.0),
              // Confidence Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                decoration: BoxDecoration(
                  color: AppColors.bgSecondary,
                  borderRadius: BorderRadius.circular(4.0),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  'CONF: ${widget.prediction.confidence}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 9.0,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),
          // Title
          Text(
            widget.prediction.title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (widget.prediction.description.isNotEmpty) ...[
            const SizedBox(height: 4.0),
            Text(
              widget.prediction.description,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 10.0),
          // Expand / Collapse Details (Evidence & Reasoning)
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isExpanded ? 'HIDE EVIDENCE & REASONING' : 'VIEW EVIDENCE & REASONING',
                  style: const TextStyle(
                    color: AppColors.cyan,
                    fontSize: 10.0,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 16.0,
                  color: AppColors.cyan,
                ),
              ],
            ),
          ),
          if (_isExpanded) ...[
            const SizedBox(height: 10.0),
            const Divider(color: AppColors.border, height: 1.0),
            const SizedBox(height: 10.0),
            if (widget.prediction.reasoning.isNotEmpty) ...[
              const Text(
                'NEURAL REASONING:',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10.0,
                  color: AppColors.textMuted,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                widget.prediction.reasoning,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.0,
                  fontStyle: FontStyle.italic,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 8.0),
            ],
            if (widget.prediction.evidence.isNotEmpty) ...[
              const Text(
                'SUPPORTING EVIDENCE:',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10.0,
                  color: AppColors.textMuted,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 4.0),
              ...widget.prediction.evidence.map(
                (ev) => Padding(
                  padding: const EdgeInsets.only(bottom: 2.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '• ',
                        style: TextStyle(color: AppColors.cyan, fontSize: 12.0),
                      ),
                      Expanded(
                        child: Text(
                          ev,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11.5,
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
