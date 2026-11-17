import 'simulation_model.dart';

/// Multiple Future Selves response comparing Current, Improved, and Alternative Trajectories
class MultipleFuturesModel {
  final String horizon;
  final FutureScenarioModel currentTrajectory;
  final FutureScenarioModel improvedTrajectory;
  final FutureScenarioModel alternativeTrajectory;

  const MultipleFuturesModel({
    required this.horizon,
    required this.currentTrajectory,
    required this.improvedTrajectory,
    required this.alternativeTrajectory,
  });

  factory MultipleFuturesModel.fromJson(Map<String, dynamic> json) {
    return MultipleFuturesModel(
      horizon: json['horizon'] as String? ?? '30d',
      currentTrajectory: json['current_trajectory'] is Map<String, dynamic>
          ? FutureScenarioModel.fromJson(json['current_trajectory'] as Map<String, dynamic>)
          : const FutureScenarioModel(
              id: 'curr_default',
              trajectoryType: 'CURRENT',
              title: 'Current Path',
              summary: 'Continuation of current pace',
              horizon: '30d',
              rawProbability: 0.6,
              confidence: 'MEDIUM',
              evidence: [],
              events: [],
            ),
      improvedTrajectory: json['improved_trajectory'] is Map<String, dynamic>
          ? FutureScenarioModel.fromJson(json['improved_trajectory'] as Map<String, dynamic>)
          : const FutureScenarioModel(
              id: 'imp_default',
              trajectoryType: 'IMPROVED',
              title: 'Optimized Path',
              summary: 'Adopting focused deep work habits',
              horizon: '30d',
              rawProbability: 0.8,
              confidence: 'HIGH',
              evidence: [],
              events: [],
            ),
      alternativeTrajectory: json['alternative_trajectory'] is Map<String, dynamic>
          ? FutureScenarioModel.fromJson(json['alternative_trajectory'] as Map<String, dynamic>)
          : const FutureScenarioModel(
              id: 'alt_default',
              trajectoryType: 'ALTERNATIVE',
              title: 'Alternative Path',
              summary: 'Pivoting task allocation',
              horizon: '30d',
              rawProbability: 0.5,
              confidence: 'MEDIUM',
              evidence: [],
              events: [],
            ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'horizon': horizon,
      'current_trajectory': currentTrajectory.toJson(),
      'improved_trajectory': improvedTrajectory.toJson(),
      'alternative_trajectory': alternativeTrajectory.toJson(),
    };
  }
}

