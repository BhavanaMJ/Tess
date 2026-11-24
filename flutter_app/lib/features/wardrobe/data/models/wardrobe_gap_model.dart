import '../../domain/entities/wardrobe_gap.dart';

class WardrobeGapModel extends WardrobeGap {
  const WardrobeGapModel({
    required super.id,
    required super.title,
    required super.category,
    super.suggestedSubcategory,
    super.suggestedColor,
    required super.supportingEvidence,
    required super.currentInventoryCount,
    super.compatibleExistingGarmentIds = const [],
    super.compatibleExistingGarmentNames = const [],
    required super.potentialOutfitCombinationsGained,
    required super.explanation,
    required super.confidenceScore,
    required super.severity,
  });

  factory WardrobeGapModel.fromJson(Map<String, dynamic> json) {
    return WardrobeGapModel(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      suggestedSubcategory: json['suggested_subcategory'] as String?,
      suggestedColor: json['suggested_color'] as String?,
      supportingEvidence: json['supporting_evidence'] as String,
      currentInventoryCount: (json['current_inventory_count'] as num).toInt(),
      compatibleExistingGarmentIds: (json['compatible_existing_garment_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      compatibleExistingGarmentNames: (json['compatible_existing_garment_names'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      potentialOutfitCombinationsGained:
          (json['potential_outfit_combinations_gained'] as num).toInt(),
      explanation: json['explanation'] as String,
      confidenceScore: (json['confidence_score'] as num).toDouble(),
      severity: GapSeverity.fromString(json['severity'] as String? ?? 'MEDIUM'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'suggested_subcategory': suggestedSubcategory,
      'suggested_color': suggestedColor,
      'supporting_evidence': supportingEvidence,
      'current_inventory_count': currentInventoryCount,
      'compatible_existing_garment_ids': compatibleExistingGarmentIds,
      'compatible_existing_garment_names': compatibleExistingGarmentNames,
      'potential_outfit_combinations_gained': potentialOutfitCombinationsGained,
      'explanation': explanation,
      'confidence_score': confidenceScore,
      'severity': severity.name.toUpperCase(),
    };
  }
}
