/// Represents an individual garment lifecycle event in its laundry history.
class LaundryHistoryEntry {
  final String id;
  final String userId;
  final String garmentId;
  final String? batchId;
  final String eventType; // 'STATUS_CHANGE', 'WEAR', 'WASH_CYCLE_STARTED', etc.
  final String? previousStatus;
  final String? newStatus;
  final String source;
  final String? notes;
  final DateTime createdAt;

  const LaundryHistoryEntry({
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
}
