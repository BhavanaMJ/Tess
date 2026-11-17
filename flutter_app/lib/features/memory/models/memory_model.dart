/// Model representing a Personal Memory entity in TESS.
/// Corresponds to backend `Memory` domain schema in FastAPI.
class MemoryModel {
  final String id;
  final String userId;
  final String category; // 'WORK', 'PERSONAL', 'PREFERENCE', 'HEALTH', 'PROJECT'
  final String content;
  final int importance; // 1 to 5
  final bool isConfirmed;
  final String provenance; // 'USER_STATED', 'INFERRED', etc.
  final DateTime createdAt;
  final DateTime updatedAt;

  const MemoryModel({
    required this.id,
    required this.userId,
    required this.category,
    required this.content,
    required this.importance,
    this.isConfirmed = true,
    this.provenance = 'USER_STATED',
    required this.createdAt,
    required this.updatedAt,
  });

  factory MemoryModel.fromJson(Map<String, dynamic> json) {
    return MemoryModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      category: (json['category'] as String?)?.toUpperCase() ?? 'GENERAL',
      content: json['content'] as String? ?? '',
      importance: (json['importance'] as num?)?.toInt() ?? 1,
      isConfirmed: json['is_confirmed'] as bool? ?? true,
      provenance: json['provenance'] as String? ?? 'USER_STATED',
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
      'category': category,
      'content': content,
      'importance': importance,
      'is_confirmed': isConfirmed,
      'provenance': provenance,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get formattedDate {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final month = months[createdAt.month - 1];
    return '$month ${createdAt.day}, ${createdAt.year}';
  }

  MemoryModel copyWith({
    String? id,
    String? userId,
    String? category,
    String? content,
    int? importance,
    bool? isConfirmed,
    String? provenance,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MemoryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      content: content ?? this.content,
      importance: importance ?? this.importance,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      provenance: provenance ?? this.provenance,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
