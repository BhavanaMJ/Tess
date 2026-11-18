import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/accuracy_model.dart';
import '../services/future_service.dart';

/// Prediction Evaluation & Empirical Calibration Accuracy View
class AccuracyMetricsView extends StatefulWidget {
  final FutureService futureService;

  const AccuracyMetricsView({super.key, required this.futureService});

  @override
  State<AccuracyMetricsView> createState() => _AccuracyMetricsViewState();
}

class _AccuracyMetricsViewState extends State<AccuracyMetricsView> {
  AccuracyMetricsModel? _accuracy;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAccuracy();
  }

  Future<void> _loadAccuracy() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await widget.futureService.getAccuracyMetrics();
      if (mounted) {
        setState(() {
          _accuracy = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final chipBg = isDark ? AppColors.darkSurfaceElevated : AppColors.lightSecondary;

    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(48.0),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.tessTeal),
        ),
      );
    }

    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.accentDanger.withOpacity(0.1),
            borderRadius: AppRadius.card,
            border: Border.all(color: AppColors.accentDanger.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Accuracy Metrics Unavailable', style: TextStyle(color: AppColors.accentDanger, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4.0),
              Text(_errorMessage!, style: TextStyle(color: textSecondary, fontSize: 12.0)),
              TextButton(
                onPressed: _loadAccuracy,
                child: const Text('Retry', style: TextStyle(color: AppColors.tessTeal)),
              ),
            ],
          ),
        ),
      );
    }

    if (_accuracy == null) return const SizedBox.shrink();

    final acc = _accuracy!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Calibration Matrix
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: AppRadius.card,
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.03),
                  blurRadius: 8.0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatTile(
                  'EVALUATIONS',
                  '${acc.totalEvaluated}',
                  AppColors.tessTeal,
                  textMuted,
                ),
                Container(width: 1.0, height: 36.0, color: borderColor),
                _buildStatTile(
                  'BRIER SCORE',
                  acc.brierCalibrationScore.toStringAsFixed(3),
                  AppColors.vibrantMint,
                  textMuted,
                ),
                Container(width: 1.0, height: 36.0, color: borderColor),
                _buildStatTile(
                  'ACCURACY',
                  acc.hasSufficientSampleSize ? '${acc.accuracyPercentage.toInt()}%' : 'N/A',
                  acc.hasSufficientSampleSize ? AppColors.accentSuccess : AppColors.accentWarning,
                  textMuted,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Sample Size Honesty Alert
          if (!acc.hasSufficientSampleSize)
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.accentWarning.withOpacity(0.1),
                borderRadius: AppRadius.card,
                border: Border.all(color: AppColors.accentWarning.withOpacity(0.35)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.accentWarning, size: 20.0),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Calibration Sample Size Note: Current evaluation sample size (N < 5) is insufficient to guarantee statistically calibrated accuracy percentages. Active forecasts represent directional heuristics.',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 12.0,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (acc.recentEvaluations.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'RECENT PREDICTION AUDITS:',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...acc.recentEvaluations.map(
              (item) => Container(
                margin: const EdgeInsets.only(bottom: 8.0),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: AppRadius.card,
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Icon(
                      item.isConfirmed
                          ? Icons.check_circle_outline_rounded
                          : Icons.pending_outlined,
                      size: 18.0,
                      color: item.isConfirmed ? AppColors.accentSuccess : AppColors.accentWarning,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.predictedOutcome,
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 13.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (item.actualOutcome.isNotEmpty)
                            Text(
                              'Observed: ${item.actualOutcome}',
                              style: TextStyle(
                                color: textMuted,
                                fontSize: 11.0,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                      decoration: BoxDecoration(
                        color: chipBg,
                        borderRadius: AppRadius.pill,
                        border: Border.all(color: borderColor),
                      ),
                      child: Text(
                        item.status,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: item.isConfirmed ? AppColors.accentSuccess : AppColors.accentWarning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatTile(String label, String value, Color color, Color textMuted) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          label,
          style: TextStyle(
            color: textMuted,
            fontSize: 9.0,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
