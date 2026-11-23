import '../../domain/entities/insights_period.dart';
import '../../domain/entities/wardrobe_insights.dart';

class WardrobeOverviewModel {
  final String period;
  final String? startDate;
  final String? endDate;
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

  WardrobeOverviewModel({
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

  factory WardrobeOverviewModel.fromJson(Map<String, dynamic> json) {
    return WardrobeOverviewModel(
      period: json['period'] ?? '30d',
      startDate: json['start_date'],
      endDate: json['end_date'],
      totalActiveGarments: json['total_active_garments'] ?? 0,
      totalArchivedGarments: json['total_archived_garments'] ?? 0,
      totalWornGarmentsInPeriod: json['total_worn_garments_in_period'] ?? 0,
      uniqueGarmentsWornInPeriod: json['unique_garments_worn_in_period'] ?? 0,
      utilisationPercentage: (json['utilisation_percentage'] as num?)?.toDouble() ?? 0.0,
      cleanGarmentsCount: json['clean_garments_count'] ?? 0,
      inLaundryCount: json['in_laundry_count'] ?? 0,
      neverWornCount: json['never_worn_count'] ?? 0,
      totalOutfitsWornInPeriod: json['total_outfits_worn_in_period'] ?? 0,
      totalInvestment: (json['total_investment'] as num?)?.toDouble() ?? 0.0,
      averageCostPerWear: (json['average_cost_per_wear'] as num?)?.toDouble(),
      currency: json['currency'] ?? 'INR',
    );
  }

  WardrobeOverview toDomain() {
    return WardrobeOverview(
      period: AnalyticsPeriodExtension.fromString(period),
      startDate: startDate != null ? DateTime.tryParse(startDate!) : null,
      endDate: endDate != null ? DateTime.tryParse(endDate!) : null,
      totalActiveGarments: totalActiveGarments,
      totalArchivedGarments: totalArchivedGarments,
      totalWornGarmentsInPeriod: totalWornGarmentsInPeriod,
      uniqueGarmentsWornInPeriod: uniqueGarmentsWornInPeriod,
      utilisationPercentage: utilisationPercentage,
      cleanGarmentsCount: cleanGarmentsCount,
      inLaundryCount: inLaundryCount,
      neverWornCount: neverWornCount,
      totalOutfitsWornInPeriod: totalOutfitsWornInPeriod,
      totalInvestment: totalInvestment,
      averageCostPerWear: averageCostPerWear,
      currency: currency,
    );
  }
}

class CategoryDistributionModel {
  final String category;
  final int count;
  final double percentageOfWardrobe;
  final int activeCount;
  final int wornInPeriodCount;

  CategoryDistributionModel({
    required this.category,
    required this.count,
    required this.percentageOfWardrobe,
    required this.activeCount,
    this.wornInPeriodCount = 0,
  });

  factory CategoryDistributionModel.fromJson(Map<String, dynamic> json) {
    return CategoryDistributionModel(
      category: json['category'] ?? 'Uncategorized',
      count: json['count'] ?? 0,
      percentageOfWardrobe: (json['percentage_of_wardrobe'] as num?)?.toDouble() ?? 0.0,
      activeCount: json['active_count'] ?? 0,
      wornInPeriodCount: json['worn_in_period_count'] ?? 0,
    );
  }

  CategoryDistribution toDomain() {
    return CategoryDistribution(
      category: category,
      count: count,
      percentageOfWardrobe: percentageOfWardrobe,
      activeCount: activeCount,
      wornInPeriodCount: wornInPeriodCount,
    );
  }
}

class GarmentUsageModel {
  final String garmentId;
  final String garmentName;
  final String mainCategory;
  final String primaryColor;
  final String? thumbnailRef;
  final int wearCount;
  final String? lastWornDate;
  final double? purchasePrice;
  final String purchaseCurrency;
  final double? costPerWear;
  final String? neglectReason;
  final String? laundryStatus;

  GarmentUsageModel({
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

  factory GarmentUsageModel.fromJson(Map<String, dynamic> json) {
    return GarmentUsageModel(
      garmentId: json['garment_id'] ?? '',
      garmentName: json['garment_name'] ?? 'Unnamed',
      mainCategory: json['main_category'] ?? 'Tops',
      primaryColor: json['primary_color'] ?? 'Unknown',
      thumbnailRef: json['thumbnail_ref'],
      wearCount: json['wear_count'] ?? 0,
      lastWornDate: json['last_worn_date'],
      purchasePrice: (json['purchase_price'] as num?)?.toDouble(),
      purchaseCurrency: json['purchase_currency'] ?? 'INR',
      costPerWear: (json['cost_per_wear'] as num?)?.toDouble(),
      neglectReason: json['neglect_reason'],
      laundryStatus: json['laundry_status'],
    );
  }

  GarmentUsage toDomain() {
    NeglectReason? reason;
    if (neglectReason != null) {
      switch (neglectReason) {
        case 'NEVER_RECORDED':
          reason = NeglectReason.neverRecorded;
          break;
        case 'NOT_WORN_RECENTLY':
          reason = NeglectReason.notWornRecently;
          break;
        case 'RARELY_WORN':
          reason = NeglectReason.rarelyWorn;
          break;
        case 'RECENTLY_ADDED':
          reason = NeglectReason.recentlyAdded;
          break;
        default:
          reason = NeglectReason.insufficientData;
      }
    }

    return GarmentUsage(
      garmentId: garmentId,
      garmentName: garmentName,
      mainCategory: mainCategory,
      primaryColor: primaryColor,
      thumbnailRef: thumbnailRef,
      wearCount: wearCount,
      lastWornDate: lastWornDate != null ? DateTime.tryParse(lastWornDate!) : null,
      purchasePrice: purchasePrice,
      purchaseCurrency: purchaseCurrency,
      costPerWear: costPerWear,
      neglectReason: reason,
      laundryStatus: laundryStatus,
    );
  }
}

class ColourDistributionModel {
  final String colorGroup;
  final List<String> originalColors;
  final int count;
  final double percentage;

  ColourDistributionModel({
    required this.colorGroup,
    required this.originalColors,
    required this.count,
    required this.percentage,
  });

  factory ColourDistributionModel.fromJson(Map<String, dynamic> json) {
    return ColourDistributionModel(
      colorGroup: json['color_group'] ?? 'Multicolor / Other',
      originalColors: (json['original_colors'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      count: json['count'] ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  ColourDistribution toDomain() {
    return ColourDistribution(
      colorGroup: colorGroup,
      originalColors: originalColors,
      count: count,
      percentage: percentage,
    );
  }
}

class CategoryUsageModel {
  final String category;
  final int totalGarments;
  final int wearCount;
  final int uniqueGarmentsWorn;
  final double utilisationPercentage;

  CategoryUsageModel({
    required this.category,
    required this.totalGarments,
    required this.wearCount,
    required this.uniqueGarmentsWorn,
    required this.utilisationPercentage,
  });

  factory CategoryUsageModel.fromJson(Map<String, dynamic> json) {
    return CategoryUsageModel(
      category: json['category'] ?? 'Tops',
      totalGarments: json['total_garments'] ?? 0,
      wearCount: json['wear_count'] ?? 0,
      uniqueGarmentsWorn: json['unique_garments_worn'] ?? 0,
      utilisationPercentage: (json['utilisation_percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  CategoryUsage toDomain() {
    return CategoryUsage(
      category: category,
      totalGarments: totalGarments,
      wearCount: wearCount,
      uniqueGarmentsWorn: uniqueGarmentsWorn,
      utilisationPercentage: utilisationPercentage,
    );
  }
}

class OutfitRepetitionModel {
  final String outfitId;
  final String outfitName;
  final int wearCount;
  final List<String> garmentNames;
  final List<String> garmentIds;
  final String? lastWornDate;
  final double? averageIntervalDays;
  final String occasion;

  OutfitRepetitionModel({
    required this.outfitId,
    required this.outfitName,
    required this.wearCount,
    required this.garmentNames,
    required this.garmentIds,
    this.lastWornDate,
    this.averageIntervalDays,
    this.occasion = 'Casual',
  });

  factory OutfitRepetitionModel.fromJson(Map<String, dynamic> json) {
    return OutfitRepetitionModel(
      outfitId: json['outfit_id'] ?? '',
      outfitName: json['outfit_name'] ?? 'Outfit',
      wearCount: json['wear_count'] ?? 0,
      garmentNames: (json['garment_names'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      garmentIds: (json['garment_ids'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      lastWornDate: json['last_worn_date'],
      averageIntervalDays: (json['average_interval_days'] as num?)?.toDouble(),
      occasion: json['occasion'] ?? 'Casual',
    );
  }

  OutfitRepetition toDomain() {
    return OutfitRepetition(
      outfitId: outfitId,
      outfitName: outfitName,
      wearCount: wearCount,
      garmentNames: garmentNames,
      garmentIds: garmentIds,
      lastWornDate: lastWornDate != null ? DateTime.tryParse(lastWornDate!) : null,
      averageIntervalDays: averageIntervalDays,
      occasion: occasion,
    );
  }
}

class WardrobeRecommendationModel {
  final String id;
  final String type;
  final String title;
  final String description;
  final List<String> garmentIds;
  final List<String> garmentNames;
  final String suggestedAction;
  final double confidenceScore;

  WardrobeRecommendationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.garmentIds,
    required this.garmentNames,
    required this.suggestedAction,
    required this.confidenceScore,
  });

  factory WardrobeRecommendationModel.fromJson(Map<String, dynamic> json) {
    return WardrobeRecommendationModel(
      id: json['id'] ?? '',
      type: json['type'] ?? 'NEW_COMBINATION',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      garmentIds: (json['garment_ids'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      garmentNames: (json['garment_names'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      suggestedAction: json['suggested_action'] ?? 'Explore',
      confidenceScore: (json['confidence_score'] as num?)?.toDouble() ?? 0.8,
    );
  }

  WardrobeRecommendation toDomain() {
    RecommendationType rType;
    switch (type) {
      case 'REVIVE_NEGLECTED':
        rType = RecommendationType.reviveNeglected;
        break;
      case 'HIGH_WEAR_FAVORITE':
        rType = RecommendationType.highWearFavorite;
        break;
      case 'CATEGORY_BALANCE':
        rType = RecommendationType.categoryBalance;
        break;
      default:
        rType = RecommendationType.newCombination;
    }

    return WardrobeRecommendation(
      id: id,
      type: rType,
      title: title,
      description: description,
      garmentIds: garmentIds,
      garmentNames: garmentNames,
      suggestedAction: suggestedAction,
      confidenceScore: confidenceScore,
    );
  }
}
