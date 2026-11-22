import '../../domain/entities/laundry_batch.dart';
import '../../domain/entities/laundry_batch_item.dart';

class LaundryBatchItemModel {
  final String id;
  final String batchId;
  final String garmentId;
  final String? garmentName;
  final String? garmentCategory;
  final String? currentLaundryStatus;
  final String? thumbnailRef;
  final String status;
  final DateTime addedAt;

  const LaundryBatchItemModel({
    required this.id,
    required this.batchId,
    required this.garmentId,
    this.garmentName,
    this.garmentCategory,
    this.currentLaundryStatus,
    this.thumbnailRef,
    this.status = 'ACTIVE',
    required this.addedAt,
  });

  factory LaundryBatchItemModel.fromJson(Map<String, dynamic> json) {
    return LaundryBatchItemModel(
      id: json['id'] as String? ?? '',
      batchId: json['batch_id'] as String? ?? '',
      garmentId: json['garment_id'] as String? ?? '',
      garmentName: json['garment_name'] as String?,
      garmentCategory: json['garment_category'] as String?,
      currentLaundryStatus: json['current_laundry_status'] as String?,
      thumbnailRef: json['thumbnail_ref'] as String?,
      status: json['status'] as String? ?? 'ACTIVE',
      addedAt: json['added_at'] != null
          ? DateTime.tryParse(json['added_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'batch_id': batchId,
      'garment_id': garmentId,
      'garment_name': garmentName,
      'garment_category': garmentCategory,
      'current_laundry_status': currentLaundryStatus,
      'thumbnail_ref': thumbnailRef,
      'status': status,
      'added_at': addedAt.toIso8601String(),
    };
  }

  LaundryBatchItem toDomain() {
    return LaundryBatchItem(
      id: id,
      batchId: batchId,
      garmentId: garmentId,
      garmentName: garmentName,
      garmentCategory: garmentCategory,
      currentLaundryStatus: currentLaundryStatus,
      thumbnailRef: thumbnailRef,
      status: status,
      addedAt: addedAt,
    );
  }
}

class LaundryBatchModel {
  final String id;
  final String userId;
  final String batchNumber;
  final String name;
  final String status;
  final String? notes;
  final int itemsCount;
  final List<LaundryBatchItemModel> items;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  const LaundryBatchModel({
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

  factory LaundryBatchModel.fromJson(Map<String, dynamic> json) {
    List<LaundryBatchItemModel> itemsList = [];
    if (json['items'] is List) {
      itemsList = (json['items'] as List)
          .map((i) => LaundryBatchItemModel.fromJson(i as Map<String, dynamic>))
          .toList();
    }

    return LaundryBatchModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      batchNumber: json['batch_number'] as String? ?? 'BATCH-001',
      name: json['name'] as String? ?? 'Laundry Batch',
      status: json['status'] as String? ?? 'CREATED',
      notes: json['notes'] as String?,
      itemsCount: (json['items_count'] as num?)?.toInt() ?? itemsList.length,
      items: itemsList,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'batch_number': batchNumber,
      'name': name,
      'status': status,
      'notes': notes,
      'items_count': itemsCount,
      'items': items.map((i) => i.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  LaundryBatch toDomain() {
    return LaundryBatch(
      id: id,
      userId: userId,
      batchNumber: batchNumber,
      name: name,
      status: status,
      notes: notes,
      itemsCount: itemsCount,
      items: items.map((i) => i.toDomain()).toList(),
      createdAt: createdAt,
      updatedAt: updatedAt,
      completedAt: completedAt,
    );
  }
}
