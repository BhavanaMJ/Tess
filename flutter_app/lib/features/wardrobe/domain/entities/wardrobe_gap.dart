/// Severity of an identified wardrobe gap
enum GapSeverity {
  high,
  medium,
  low;

  static GapSeverity fromString(String val) {
    switch (val.toUpperCase()) {
      case 'HIGH':
        return GapSeverity.high;
      case 'LOW':
        return GapSeverity.low;
      case 'MEDIUM':
      default:
        return GapSeverity.medium;
    }
  }

  String get displayName {
    switch (this) {
      case GapSeverity.high:
        return 'High Impact';
      case GapSeverity.medium:
        return 'Moderate Impact';
      case GapSeverity.low:
        return 'Fine Tuning';
    }
  }
}

/// Domain entity representing an empirical wardrobe gap detected by shopping intelligence.
class WardrobeGap {
  final String id;
  final String title;
  final String category;
  final String? suggestedSubcategory;
  final String? suggestedColor;
  final String supportingEvidence;
  final int currentInventoryCount;
  final List<String> compatibleExistingGarmentIds;
  final List<String> compatibleExistingGarmentNames;
  final int potentialOutfitCombinationsGained;
  final String explanation;
  final double confidenceScore;
  final GapSeverity severity;

  const WardrobeGap({
    required this.id,
    required this.title,
    required this.category,
    this.suggestedSubcategory,
    this.suggestedColor,
    required this.supportingEvidence,
    required this.currentInventoryCount,
    this.compatibleExistingGarmentIds = const [],
    this.compatibleExistingGarmentNames = const [],
    required this.potentialOutfitCombinationsGained,
    required this.explanation,
    required this.confidenceScore,
    required this.severity,
  });
}
