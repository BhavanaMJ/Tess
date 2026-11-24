/// Outcome of a Purchase Decision Assessment
enum AssessmentOutcome {
  strongAddition,
  potentiallyUseful,
  considerAlternatives,
  insufficientInfo;

  static AssessmentOutcome fromString(String val) {
    switch (val.toUpperCase()) {
      case 'STRONG_ADDITION':
        return AssessmentOutcome.strongAddition;
      case 'CONSIDER_ALTERNATIVES':
        return AssessmentOutcome.considerAlternatives;
      case 'INSUFFICIENT_INFO':
        return AssessmentOutcome.insufficientInfo;
      case 'POTENTIALLY_USEFUL':
      default:
        return AssessmentOutcome.potentiallyUseful;
    }
  }

  String get displayName {
    switch (this) {
      case AssessmentOutcome.strongAddition:
        return 'Strong Wardrobe Addition';
      case AssessmentOutcome.potentiallyUseful:
        return 'Potentially Useful';
      case AssessmentOutcome.considerAlternatives:
        return 'Consider Alternatives';
      case AssessmentOutcome.insufficientInfo:
        return 'Insufficient Info';
    }
  }
}

/// Match type between a prospective purchase and existing garments
enum GarmentMatchType {
  exactColorAndCategory,
  sameCategory,
  similarFunction;

  static GarmentMatchType fromString(String val) {
    switch (val.toUpperCase()) {
      case 'EXACT_COLOR_AND_CATEGORY':
        return GarmentMatchType.exactColorAndCategory;
      case 'SIMILAR_FUNCTION':
        return GarmentMatchType.similarFunction;
      case 'SAME_CATEGORY':
      default:
        return GarmentMatchType.sameCategory;
    }
  }

  String get displayName {
    switch (this) {
      case GarmentMatchType.exactColorAndCategory:
        return 'Exact Match';
      case GarmentMatchType.sameCategory:
        return 'Same Category';
      case GarmentMatchType.similarFunction:
        return 'Similar Function';
    }
  }
}

/// An existing garment in the user's wardrobe that is similar to a prospective purchase.
class GarmentMatch {
  final String garmentId;
  final String garmentName;
  final String mainCategory;
  final String? subcategory;
  final String primaryColor;
  final String? imageUrl;
  final String similarityReason;
  final GarmentMatchType matchType;

  const GarmentMatch({
    required this.garmentId,
    required this.garmentName,
    required this.mainCategory,
    this.subcategory,
    required this.primaryColor,
    this.imageUrl,
    required this.similarityReason,
    required this.matchType,
  });
}

/// Explainable decision assessment evaluating whether a wishlist purchase is justified.
class PurchaseAssessment {
  final String wishlistItemId;
  final String wishlistItemName;
  final AssessmentOutcome outcome;
  final String headline;
  final String explanation;
  final List<GarmentMatch> existingSimilarGarments;
  final bool hasSimilarOwned;
  final bool fillsCategoryGap;
  final bool fillsColourGap;
  final int compatiblePiecesCount;
  final int potentialNewCombinations;
  final double? assessmentScore;
  final List<String> contributingFactors;
  final String recommendationAction;

  const PurchaseAssessment({
    required this.wishlistItemId,
    required this.wishlistItemName,
    required this.outcome,
    required this.headline,
    required this.explanation,
    this.existingSimilarGarments = const [],
    required this.hasSimilarOwned,
    required this.fillsCategoryGap,
    required this.fillsColourGap,
    required this.compatiblePiecesCount,
    required this.potentialNewCombinations,
    this.assessmentScore,
    this.contributingFactors = const [],
    required this.recommendationAction,
  });
}
