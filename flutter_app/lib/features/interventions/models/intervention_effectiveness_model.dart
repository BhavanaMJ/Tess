/// Model representing empirical intervention acceptance and action conversion metrics
class InterventionEffectivenessModel {
  final int totalInterventions;
  final int acceptedCount;
  final int dismissedCount;
  final int actionsCompletedCount;
  final double acceptanceRate; // 0.0 to 1.0 or 0 to 100
  final double actionConversionRate; // 0.0 to 1.0 or 0 to 100
  final List<String> insights;

  const InterventionEffectivenessModel({
    required this.totalInterventions,
    required this.acceptedCount,
    required this.dismissedCount,
    required this.actionsCompletedCount,
    required this.acceptanceRate,
    required this.actionConversionRate,
    required this.insights,
  });

  double get acceptanceRatePercentage {
    if (acceptanceRate <= 1.0 && acceptanceRate > 0.0) {
      return (acceptanceRate * 100).roundToDouble();
    }
    return acceptanceRate.clamp(0.0, 100.0);
  }

  double get actionConversionRatePercentage {
    if (actionConversionRate <= 1.0 && actionConversionRate > 0.0) {
      return (actionConversionRate * 100).roundToDouble();
    }
    return actionConversionRate.clamp(0.0, 100.0);
  }

  factory InterventionEffectivenessModel.fromJson(Map<String, dynamic> json) {
    return InterventionEffectivenessModel(
      totalInterventions: (json['total_interventions'] as num?)?.toInt() ?? 0,
      acceptedCount: (json['accepted_count'] as num?)?.toInt() ?? 0,
      dismissedCount: (json['dismissed_count'] as num?)?.toInt() ?? 0,
      actionsCompletedCount: (json['actions_completed_count'] as num?)?.toInt() ?? 0,
      acceptanceRate: (json['acceptance_rate'] as num?)?.toDouble() ?? 0.0,
      actionConversionRate: (json['action_conversion_rate'] as num?)?.toDouble() ?? 0.0,
      insights: (json['insights'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_interventions': totalInterventions,
      'accepted_count': acceptedCount,
      'dismissed_count': dismissedCount,
      'actions_completed_count': actionsCompletedCount,
      'acceptance_rate': acceptanceRate,
      'action_conversion_rate': actionConversionRate,
      'insights': insights,
    };
  }
}
