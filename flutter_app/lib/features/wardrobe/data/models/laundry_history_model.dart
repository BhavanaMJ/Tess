import '../../domain/entities/laundry_history_entry.dart';

class LaundryHistoryEntryModel {
  final String id;
  final String userId;
  final String garmentId;
  final String? batchId;
  final String eventType;
  final String? previousStatus;
  final String? newStatus;
  final String source;
  final String? notes;
  final DateTime createdAt;

  const LaundryHistoryEntryModel({
    required this.id,
    required this.userId,
    required this.garmentId,
    this.batchId,
    required this.eventType,
    this.previousStatus,
    this.newStatus,
    this.source = 'MANUAL',
    this.notes,
    required this.createdAt,
  });

  factory LaundryHistoryEntryModel.fromJson(Map<String, dynamic> json) {
    return LaundryHistoryEntryModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      garmentId: json['garment_id'] as String? ?? '',
      batchId: json['batch_id'] as String?,
      eventType: json['event_type'] as String? ?? 'STATUS_CHANGE',
      previousStatus: json['previous_status'] as String?,
      newStatus: json['new_status'] as String?,
      source: json['source'] as String? ?? 'MANUAL',
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'garment_id': garmentId,
      'batch_id': batchId,
      'event_type': eventType,
      'previous_status': previousStatus,
      'new_status': newStatus,
      'source': source,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  LaundryHistoryEntry toDomain() {
    return LaundryHistoryEntry(
      id: id,
      userId: userId,
      garmentId: garmentId,
      batchId: batchId,
      eventType: eventType,
      previousStatus: previousStatus,
      newStatus: newStatus,
      source: source,
      notes: notes,
      createdAt: createdAt,
    );
  }
}
