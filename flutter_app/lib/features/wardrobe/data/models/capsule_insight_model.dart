import '../../domain/entities/capsule_insight.dart';

class CapsuleGarmentInsightModel {
  final String garmentId;
  final String garmentName;
  final String mainCategory;
  final String primaryColor;
  final String? thumbnailRef;
  final int compatiblePairingsCount;
  final double versatilityScore;
  final bool isCapsuleAnchor;

  CapsuleGarmentInsightModel({
    required this.garmentId,
    required this.garmentName,
    required this.mainCategory,
    required this.primaryColor,
    this.thumbnailRef,
    required this.compatiblePairingsCount,
    required this.versatilityScore,
    required this.isCapsuleAnchor,
  });

  factory CapsuleGarmentInsightModel.fromJson(Map<String, dynamic> json) {
    return CapsuleGarmentInsightModel(
      garmentId: json['garment_id'] ?? '',
      garmentName: json['garment_name'] ?? 'Unnamed',
      mainCategory: json['main_category'] ?? 'Tops',
      primaryColor: json['primary_color'] ?? 'Unknown',
      thumbnailRef: json['thumbnail_ref'],
      compatiblePairingsCount: json['compatible_pairings_count'] ?? 0,
      versatilityScore: (json['versatility_score'] as num?)?.toDouble() ?? 0.0,
      isCapsuleAnchor: json['is_capsule_anchor'] ?? false,
    );
  }

  CapsuleGarmentInsight toDomain() {
    return CapsuleGarmentInsight(
      garmentId: garmentId,
      garmentName: garmentName,
      mainCategory: mainCategory,
      primaryColor: primaryColor,
      thumbnailRef: thumbnailRef,
      compatiblePairingsCount: compatiblePairingsCount,
      versatilityScore: versatilityScore,
      isCapsuleAnchor: isCapsuleAnchor,
    );
  }
}

class CapsuleWardrobeSummaryModel {
  final int totalActiveGarments;
  final int capsuleReadyGarmentsCount;
  final double averageVersatilityScore;
  final List<CapsuleGarmentInsightModel> anchorGarments;
  final int potentialOutfitCombinations;

  CapsuleWardrobeSummaryModel({
    required this.totalActiveGarments,
    required this.capsuleReadyGarmentsCount,
    required this.averageVersatilityScore,
    required this.anchorGarments,
    required this.potentialOutfitCombinations,
  });

  factory CapsuleWardrobeSummaryModel.fromJson(Map<String, dynamic> json) {
    return CapsuleWardrobeSummaryModel(
      totalActiveGarments: json['total_active_garments'] ?? 0,
      capsuleReadyGarmentsCount: json['capsule_ready_garments_count'] ?? 0,
      averageVersatilityScore: (json['average_versatility_score'] as num?)?.toDouble() ?? 0.0,
      anchorGarments: (json['anchor_garments'] as List<dynamic>?)
              ?.map((e) => CapsuleGarmentInsightModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      potentialOutfitCombinations: json['potential_outfit_combinations'] ?? 0,
    );
  }

  CapsuleWardrobeSummary toDomain() {
    return CapsuleWardrobeSummary(
      totalActiveGarments: totalActiveGarments,
      capsuleReadyGarmentsCount: capsuleReadyGarmentsCount,
      averageVersatilityScore: averageVersatilityScore,
      anchorGarments: anchorGarments.map((e) => e.toDomain()).toList(),
      potentialOutfitCombinations: potentialOutfitCombinations,
    );
  }
}
