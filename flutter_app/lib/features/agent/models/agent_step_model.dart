import 'action_confirmation_model.dart';

/// Model representing a single atomic step inside an Agent Plan.
class AgentStepModel {
  final String id;
  final String planId;
  final int stepOrder;
  final String toolName;
  final String actionType;
  final Map<String, dynamic> parameters;
  final String riskLevel; // LOW, MEDIUM, HIGH
  final String status; // PENDING, RUNNING, SUCCESS, FAILED
  final DateTime? createdAt;
  final DateTime? completedAt;
  final dynamic result;
  final ActionConfirmationModel? confirmation;

  const AgentStepModel({
    required this.id,
    required this.planId,
    required this.stepOrder,
    required this.toolName,
    required this.actionType,
    required this.parameters,
    required this.riskLevel,
    required this.status,
    this.createdAt,
    this.completedAt,
    this.result,
    this.confirmation,
  });

  factory AgentStepModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      try {
        return DateTime.parse(val.toString()).toUtc();
      } catch (_) {
        return null;
      }
    }

    ActionConfirmationModel? conf;
    if (json['confirmation'] != null && json['confirmation'] is Map<String, dynamic>) {
      conf = ActionConfirmationModel.fromJson(json['confirmation'] as Map<String, dynamic>);
    }

    Map<String, dynamic> params = {};
    if (json['parameters'] != null && json['parameters'] is Map) {
      params = Map<String, dynamic>.from(json['parameters'] as Map);
    }

    return AgentStepModel(
      id: json['id']?.toString() ?? '',
      planId: json['plan_id']?.toString() ?? '',
      stepOrder: json['step_order'] is int ? json['step_order'] as int : int.tryParse(json['step_order']?.toString() ?? '1') ?? 1,
      toolName: json['tool_name']?.toString() ?? '',
      actionType: json['action_type']?.toString() ?? '',
      parameters: params,
      riskLevel: (json['risk_level']?.toString() ?? 'LOW').toUpperCase(),
      status: (json['status']?.toString() ?? 'PENDING').toUpperCase(),
      createdAt: parseDate(json['created_at']),
      completedAt: parseDate(json['completed_at']),
      result: json['result'],
      confirmation: conf,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plan_id': planId,
      'step_order': stepOrder,
      'tool_name': toolName,
      'action_type': actionType,
      'parameters': parameters,
      'risk_level': riskLevel,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'result': result,
      'confirmation': confirmation?.toJson(),
    };
  }

  bool get requiresConfirmation => riskLevel == 'MEDIUM' || riskLevel == 'HIGH';

  bool get isConfirmed {
    if (!requiresConfirmation) return true;
    return confirmation?.isConfirmed == true;
  }

  bool get isPendingConfirmation {
    if (!requiresConfirmation) return false;
    return confirmation?.isPending == true;
  }

  /// Safe parameter view that strips out any sensitive keys
  Map<String, dynamic> get safeParameters {
    const sensitiveKeys = {'token', 'secret', 'password', 'api_key', 'auth', 'bearer'};
    final safe = <String, dynamic>{};
    parameters.forEach((key, value) {
      final lowerKey = key.toLowerCase();
      if (!sensitiveKeys.any((s) => lowerKey.contains(s))) {
        safe[key] = value;
      }
    });
    return safe;
  }

  /// Target resource description deduced from tool parameters
  String get targetResource {
    if (parameters.containsKey('task_id')) {
      return 'Task #${parameters['task_id']}';
    }
    if (parameters.containsKey('url')) {
      return parameters['url'].toString();
    }
    if (parameters.containsKey('file_path')) {
      return parameters['file_path'].toString();
    }
    if (parameters.containsKey('target_path')) {
      return parameters['target_path'].toString();
    }
    if (parameters.containsKey('to')) {
      return 'Recipient: ${parameters['to']}';
    }
    if (toolName.contains('calendar')) {
      return 'Google Calendar';
    }
    return toolName.replaceAll('_', ' ').toUpperCase();
  }

  /// Human-readable display label for the action
  String get actionDisplayName {
    if (actionType.isNotEmpty) {
      return actionType.replaceAll('_', ' ');
    }
    return toolName.replaceAll('_', ' ').toUpperCase();
  }
}
