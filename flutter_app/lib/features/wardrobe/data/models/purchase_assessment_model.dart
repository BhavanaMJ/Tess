import '../../domain/entities/purchase_assessment.dart';

class GarmentMatchModel extends GarmentMatch {
  const GarmentMatchModel({
    required super.garmentId,
    required super.garmentName,
    required super.mainCategory,
    super.subcategory,
    required super.primaryColor,
    super.imageUrl,
    required super.similarityReason,
    required super.matchType,
  });

  factory GarmentMatchModel.fromJson(Map<String, dynamic> json) {
    return GarmentMatchModel(
      garmentId: json['garment_id'] as String,
      garmentName: json['garment_name'] as String,
      mainCategory: json['main_category'] as String,
      subcategory: json['subcategory'] as String?,
      primaryColor: json['primary_color'] as String,
      imageUrl: json['image_url'] as String?,
      similarityReason: json['similarity_reason'] as String,
      matchType: GarmentMatchType.fromString(
        json['match_type'] as String? ?? 'SAME_CATEGORY',
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'garment_id': garmentId,
      'garment_name': garmentName,
      'main_category': mainCategory,
      'subcategory': subcategory,
      'primary_color': primaryColor,
      'image_url': imageUrl,
      'similarity_reason': similarityReason,
      'match_type': matchType.name,
    };
  }
}

class PurchaseAssessmentModel extends PurchaseAssessment {
  const PurchaseAssessmentModel({
    required super.wishlistItemId,
    required super.wishlistItemName,
    required super.outcome,
    required super.headline,
    required super.explanation,
    super.existingSimilarGarments = const [],
    required super.hasSimilarOwned,
    required super.fillsCategoryGap,
    required super.fillsColourGap,
    required super.compatiblePiecesCount,
    required super.potentialNewCombinations,
    super.assessmentScore,
    super.contributingFactors = const [],
    required super.recommendationAction,
  });

  factory PurchaseAssessmentModel.fromJson(Map<String, dynamic> json) {
    return PurchaseAssessmentModel(
      wishlistItemId: json['wishlist_item_id'] as String,
      wishlistItemName: json['wishlist_item_name'] as String,
      outcome: AssessmentOutcome.fromString(
        json['outcome'] as String? ?? 'POTENTIALLY_USEFUL',
      ),
      headline: json['headline'] as String,
      explanation: json['explanation'] as String,
      existingSimilarGarments: (json['existing_similar_garments'] as List<dynamic>?)
              ?.map((e) => GarmentMatchModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      hasSimilarOwned: json['has_similar_owned'] as bool? ?? false,
      fillsCategoryGap: json['fills_category_gap'] as bool? ?? false,
      fillsColourGap: json['fills_colour_gap'] as bool? ?? false,
      compatiblePiecesCount: (json['compatible_pieces_count'] as num?)?.toInt() ?? 0,
      potentialNewCombinations:
          (json['potential_new_combinations'] as num?)?.toInt() ?? 0,
      assessmentScore: (json['assessment_score'] as num?)?.toDouble(),
      contributingFactors: (json['contributing_factors'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      recommendationAction: json['recommendation_action'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'wishlist_item_id': wishlistItemId,
      'wishlist_item_name': wishlistItemName,
      'outcome': outcome.name,
      'headline': headline,
      'explanation': explanation,
      'existing_similar_garments': existingSimilarGarments
          .map((e) => (e as GarmentMatchModel).toJson())
          .toList(),
      'has_similar_owned': hasSimilarOwned,
      'fills_category_gap': fillsCategoryGap,
      'fills_colour_gap': fillsColourGap,
      'compatible_pieces_count': compatiblePiecesCount,
      'potential_new_combinations': potentialNewCombinations,
      'assessment_score': assessmentScore,
      'contributing_factors': contributingFactors,
      'recommendation_action': recommendationAction,
    };
  }
}
