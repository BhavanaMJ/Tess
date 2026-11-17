// Strongly Typed Models for TESS Real Backend Dashboard Integration.
// Faithfully maps to FastAPI Pydantic schemas:
// - app.schemas.productivity.ProductivitySummary
// - app.schemas.future.FuturePrediction

class ProductivitySummaryModel {
  final int totalActive;
  final int overdue;
  final int dueToday;
  final int dueThisWeek;
  final int completedRecently;

  const ProductivitySummaryModel({
    this.totalActive = 0,
    this.overdue = 0,
    this.dueToday = 0,
    this.dueThisWeek = 0,
    this.completedRecently = 0,
  });

  factory ProductivitySummaryModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ProductivitySummaryModel();
    return ProductivitySummaryModel(
      totalActive: json['total_active'] as int? ?? 0,
      overdue: json['overdue'] as int? ?? 0,
      dueToday: json['due_today'] as int? ?? 0,
      dueThisWeek: json['due_this_week'] as int? ?? 0,
      completedRecently: json['completed_recently'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_active': totalActive,
      'overdue': overdue,
      'due_today': dueToday,
      'due_this_week': dueThisWeek,
      'completed_recently': completedRecently,
    };
  }

  bool get hasOverdue => overdue > 0;
}

class BackendFuturePredictionModel {
  final String id;
  final String predictionType; // RISK, NEUTRAL, POSITIVE
  final String title;
  final String description;
  final double probability;
  final String confidence; // HIGH, MEDIUM, LOW
  final String timeHorizon; // e.g. "24h", "72h"
  final List<String> evidence;
  final String reasoning;

  const BackendFuturePredictionModel({
    required this.id,
    required this.predictionType,
    required this.title,
    required this.description,
    required this.probability,
    required this.confidence,
    required this.timeHorizon,
    this.evidence = const [],
    this.reasoning = '',
  });

  factory BackendFuturePredictionModel.fromJson(Map<String, dynamic> json) {
    final rawProb = json['probability'];
    double parsedProb = 0.0;
    if (rawProb is num) {
      // Normalize if represented as 0.0-1.0 or 0-100
      parsedProb = rawProb > 1.0 ? rawProb.toDouble() : (rawProb * 100).toDouble();
    }

    final rawEvidence = json['evidence'];
    List<String> parsedEvidence = [];
    if (rawEvidence is List) {
      parsedEvidence = rawEvidence.map((e) => e.toString()).toList();
    }

    return BackendFuturePredictionModel(
      id: json['id'] as String? ?? 'pred_${DateTime.now().millisecondsSinceEpoch}',
      predictionType: (json['prediction_type'] as String? ?? 'NEUTRAL').toUpperCase(),
      title: json['title'] as String? ?? 'Future Trajectory',
      description: json['description'] as String? ?? '',
      probability: parsedProb,
      confidence: (json['confidence'] as String? ?? 'MEDIUM').toUpperCase(),
      timeHorizon: json['time_horizon'] as String? ?? '24h',
      evidence: parsedEvidence,
      reasoning: json['reasoning'] as String? ?? '',
    );
  }

  bool get isRisk => predictionType == 'RISK';
  bool get isPositive => predictionType == 'POSITIVE';

  String get formattedProbability => '${probability.toStringAsFixed(0)}% Probability';
}

/// Aggregated data container for the TESS Home Dashboard
class DashboardData {
  final ProductivitySummaryModel summary;
  final List<BackendFuturePredictionModel> predictions;
  final String userEmail;
  final String callsign;

  const DashboardData({
    required this.summary,
    required this.predictions,
    required this.userEmail,
    required this.callsign,
  });

  bool get hasUrgentAlerts => summary.hasOverdue || predictions.any((p) => p.isRisk);
}
