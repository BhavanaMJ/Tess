import 'base_entity.dart';

/// Task Priority Enumeration
enum TaskPriority { high, medium, low }

/// Extension methods provide extra capability to existing enums/classes
/// without modifying their core definition.
extension TaskPriorityExtension on TaskPriority {
  String get code {
    switch (this) {
      case TaskPriority.high:
        return 'P1';
      case TaskPriority.medium:
        return 'P2';
      case TaskPriority.low:
        return 'P3';
    }
  }

  String get label {
    switch (this) {
      case TaskPriority.high:
        return 'High Priority';
      case TaskPriority.medium:
        return 'Medium Priority';
      case TaskPriority.low:
        return 'Low Priority';
    }
  }
}

/// Task Model representing an actionable objective in TESS.
/// Demonstrates:
/// - Inheritance: extends BaseEntity
/// - Interface implementation: implements Displayable
/// - Encapsulation: private variable `_isCompleted` with getter/setter
/// - Named constructors: `Task.create(...)`
class Task extends BaseEntity implements Displayable {
  final String title;
  final String category;
  final TaskPriority priority;
  bool isCompleted;

  Task({
    required super.id,
    required this.title,
    required this.category,
    this.priority = TaskPriority.medium,
    this.isCompleted = false,
    super.createdAt,
  });

  /// Named Constructor for creating a brand new task with automatic ID generation.
  Task.create({
    required this.title,
    required this.category,
    this.priority = TaskPriority.medium,
  })  : isCompleted = false,
        super(id: 'task_${DateTime.now().millisecondsSinceEpoch}');

  /// Named Factory Constructor: Deserializes JSON Map into a Task instance.
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      priority: TaskPriority.values.firstWhere(
        (p) => p.name == json['priority'],
        orElse: () => TaskPriority.medium,
      ),
      isCompleted: json['isCompleted'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  /// Toggle task completion status
  void toggleCompletion() {
    isCompleted = !isCompleted;
  }

  // Implementation of Displayable interface
  @override
  String get displayTitle => title;

  @override
  String get displaySubtitle => '${priority.code} • $category';

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'priority': priority.name,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Immutable copy method (common Dart/Flutter pattern for updating state)
  Task copyWith({
    String? title,
    String? category,
    TaskPriority? priority,
    bool? isCompleted,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
    );
  }
}
