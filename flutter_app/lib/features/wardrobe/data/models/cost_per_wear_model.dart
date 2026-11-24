import '../../domain/entities/cost_per_wear.dart';

class CostPerWearItemModel {
  final String garmentId;
  final String garmentName;
  final String mainCategory;
  final String primaryColor;
  final String? thumbnailRef;
  final double? purchasePrice;
  final String purchaseCurrency;
  final String? purchaseDate;
  final int wearCount;
  final double? costPerWear;
  final String valueTier;

  CostPerWearItemModel({
    required this.garmentId,
    required this.garmentName,
    required this.mainCategory,
    required this.primaryColor,
    this.thumbnailRef,
    this.purchasePrice,
    this.purchaseCurrency = 'INR',
    this.purchaseDate,
    required this.wearCount,
    this.costPerWear,
    required this.valueTier,
  });

  factory CostPerWearItemModel.fromJson(Map<String, dynamic> json) {
    return CostPerWearItemModel(
      garmentId: json['garment_id'] ?? '',
      garmentName: json['garment_name'] ?? 'Unnamed',
      mainCategory: json['main_category'] ?? 'Tops',
      primaryColor: json['primary_color'] ?? 'Unknown',
      thumbnailRef: json['thumbnail_ref'],
      purchasePrice: (json['purchase_price'] as num?)?.toDouble(),
      purchaseCurrency: json['purchase_currency'] ?? 'INR',
      purchaseDate: json['purchase_date'],
      wearCount: json['wear_count'] ?? 0,
      costPerWear: (json['cost_per_wear'] as num?)?.toDouble(),
      valueTier: json['value_tier'] ?? 'MISSING_PRICE',
    );
  }

  CostPerWearItem toDomain() {
    ValueTier tier;
    switch (valueTier) {
      case 'EXCELLENT_VALUE':
        tier = ValueTier.excellentValue;
        break;
      case 'GOOD_VALUE':
        tier = ValueTier.goodValue;
        break;
      case 'FAIR_VALUE':
        tier = ValueTier.fairValue;
        break;
      case 'HIGH_COST_PER_WEAR':
        tier = ValueTier.highCostPerWear;
        break;
      case 'UNRECORDED_WEARS':
        tier = ValueTier.unrecordedWears;
        break;
      default:
        tier = ValueTier.missingPrice;
    }

    return CostPerWearItem(
      garmentId: garmentId,
      garmentName: garmentName,
      mainCategory: mainCategory,
      primaryColor: primaryColor,
      thumbnailRef: thumbnailRef,
      purchasePrice: purchasePrice,
      purchaseCurrency: purchaseCurrency,
      purchaseDate: purchaseDate != null ? DateTime.tryParse(purchaseDate!) : null,
      wearCount: wearCount,
      costPerWear: costPerWear,
      valueTier: tier,
    );
  }
}

class CostPerWearSummaryModel {
  final int totalGarmentsCount;
  final int garmentsWithPriceCount;
  final int garmentsWithoutPriceCount;
  final double totalInvestment;
  final String currency;
  final double? averageCostPerWear;
  final List<CostPerWearItemModel> items;
  final List<CostPerWearItemModel> bestValueGarments;
  final List<CostPerWearItemModel> highestCostPerWearGarments;

  CostPerWearSummaryModel({
    required this.totalGarmentsCount,
    required this.garmentsWithPriceCount,
    required this.garmentsWithoutPriceCount,
    required this.totalInvestment,
    this.currency = 'INR',
    this.averageCostPerWear,
    required this.items,
    required this.bestValueGarments,
    required this.highestCostPerWearGarments,
  });

  factory CostPerWearSummaryModel.fromJson(Map<String, dynamic> json) {
    return CostPerWearSummaryModel(
      totalGarmentsCount: json['total_garments_count'] ?? 0,
      garmentsWithPriceCount: json['garments_with_price_count'] ?? 0,
      garmentsWithoutPriceCount: json['garments_without_price_count'] ?? 0,
      totalInvestment: (json['total_investment'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'INR',
      averageCostPerWear: (json['average_cost_per_wear'] as num?)?.toDouble(),
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => CostPerWearItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      bestValueGarments: (json['best_value_garments'] as List<dynamic>?)
              ?.map((e) => CostPerWearItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      highestCostPerWearGarments: (json['highest_cost_per_wear_garments'] as List<dynamic>?)
              ?.map((e) => CostPerWearItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  CostPerWearSummary toDomain() {
    return CostPerWearSummary(
      totalGarmentsCount: totalGarmentsCount,
      garmentsWithPriceCount: garmentsWithPriceCount,
      garmentsWithoutPriceCount: garmentsWithoutPriceCount,
      totalInvestment: totalInvestment,
      currency: currency,
      averageCostPerWear: averageCostPerWear,
      items: items.map((e) => e.toDomain()).toList(),
      bestValueGarments: bestValueGarments.map((e) => e.toDomain()).toList(),
      highestCostPerWearGarments: highestCostPerWearGarments.map((e) => e.toDomain()).toList(),
    );
  }
}

