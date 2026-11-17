/// Model representing a TESS Conversation thread from FastAPI backend.
class ConversationModel {
  final String id;
  final String userId;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ConversationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory constructor to parse backend JSON response
  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      title: (json['title'] as String?)?.isNotEmpty == true
          ? json['title'] as String
          : 'New Conversation',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Formatted date string for UI display
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(updatedAt);

    if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return mins <= 1 ? 'Just now' : '${mins}m ago';
    } else if (difference.inHours < 24 && now.day == updatedAt.day) {
      final hour = updatedAt.hour.toString().padLeft(2, '0');
      final minute = updatedAt.minute.toString().padLeft(2, '0');
      return 'Today at $hour:$minute';
    } else {
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final month = months[updatedAt.month - 1];
      return '$month ${updatedAt.day}';
    }
  }

  ConversationModel copyWith({
    String? id,
    String? userId,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

