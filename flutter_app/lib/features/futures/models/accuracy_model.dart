/// Individual prediction evaluation item
class PredictionEvaluationModel {
  final String id;
  final String predictionId;
  final String horizon;
  final String predictedOutcome;
  final String actualOutcome;
  final String status; // 'CONFIRMED', 'NOT_CONFIRMED', 'PENDING', 'INSUFFICIENT_DATA'
  final double? brierScore;
  final DateTime evaluatedAt;

  const PredictionEvaluationModel({
    required this.id,
    required this.predictionId,
    required this.horizon,
    required this.predictedOutcome,
    required this.actualOutcome,
    required this.status,
    this.brierScore,
    required this.evaluatedAt,
  });

  bool get isConfirmed => status.toUpperCase() == 'CONFIRMED';

  factory PredictionEvaluationModel.fromJson(Map<String, dynamic> json) {
    return PredictionEvaluationModel(
      id: json['id'] as String? ?? '',
      predictionId: json['prediction_id'] as String? ?? '',
      horizon: json['horizon'] as String? ?? '24h',
      predictedOutcome: json['predicted_outcome'] as String? ?? '',
      actualOutcome: json['actual_outcome'] as String? ?? '',
      status: (json['status'] as String?)?.toUpperCase() ?? 'PENDING',
      brierScore: (json['brier_score'] as num?)?.toDouble(),
      evaluatedAt: json['evaluated_at'] != null
          ? DateTime.tryParse(json['evaluated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

/// Accuracy metrics, Brier calibration score, and evaluation sample size
class AccuracyMetricsModel {
  final int totalEvaluated;
  final double overallAccuracy;
  final double brierCalibrationScore;
  final Map<String, double> accuracyByHorizon;
  final Map<String, double> accuracyByType;
  final List<PredictionEvaluationModel> recentEvaluations;

  const AccuracyMetricsModel({
    required this.totalEvaluated,
    required this.overallAccuracy,
    required this.brierCalibrationScore,
    required this.accuracyByHorizon,
    required this.accuracyByType,
    required this.recentEvaluations,
  });

  /// Calibrated statistics require adequate sample size (N >= 5)
  bool get hasSufficientSampleSize => totalEvaluated >= 5;

  double get accuracyPercentage {
    if (overallAccuracy <= 1.0 && overallAccuracy > 0.0) {
      return (overallAccuracy * 100).roundToDouble();
    }
    return overallAccuracy.clamp(0.0, 100.0);
  }

  factory AccuracyMetricsModel.fromJson(Map<String, dynamic> json) {
    final byHorizon = <String, double>{};
    if (json['accuracy_by_horizon'] is Map) {
      (json['accuracy_by_horizon'] as Map).forEach((k, v) {
        if (v is num) byHorizon[k.toString()] = v.toDouble();
      });
    }

    final byType = <String, double>{};
    if (json['accuracy_by_type'] is Map) {
      (json['accuracy_by_type'] as Map).forEach((k, v) {
        if (v is num) byType[k.toString()] = v.toDouble();
      });
    }

    final evaluations = <PredictionEvaluationModel>[];
    if (json['recent_evaluations'] is List) {
      for (final item in json['recent_evaluations']) {
        if (item is Map<String, dynamic>) {
          evaluations.add(PredictionEvaluationModel.fromJson(item));
        }
      }
    }

    return AccuracyMetricsModel(
      totalEvaluated: (json['total_evaluated'] as num?)?.toInt() ?? 0,
      overallAccuracy: (json['overall_accuracy'] as num?)?.toDouble() ?? 0.0,
      brierCalibrationScore:
          (json['brier_calibration_score'] as num?)?.toDouble() ?? 0.25,
      accuracyByHorizon: byHorizon,
      accuracyByType: byType,
      recentEvaluations: evaluations,
    );
  }
}

