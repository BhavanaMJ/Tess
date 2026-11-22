/// Represents a garment's membership within a laundry batch.
class LaundryBatchItem {
  final String id;
  final String batchId;
  final String garmentId;
  final String? garmentName;
  final String? garmentCategory;
  final String? currentLaundryStatus;
  final String? thumbnailRef;
  final String status; // 'ACTIVE', 'REMOVED', 'COMPLETED'
  final DateTime addedAt;

  const LaundryBatchItem({
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

  LaundryBatchItem copyWith({
    String? id,
    String? batchId,
    String? garmentId,
    String? garmentName,
    String? garmentCategory,
    String? currentLaundryStatus,
    String? thumbnailRef,
    String? status,
    DateTime? addedAt,
  }) {
    return LaundryBatchItem(
      id: id ?? this.id,
      batchId: batchId ?? this.batchId,
      garmentId: garmentId ?? this.garmentId,
      garmentName: garmentName ?? this.garmentName,
      garmentCategory: garmentCategory ?? this.garmentCategory,
      currentLaundryStatus: currentLaundryStatus ?? this.currentLaundryStatus,
      thumbnailRef: thumbnailRef ?? this.thumbnailRef,
      status: status ?? this.status,
      addedAt: addedAt ?? this.addedAt,
    );
  }
}
