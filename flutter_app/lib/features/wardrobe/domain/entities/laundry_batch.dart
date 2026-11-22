import 'laundry_batch_item.dart';

/// Represents a multi-garment laundry batch with full lifecycle state.
class LaundryBatch {
  final String id;
  final String userId;
  final String batchNumber; // e.g. "BATCH-001"
  final String name;
  final String
      status; // 'CREATED', 'WASHING', 'DRYING', 'COMPLETED', 'CANCELLED'
  final String? notes;
  final int itemsCount;
  final List<LaundryBatchItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  const LaundryBatch({
    required this.id,
    required this.userId,
    required this.batchNumber,
    required this.name,
    required this.status,
    this.notes,
    this.itemsCount = 0,
    this.items = const [],
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  bool get isCreated => status == 'CREATED';
  bool get isWashing => status == 'WASHING';
  bool get isDrying => status == 'DRYING';
  bool get isCompleted => status == 'COMPLETED';
  bool get isCancelled => status == 'CANCELLED';
  bool get isActive => !isCompleted && !isCancelled;

  LaundryBatch copyWith({
    String? id,
    String? userId,
    String? batchNumber,
    String? name,
    String? status,
    String? notes,
    int? itemsCount,
    List<LaundryBatchItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) {
    return LaundryBatch(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      batchNumber: batchNumber ?? this.batchNumber,
      name: name ?? this.name,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      itemsCount: itemsCount ?? this.itemsCount,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
