import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/tess_card.dart';
import '../models/dashboard_model.dart';

/// FuturePreview renders real predictions returned from the FastAPI Future Engine:
/// GET /api/v1/future/predictions
class FuturePreview extends StatelessWidget {
  final List<BackendFuturePredictionModel> predictions;
  final VoidCallback onExplore;

  const FuturePreview({
    super.key,
    required this.predictions,
    required this.onExplore,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.explore_outlined, color: AppColors.cyan, size: 16),
                SizedBox(width: 6),
                Text(
                  'FUTURE ENGINE TRAJECTORY',
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMuted,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            InkWell(
              onTap: onExplore,
              child: const Text(
                'VIEW ALL',
                style: TextStyle(
                  fontSize: 10,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  color: AppColors.cyan,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10.0),

        if (predictions.isEmpty)
          TessCard(
            borderColor: AppColors.cyan.withValues(alpha: 0.25),
            child: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: AppColors.success, size: 22),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trajectories Nominal',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'No critical convergence risks detected on current timeline.',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          ...predictions.take(2).map((pred) => _buildPredictionCard(pred)),
      ],
    );
  }

  Widget _buildPredictionCard(BackendFuturePredictionModel pred) {
    final isRisk = pred.isRisk;
    final isPositive = pred.isPositive;
    final badgeColor = isRisk
        ? AppColors.danger
        : (isPositive ? AppColors.success : AppColors.cyan);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: TessCard(
        borderColor: badgeColor.withValues(alpha: 0.35),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    pred.predictionType,
                    style: TextStyle(
                      fontSize: 9,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      color: badgeColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Horizon: ${pred.timeHorizon}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    color: AppColors.textMuted,
                  ),
                ),
                const Spacer(),
                Text(
                  pred.formattedProbability,
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              pred.title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            if (pred.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                pred.description,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
              ),
            ],
            if (pred.reasoning.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: AppColors.bgVoid.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(6.0),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  'Reasoning: ${pred.reasoning}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
