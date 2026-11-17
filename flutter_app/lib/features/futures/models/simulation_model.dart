/// Event along a simulated future timeline
class ScenarioEventModel {
  final String id;
  final int sequence;
  final String relativeTime; // e.g. '+4h', '+12h', '+24h'
  final String title;
  final String description;
  final String confidence;

  const ScenarioEventModel({
    required this.id,
    required this.sequence,
    required this.relativeTime,
    required this.title,
    required this.description,
    required this.confidence,
  });

  factory ScenarioEventModel.fromJson(Map<String, dynamic> json) {
    return ScenarioEventModel(
      id: json['id'] as String? ?? '',
      sequence: (json['sequence'] as num?)?.toInt() ?? 0,
      relativeTime: json['relative_time'] as String? ?? '0h',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      confidence: (json['confidence'] as String?)?.toUpperCase() ?? 'MEDIUM',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sequence': sequence,
      'relative_time': relativeTime,
      'title': title,
      'description': description,
      'confidence': confidence,
    };
  }
}

/// Simulated Future Scenario
class FutureScenarioModel {
  final String id;
  final String trajectoryType; // e.g. 'CURRENT', 'IMPROVED', 'ALTERNATIVE'
  final String title;
  final String summary;
  final String horizon;
  final double rawProbability;
  final String confidence;
  final List<String> evidence;
  final List<ScenarioEventModel> events;

  const FutureScenarioModel({
    required this.id,
    required this.trajectoryType,
    required this.title,
    required this.summary,
    required this.horizon,
    required this.rawProbability,
    required this.confidence,
    required this.evidence,
    required this.events,
  });

  double get probabilityPercentage {
    if (rawProbability <= 1.0 && rawProbability > 0.0) {
      return (rawProbability * 100).roundToDouble();
    }
    return rawProbability.clamp(0.0, 100.0);
  }

  factory FutureScenarioModel.fromJson(Map<String, dynamic> json) {
    return FutureScenarioModel(
      id: json['id'] as String? ?? '',
      trajectoryType: (json['trajectory_type'] as String?)?.toUpperCase() ?? 'CURRENT',
      title: json['title'] as String? ?? 'Simulation Scenario',
      summary: json['summary'] as String? ?? '',
      horizon: json['horizon'] as String? ?? '24h',
      rawProbability: (json['probability'] as num?)?.toDouble() ?? 0.5,
      confidence: (json['confidence'] as String?)?.toUpperCase() ?? 'MEDIUM',
      evidence: (json['evidence'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      events: (json['events'] as List<dynamic>?)
              ?.map((e) => ScenarioEventModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trajectory_type': trajectoryType,
      'title': title,
      'summary': summary,
      'horizon': horizon,
      'probability': rawProbability,
      'confidence': confidence,
      'evidence': evidence,
      'events': events.map((e) => e.toJson()).toList(),
    };
  }
}

/// Counterfactual Alternative Path
class CounterfactualModel {
  final String id;
  final String action;
  final String assumption;
  final String expectedEffect;

  const CounterfactualModel({
    required this.id,
    required this.action,
    required this.assumption,
    required this.expectedEffect,
  });

  factory CounterfactualModel.fromJson(Map<String, dynamic> json) {
    return CounterfactualModel(
      id: json['id'] as String? ?? '',
      action: json['action'] as String? ?? '',
      assumption: json['assumption'] as String? ?? '',
      expectedEffect: json['expected_effect'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'action': action,
      'assumption': assumption,
      'expected_effect': expectedEffect,
    };
  }
}

/// Full Counterfactual Simulation Result
class SimulationResponseModel {
  final FutureScenarioModel scenario;
  final CounterfactualModel? alternative;

  const SimulationResponseModel({
    required this.scenario,
    this.alternative,
  });

  factory SimulationResponseModel.fromJson(Map<String, dynamic> json) {
    return SimulationResponseModel(
      scenario: json['scenario'] is Map<String, dynamic>
          ? FutureScenarioModel.fromJson(json['scenario'] as Map<String, dynamic>)
          : const FutureScenarioModel(
              id: '',
              trajectoryType: 'CURRENT',
              title: 'Default Simulation',
              summary: 'Simulation data unavailable',
              horizon: '24h',
              rawProbability: 0.5,
              confidence: 'MEDIUM',
              evidence: [],
              events: [],
            ),
      alternative: json['alternative'] is Map<String, dynamic>
          ? CounterfactualModel.fromJson(json['alternative'] as Map<String, dynamic>)
          : null,
    );
  }
}
