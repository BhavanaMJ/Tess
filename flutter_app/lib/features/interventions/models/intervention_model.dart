/// Model representing an actionable proactive recommendation from TESS Intervention Engine
class InterventionModel {
  final String id;
  final String userId;
  final String type; // e.g. 'SCHEDULE_WARNING', 'BREAK_SUGGESTION', 'PRIORITY_REALIGNMENT'
  final String priority; // 'LOW', 'MEDIUM', 'HIGH', 'CRITICAL'
  final String title;
  final String message;
  final String? reason;
  final double valueScore; // e.g. 0.0 to 10.0
  final String status; // 'SENT', 'ACTED', 'DEFERRED', 'DISMISSED'
  final DateTime createdAt;
  final DateTime? sentAt;
  final DateTime? deferredUntil;
  final String? predictionId;

  const InterventionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.priority,
    required this.title,
    required this.message,
    this.reason,
    required this.valueScore,
    required this.status,
    required this.createdAt,
    this.sentAt,
    this.deferredUntil,
    this.predictionId,
  });

  bool get isPending => status.toUpperCase() == 'SENT';
  bool get isActed => status.toUpperCase() == 'ACTED';
  bool get isDeferred => status.toUpperCase() == 'DEFERRED';
  bool get isDismissed => status.toUpperCase() == 'DISMISSED';

  bool get isCritical => priority.toUpperCase() == 'CRITICAL';
  bool get isHighPriority => priority.toUpperCase() == 'HIGH' || isCritical;

  String get formattedValueScore => 'Value: ${valueScore.toStringAsFixed(1)} / 10';

  String get formattedTime {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    if (diff.inMinutes < 60) {
      final mins = diff.inMinutes;
      return mins <= 1 ? 'Just now' : '${mins}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  factory InterventionModel.fromJson(Map<String, dynamic> json) {
    return InterventionModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      type: (json['type'] as String?)?.toUpperCase() ?? 'RECOMMENDATION',
      priority: (json['priority'] as String?)?.toUpperCase() ?? 'MEDIUM',
      title: json['title'] as String? ?? 'Proactive Recommendation',
      message: json['message'] as String? ?? '',
      reason: json['reason'] as String?,
      valueScore: (json['value_score'] as num?)?.toDouble() ?? 5.0,
      status: (json['status'] as String?)?.toUpperCase() ?? 'SENT',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      sentAt: json['sent_at'] != null
          ? DateTime.tryParse(json['sent_at'].toString())
          : null,
      deferredUntil: json['deferred_until'] != null
          ? DateTime.tryParse(json['deferred_until'].toString())
          : null,
      predictionId: json['prediction_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'priority': priority,
      'title': title,
      'message': message,
      'reason': reason,
      'value_score': valueScore,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'sent_at': sentAt?.toIso8601String(),
      'deferred_until': deferredUntil?.toIso8601String(),
      'prediction_id': predictionId,
    };
  }

  InterventionModel copyWith({
    String? id,
    String? userId,
    String? type,
    String? priority,
    String? title,
    String? message,
    String? reason,
    double? valueScore,
    String? status,
    DateTime? createdAt,
    DateTime? sentAt,
    DateTime? deferredUntil,
    String? predictionId,
  }) {
    return InterventionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      title: title ?? this.title,
      message: message ?? this.message,
      reason: reason ?? this.reason,
      valueScore: valueScore ?? this.valueScore,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      sentAt: sentAt ?? this.sentAt,
      deferredUntil: deferredUntil ?? this.deferredUntil,
      predictionId: predictionId ?? this.predictionId,
    );
  }
}
