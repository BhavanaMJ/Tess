/// Metrics summary for the Laundry Manager dashboard.
class LaundryStats {
  final int totalGarments;
  final int cleanCount;
  final int wornCount;
  final int washingCount;
  final int dryingCount;
  final int storedCount;
  final int unassignedCount;
  final int activeBatchesCount;

  const LaundryStats({
    this.totalGarments = 0,
    this.cleanCount = 0,
    this.wornCount = 0,
    this.washingCount = 0,
    this.dryingCount = 0,
    this.storedCount = 0,
    this.unassignedCount = 0,
    this.activeBatchesCount = 0,
  });

  int get totalInProcess => washingCount + dryingCount;
}
