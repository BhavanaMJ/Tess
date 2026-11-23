import 'insights_period.dart';

/// Reason why a garment is flagged as neglected or underutilized.
enum NeglectReason {
  neverRecorded,
  notWornRecently,
  rarelyWorn,
  recentlyAdded,
  insufficientData,
}

extension NeglectReasonExtension on NeglectReason {
  String get label {
    switch (this) {
      case NeglectReason.neverRecorded:
        return 'Never Worn';
      case NeglectReason.notWornRecently:
        return 'Not Worn Recently (>60d)';
      case NeglectReason.rarelyWorn:
        return 'Rarely Worn (<=2 wears)';
      case NeglectReason.recentlyAdded:
        return 'Recently Added (<14d)';
      case NeglectReason.insufficientData:
        return 'Low Wear Data';
    }
  }
}

/// Type of intelligent recommendation.
enum RecommendationType {
  reviveNeglected,
  newCombination,
  highWearFavorite,
  categoryBalance,
}

/// Wardrobe Overview and High-Level Telemetry.
class WardrobeOverview {
  final AnalyticsPeriod period;
  final DateTime? startDate;
  final DateTime? endDate;
  final int totalActiveGarments;
  final int totalArchivedGarments;
  final int totalWornGarmentsInPeriod;
  final int uniqueGarmentsWornInPeriod;
  final double utilisationPercentage;
  final int cleanGarmentsCount;
  final int inLaundryCount;
  final int neverWornCount;
  final int totalOutfitsWornInPeriod;
  final double totalInvestment;
  final double? averageCostPerWear;
  final String currency;

  const WardrobeOverview({
    required this.period,
    this.startDate,
    this.endDate,
    required this.totalActiveGarments,
    required this.totalArchivedGarments,
    required this.totalWornGarmentsInPeriod,
    required this.uniqueGarmentsWornInPeriod,
    required this.utilisationPercentage,
    required this.cleanGarmentsCount,
    required this.inLaundryCount,
    required this.neverWornCount,
    required this.totalOutfitsWornInPeriod,
    required this.totalInvestment,
    this.averageCostPerWear,
    this.currency = 'INR',
  });
}

/// Breakdown of wardrobe garments by category.
class CategoryDistribution {
  final String category;
  final int count;
  final double percentageOfWardrobe;
  final int activeCount;
  final int wornInPeriodCount;

  const CategoryDistribution({
    required this.category,
    required this.count,
    required this.percentageOfWardrobe,
    required this.activeCount,
    this.wornInPeriodCount = 0,
  });
}

/// Garment usage entity for top/least worn and neglected pieces.
class GarmentUsage {
  final String garmentId;
  final String garmentName;
  final String mainCategory;
  final String primaryColor;
  final String? thumbnailRef;
  final int wearCount;
  final DateTime? lastWornDate;
  final double? purchasePrice;
  final String purchaseCurrency;
  final double? costPerWear;
  final NeglectReason? neglectReason;
  final String? laundryStatus;

  const GarmentUsage({
    required this.garmentId,
    required this.garmentName,
    required this.mainCategory,
    required this.primaryColor,
    this.thumbnailRef,
    required this.wearCount,
    this.lastWornDate,
    this.purchasePrice,
    this.purchaseCurrency = 'INR',
    this.costPerWear,
    this.neglectReason,
    this.laundryStatus,
  });
}

/// Distribution across canonical color families.
class ColourDistribution {
  final String colorGroup;
  final List<String> originalColors;
  final int count;
  final double percentage;

  const ColourDistribution({
    required this.colorGroup,
    required this.originalColors,
    required this.count,
    required this.percentage,
  });
}

/// Detailed usage metrics for a specific category.
class CategoryUsage {
  final String category;
  final int totalGarments;
  final int wearCount;
  final int uniqueGarmentsWorn;
  final double utilisationPercentage;

  const CategoryUsage({
    required this.category,
    required this.totalGarments,
    required this.wearCount,
    required this.uniqueGarmentsWorn,
    required this.utilisationPercentage,
  });
}

/// Repeated outfit combination entity.
class OutfitRepetition {
  final String outfitId;
  final String outfitName;
  final int wearCount;
  final List<String> garmentNames;
  final List<String> garmentIds;
  final DateTime? lastWornDate;
  final double? averageIntervalDays;
  final String occasion;

  const OutfitRepetition({
    required this.outfitId,
    required this.outfitName,
    required this.wearCount,
    required this.garmentNames,
    required this.garmentIds,
    this.lastWornDate,
    this.averageIntervalDays,
    this.occasion = 'Casual',
  });
}

/// Actionable wardrobe styling recommendation.
class WardrobeRecommendation {
  final String id;
  final RecommendationType type;
  final String title;
  final String description;
  final List<String> garmentIds;
  final List<String> garmentNames;
  final String suggestedAction;
  final double confidenceScore;

  const WardrobeRecommendation({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.garmentIds,
    required this.garmentNames,
    required this.suggestedAction,
    required this.confidenceScore,
  });
}
