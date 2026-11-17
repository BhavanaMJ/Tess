/// Model representing an active future prediction from FastAPI Future Engine.
/// Corresponds to backend `FuturePrediction` schema.
class FuturePredictionModel {
  final String id;
  final String userId;
  final String predictionType; // 'RISK', 'NEUTRAL', 'POSITIVE'
  final String title;
  final String description;
  final double rawProbability; // 0.0 to 1.0 or 0 to 100
  final String confidence; // 'LOW', 'MEDIUM', 'HIGH'
  final String timeHorizon; // e.g. '24h', '48h', '7d', '30d'
  final List<String> evidence;
  final String reasoning;
  final String status; // 'ACTIVE', 'CONFIRMED', 'DISMISSED'
  final DateTime createdAt;
  final DateTime? expiresAt;

  const FuturePredictionModel({
    required this.id,
    required this.userId,
    required this.predictionType,
    required this.title,
    required this.description,
    required this.rawProbability,
    required this.confidence,
    required this.timeHorizon,
    required this.evidence,
    required this.reasoning,
    required this.status,
    required this.createdAt,
    this.expiresAt,
  });

  bool get isRisk => predictionType.toUpperCase() == 'RISK';
  bool get isPositive => predictionType.toUpperCase() == 'POSITIVE';
  bool get isNeutral => !isRisk && !isPositive;

  /// Normalized probability as a clean percentage (0 - 100)
  double get probabilityPercentage {
    if (rawProbability <= 1.0 && rawProbability > 0.0) {
      return (rawProbability * 100).roundToDouble();
    }
    return rawProbability.clamp(0.0, 100.0);
  }

  String get formattedProbability => '${probabilityPercentage.toInt()}% Probability';

  factory FuturePredictionModel.fromJson(Map<String, dynamic> json) {
    return FuturePredictionModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      predictionType: (json['prediction_type'] as String?)?.toUpperCase() ?? 'NEUTRAL',
      title: json['title'] as String? ?? 'Nominal Trajectory',
      description: json['description'] as String? ?? '',
      rawProbability: (json['probability'] as num?)?.toDouble() ?? 0.5,
      confidence: (json['confidence'] as String?)?.toUpperCase() ?? 'MEDIUM',
      timeHorizon: json['time_horizon'] as String? ?? '24h',
      evidence: (json['evidence'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      reasoning: json['reasoning'] as String? ?? '',
      status: json['status'] as String? ?? 'ACTIVE',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'prediction_type': predictionType,
      'title': title,
      'description': description,
      'probability': rawProbability,
      'confidence': confidence,
      'time_horizon': timeHorizon,
      'evidence': evidence,
      'reasoning': reasoning,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
    };
  }
}

