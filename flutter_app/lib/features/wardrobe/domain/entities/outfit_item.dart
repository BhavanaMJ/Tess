import 'laundry_status.dart';

/// Represents a garment's summary within an outfit or recommendation.
class OutfitItem {
  final String garmentId;
  final String name;
  final String mainCategory;
  final String primaryColor;
  final List<String> secondaryColors;
  final String? pattern;
  final String? originalImageRef;
  final String? processedImageRef;
  final String? thumbnailRef;
  final LaundryStatus? laundryStatus;
  final bool isEligible;
  final String? unavailabilityReason;

  const OutfitItem({
    required this.garmentId,
    required this.name,
    required this.mainCategory,
    required this.primaryColor,
    this.secondaryColors = const [],
    this.pattern,
    this.originalImageRef,
    this.processedImageRef,
    this.thumbnailRef,
    this.laundryStatus,
    this.isEligible = true,
    this.unavailabilityReason,
  });

  OutfitItem copyWith({
    String? garmentId,
    String? name,
    String? mainCategory,
    String? primaryColor,
    List<String>? secondaryColors,
    String? pattern,
    String? originalImageRef,
    String? processedImageRef,
    String? thumbnailRef,
    LaundryStatus? laundryStatus,
    bool? isEligible,
    String? unavailabilityReason,
  }) {
    return OutfitItem(
      garmentId: garmentId ?? this.garmentId,
      name: name ?? this.name,
      mainCategory: mainCategory ?? this.mainCategory,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColors: secondaryColors ?? this.secondaryColors,
      pattern: pattern ?? this.pattern,
      originalImageRef: originalImageRef ?? this.originalImageRef,
      processedImageRef: processedImageRef ?? this.processedImageRef,
      thumbnailRef: thumbnailRef ?? this.thumbnailRef,
      laundryStatus: laundryStatus ?? this.laundryStatus,
      isEligible: isEligible ?? this.isEligible,
      unavailabilityReason: unavailabilityReason ?? this.unavailabilityReason,
    );
  }
}

