import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/tess_badge.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.explore_outlined, color: AppColors.tessTeal, size: 18),
                const SizedBox(width: 6),
                Text(
                  'FUTURE TRAJECTORY PREVIEW',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
              ],
            ),
            InkWell(
              onTap: onExplore,
              borderRadius: BorderRadius.circular(6),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Text(
                  'SIMULATE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: AppColors.tessTeal,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10.0),

        if (predictions.isEmpty)
          TessCard(
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.success.withValues(alpha: isDark ? 0.20 : 0.12),
                  ),
                  child: const Icon(Icons.check_circle_outline, color: AppColors.success, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trajectories Nominal',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: primaryText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'No critical milestone convergence risks on current horizon.',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
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
          ...predictions.take(2).map((pred) => _buildPredictionCard(context, pred)),
      ],
    );
  }

  Widget _buildPredictionCard(BuildContext context, BackendFuturePredictionModel pred) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryText = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final isRisk = pred.isRisk;
    final isPositive = pred.isPositive;
    final statusColor = isRisk
        ? AppColors.danger
        : (isPositive ? AppColors.success : AppColors.tessTeal);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: TessCard(
        borderColor: statusColor.withValues(alpha: isDark ? 0.35 : 0.25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                TessBadge(
                  label: pred.predictionType,
                  variant: isRisk
                      ? TessBadgeVariant.danger
                      : (isPositive ? TessBadgeVariant.success : TessBadgeVariant.info),
                ),
                const SizedBox(width: 8),
                Text(
                  '${pred.timeHorizon} Horizon',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
                const Spacer(),
                Text(
                  '${pred.probability.toStringAsFixed(0)}% Probability',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              pred.title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: primaryText,
              ),
            ),
            if (pred.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                pred.description,
                style: TextStyle(
                  fontSize: 12,
                  color: secondaryText,
                  height: 1.35,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
