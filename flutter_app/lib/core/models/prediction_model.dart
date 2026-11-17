import 'base_entity.dart';

/// Trajectory Classification Enum
enum TrajectoryType { optimal, risk, nominal }

/// Extension on TrajectoryType to provide helper methods and formatted labels
extension TrajectoryTypeExtension on TrajectoryType {
  String get label {
    switch (this) {
      case TrajectoryType.optimal:
        return 'OPTIMAL';
      case TrajectoryType.risk:
        return 'RISK DETECTED';
      case TrajectoryType.nominal:
        return 'BASELINE';
    }
  }

  bool get requiresIntervention => this == TrajectoryType.risk;
}

/// Prediction Model representing future projection branches computed by TESS Future Engine.
class Prediction extends BaseEntity implements Displayable {
  final String title;
  final String description;
  final double probabilityPercentage; // e.g. 88.0 for 88%
  final String projectedOutcome;
  final TrajectoryType trajectory;
  final String? interventionNote; // Nullable: only present when risk is detected

  Prediction({
    required super.id,
    required this.title,
    required this.description,
    required this.probabilityPercentage,
    required this.projectedOutcome,
    this.trajectory = TrajectoryType.nominal,
    this.interventionNote,
    super.createdAt,
  });

  /// Formatted probability string utilizing Dart string interpolation
  String get formattedProbability =>
      '${probabilityPercentage.toStringAsFixed(0)}% ${trajectory.label}';

  @override
  String get displayTitle => title;

  @override
  String get displaySubtitle => formattedProbability;

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'probabilityPercentage': probabilityPercentage,
      'projectedOutcome': projectedOutcome,
      'trajectory': trajectory.name,
      'interventionNote': interventionNote,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

