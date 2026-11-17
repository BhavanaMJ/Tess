/// Long-term explainable forecast (30d, 90d, 365d) from Future Engine
class LongTermForecastModel {
  final String id;
  final String horizon;
  final int projectedBacklog;
  final int completionForecast;
  final double burnoutRiskScore; // 0.0 - 1.0 or 0 - 100
  final double rawProbability;
  final String confidence;
  final Map<String, double> uncertaintyRange;
  final List<String> assumptions;
  final List<String> evidence;
  final String explanation;
  final DateTime createdAt;

  const LongTermForecastModel({
    required this.id,
    required this.horizon,
    required this.projectedBacklog,
    required this.completionForecast,
    required this.burnoutRiskScore,
    required this.rawProbability,
    required this.confidence,
    required this.uncertaintyRange,
    required this.assumptions,
    required this.evidence,
    required this.explanation,
    required this.createdAt,
  });

  /// Burnout risk normalized to percentage (0 - 100)
  double get burnoutRiskPercentage {
    if (burnoutRiskScore <= 1.0 && burnoutRiskScore > 0.0) {
      return (burnoutRiskScore * 100).roundToDouble();
    }
    return burnoutRiskScore.clamp(0.0, 100.0);
  }

  bool get isHighBurnoutRisk => burnoutRiskPercentage >= 65.0;

  double get probabilityPercentage {
    if (rawProbability <= 1.0 && rawProbability > 0.0) {
      return (rawProbability * 100).roundToDouble();
    }
    return rawProbability.clamp(0.0, 100.0);
  }

  factory LongTermForecastModel.fromJson(Map<String, dynamic> json) {
    final rangeMap = <String, double>{};
    if (json['uncertainty_range'] is Map) {
      (json['uncertainty_range'] as Map).forEach((k, v) {
        if (v is num) rangeMap[k.toString()] = v.toDouble();
      });
    }

    return LongTermForecastModel(
      id: json['id'] as String? ?? '',
      horizon: json['horizon'] as String? ?? '30d',
      projectedBacklog: (json['projected_backlog'] as num?)?.toInt() ?? 0,
      completionForecast: (json['completion_forecast'] as num?)?.toInt() ?? 0,
      burnoutRiskScore: (json['burnout_risk_score'] as num?)?.toDouble() ?? 0.0,
      rawProbability: (json['probability'] as num?)?.toDouble() ?? 0.5,
      confidence: (json['confidence'] as String?)?.toUpperCase() ?? 'MEDIUM',
      uncertaintyRange: rangeMap,
      assumptions: (json['assumptions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      evidence: (json['evidence'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      explanation: json['explanation'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'horizon': horizon,
      'projected_backlog': projectedBacklog,
      'completion_forecast': completionForecast,
      'burnout_risk_score': burnoutRiskScore,
      'probability': rawProbability,
      'confidence': confidence,
      'uncertainty_range': uncertaintyRange,
      'assumptions': assumptions,
      'evidence': evidence,
      'explanation': explanation,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

