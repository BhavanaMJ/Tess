/// Behavioral Insight observation
class BehavioralInsightModel {
  final String category;
  final String headline;
  final String observation;
  final List<String> evidence;
  final String dataQuality; // 'GOOD', 'PRELIMINARY', 'INSUFFICIENT'
  final int windowDays;

  const BehavioralInsightModel({
    required this.category,
    required this.headline,
    required this.observation,
    required this.evidence,
    required this.dataQuality,
    required this.windowDays,
  });

  factory BehavioralInsightModel.fromJson(Map<String, dynamic> json) {
    return BehavioralInsightModel(
      category: json['category'] as String? ?? 'GENERAL',
      headline: json['headline'] as String? ?? '',
      observation: json['observation'] as String? ?? '',
      evidence: (json['evidence'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      dataQuality: (json['data_quality'] as String?)?.toUpperCase() ?? 'INSUFFICIENT',
      windowDays: (json['window_days'] as num?)?.toInt() ?? 30,
    );
  }
}

/// Behavioral Profile and Historical Habits
class BehavioralAnalysisModel {
  final List<BehavioralInsightModel> insights;
  final Map<String, dynamic> metrics;
  final String dataQuality;
  final DateTime periodStart;
  final DateTime periodEnd;

  const BehavioralAnalysisModel({
    required this.insights,
    required this.metrics,
    required this.dataQuality,
    required this.periodStart,
    required this.periodEnd,
  });

  bool get isDataSufficient => dataQuality.toUpperCase() == 'GOOD';

  factory BehavioralAnalysisModel.fromJson(Map<String, dynamic> json) {
    final list = <BehavioralInsightModel>[];
    if (json['insights'] is List) {
      for (final item in json['insights']) {
        if (item is Map<String, dynamic>) {
          list.add(BehavioralInsightModel.fromJson(item));
        }
      }
    }

    return BehavioralAnalysisModel(
      insights: list,
      metrics: json['metrics'] is Map<String, dynamic>
          ? json['metrics'] as Map<String, dynamic>
          : {},
      dataQuality: (json['data_quality'] as String?)?.toUpperCase() ?? 'INSUFFICIENT',
      periodStart: json['period_start'] != null
          ? DateTime.tryParse(json['period_start'].toString()) ?? DateTime.now()
          : DateTime.now(),
      periodEnd: json['period_end'] != null
          ? DateTime.tryParse(json['period_end'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
