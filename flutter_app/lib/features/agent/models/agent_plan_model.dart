import 'agent_step_model.dart';

/// Model representing an Agent Action Plan containing sequential steps.
class AgentPlanModel {
  final String id;
  final String userId;
  final String objective;
  final String status; // PLANNING, READY, EXECUTING, SUCCESS, FAILED, CANCELLED
  final DateTime? createdAt;
  final DateTime? completedAt;
  final List<AgentStepModel> steps;

  const AgentPlanModel({
    required this.id,
    required this.userId,
    required this.objective,
    required this.status,
    this.createdAt,
    this.completedAt,
    this.steps = const [],
  });

  factory AgentPlanModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      try {
        return DateTime.parse(val.toString()).toUtc();
      } catch (_) {
        return null;
      }
    }

    final rawSteps = json['steps'];
    List<AgentStepModel> parsedSteps = [];
    if (rawSteps is List) {
      parsedSteps = rawSteps
          .whereType<Map<String, dynamic>>()
          .map((s) => AgentStepModel.fromJson(s))
          .toList();
    }

    return AgentPlanModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      objective: json['objective']?.toString() ?? '',
      status: (json['status']?.toString() ?? 'PLANNING').toUpperCase(),
      createdAt: parseDate(json['created_at']),
      completedAt: parseDate(json['completed_at']),
      steps: parsedSteps,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'objective': objective,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'steps': steps.map((s) => s.toJson()).toList(),
    };
  }

  AgentPlanModel copyWith({
    String? id,
    String? userId,
    String? objective,
    String? status,
    DateTime? createdAt,
    DateTime? completedAt,
    List<AgentStepModel>? steps,
  }) {
    return AgentPlanModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      objective: objective ?? this.objective,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      steps: steps ?? this.steps,
    );
  }

  int get totalSteps => steps.length;

  int get pendingConfirmationCount =>
      steps.where((s) => s.isPendingConfirmation).length;

  bool get hasPendingConfirmation => pendingConfirmationCount > 0;

  bool get hasExpiredConfirmation =>
      steps.any((s) => s.confirmation?.isExpired == true);

  /// True if all steps either do not require confirmation or have confirmed status
  bool get allConfirmedOrLowRisk =>
      steps.isNotEmpty && steps.every((s) => !s.requiresConfirmation || s.isConfirmed);

  /// Executable only when status is READY and all required confirmations are granted
  bool get isExecutable =>
      (status == 'READY' || status == 'PENDING') && allConfirmedOrLowRisk;

  bool get isExecuting => status == 'EXECUTING';
  bool get isSuccess => status == 'SUCCESS';
  bool get isFailed => status == 'FAILED';
  bool get isCancelled => status == 'CANCELLED';
  bool get isTerminal => isSuccess || isFailed || isCancelled;

  String get formattedDate {
    if (createdAt == null) return 'Unknown Date';
    final dt = createdAt!.toLocal();
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} $h:$m';
  }
}
