import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
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
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(48.0),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.cyan),
        ),
      );
    }

    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: AppColors.danger.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: AppColors.danger.withOpacity(0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Accuracy Metrics Unavailable', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4.0),
              Text(_errorMessage!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5)),
              TextButton(
                onPressed: _loadAccuracy,
                child: const Text('Retry', style: TextStyle(color: AppColors.cyan)),
              ),
            ],
          ),
        ),
      );
    }

    if (_accuracy == null) return const SizedBox.shrink();

    final acc = _accuracy!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Calibration Matrix
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatTile(
                  'EVALUATIONS',
                  '${acc.totalEvaluated}',
                  AppColors.cyan,
                ),
                Container(width: 1.0, height: 36.0, color: AppColors.border),
                _buildStatTile(
                  'BRIER SCORE',
                  acc.brierCalibrationScore.toStringAsFixed(3),
                  AppColors.violetLight,
                ),
                Container(width: 1.0, height: 36.0, color: AppColors.border),
                _buildStatTile(
                  'ACCURACY',
                  acc.hasSufficientSampleSize ? '${acc.accuracyPercentage.toInt()}%' : 'N/A',
                  acc.hasSufficientSampleSize ? AppColors.success : AppColors.amber,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12.0),

          // Sample Size Honesty Alert
          if (!acc.hasSufficientSampleSize)
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: AppColors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: AppColors.amber.withOpacity(0.4)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: AppColors.amber, size: 18.0),
                  SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      'Calibration Sample Size Note: Current evaluation sample size (N < 5) is insufficient to guarantee statistically calibrated accuracy percentages. Active forecasts represent directional heuristics.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11.5,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (acc.recentEvaluations.isNotEmpty) ...[
            const SizedBox(height: 16.0),
            const Text(
              'RECENT PREDICTION AUDITS:',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 8.0),
            ...acc.recentEvaluations.map(
              (item) => Container(
                margin: const EdgeInsets.only(bottom: 6.0),
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      item.isConfirmed
                          ? Icons.check_circle_outline_rounded
                          : Icons.pending_outlined,
                      size: 16.0,
                      color: item.isConfirmed ? AppColors.success : AppColors.amber,
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.predictedOutcome,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (item.actualOutcome.isNotEmpty)
                            Text(
                              'Observed: ${item.actualOutcome}',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 10.5,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                      decoration: BoxDecoration(
                        color: AppColors.bgSecondary,
                        borderRadius: BorderRadius.circular(4.0),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        item.status,
                        style: TextStyle(
                          fontSize: 9.0,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          color: item.isConfirmed ? AppColors.success : AppColors.amber,
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

  Widget _buildStatTile(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 9.0,
            fontFamily: 'monospace',
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}
