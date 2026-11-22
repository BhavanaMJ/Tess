/// Operational Telemetry Stats for Wardrobe Intelligence.
class WardrobeStats {
  final int totalGarments;
  final int cleanCount;
  final int wornCount;
  final int inLaundryCount;
  final int storedCount;
  final int unassignedCount;

  const WardrobeStats({
    this.totalGarments = 0,
    this.cleanCount = 0,
    this.wornCount = 0,
    this.inLaundryCount = 0,
    this.storedCount = 0,
    this.unassignedCount = 0,
  });

  factory WardrobeStats.fromGarments(List<dynamic> garments) {
    int total = garments.length;
    int clean = 0;
    int worn = 0;
    int inLaundry = 0;
    int stored = 0;
    int unassigned = 0;

    for (final g in garments) {
      final status = g.laundryStatus?.value ?? g.laundryStatus;
      if (status == 'CLEAN') {
        clean++;
      } else if (status == 'WORN') {
        worn++;
      } else if (status == 'WASHING' || status == 'DRYING') {
        inLaundry++;
      } else if (status == 'STORED') {
        stored++;
      } else {
        unassigned++;
      }
    }

    return WardrobeStats(
      totalGarments: total,
      cleanCount: clean,
      wornCount: worn,
      inLaundryCount: inLaundry,
      storedCount: stored,
      unassignedCount: unassigned,
    );
  }
}
