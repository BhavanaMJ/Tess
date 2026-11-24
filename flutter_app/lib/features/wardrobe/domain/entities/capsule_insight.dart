/// Capsule Wardrobe Garment Versatility Insight.
class CapsuleGarmentInsight {
  final String garmentId;
  final String garmentName;
  final String mainCategory;
  final String primaryColor;
  final String? thumbnailRef;
  final int compatiblePairingsCount;
  final double versatilityScore; // 0 to 100
  final bool isCapsuleAnchor;

  const CapsuleGarmentInsight({
    required this.garmentId,
    required this.garmentName,
    required this.mainCategory,
    required this.primaryColor,
    this.thumbnailRef,
    required this.compatiblePairingsCount,
    required this.versatilityScore,
    required this.isCapsuleAnchor,
  });
}

/// Capsule Wardrobe Summary and Compatibility Analytics.
class CapsuleWardrobeSummary {
  final int totalActiveGarments;
  final int capsuleReadyGarmentsCount;
  final double averageVersatilityScore;
  final List<CapsuleGarmentInsight> anchorGarments;
  final int potentialOutfitCombinations;

  const CapsuleWardrobeSummary({
    required this.totalActiveGarments,
    required this.capsuleReadyGarmentsCount,
    required this.averageVersatilityScore,
    required this.anchorGarments,
    required this.potentialOutfitCombinations,
  });
}

