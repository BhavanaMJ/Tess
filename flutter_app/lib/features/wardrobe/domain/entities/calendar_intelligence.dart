class RecentlyWornGarment {
  final String garmentId;
  final String garmentName;
  final String mainCategory;
  final String primaryColor;
  final String? thumbnailRef;
  final DateTime? lastWornDate;
  final int wearCount;

  const RecentlyWornGarment({
    required this.garmentId,
    required this.garmentName,
    required this.mainCategory,
    required this.primaryColor,
    this.thumbnailRef,
    this.lastWornDate,
    this.wearCount = 0,
  });
}

class UnusedGarment {
  final String garmentId;
  final String garmentName;
  final String mainCategory;
  final String primaryColor;
  final String? thumbnailRef;
  final DateTime? lastWornDate;
  final int wearCount;
  final String statusCategory;

  const UnusedGarment({
    required this.garmentId,
    required this.garmentName,
    required this.mainCategory,
    required this.primaryColor,
    this.thumbnailRef,
    this.lastWornDate,
    this.wearCount = 0,
    required this.statusCategory,
  });
}

class RepetitionCheck {
  final bool isRepeated;
  final String? message;
  final String? lastWornDate;
  final String? lastPlannedOrWornDate;
  final int? daysSince;
  final int repetitionCount;

  const RepetitionCheck({
    required this.isRepeated,
    this.message,
    this.lastWornDate,
    this.lastPlannedOrWornDate,
    this.daysSince,
    this.repetitionCount = 0,
  });
}
