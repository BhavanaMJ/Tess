/// Value tier classification based on Cost-Per-Wear.
enum ValueTier {
  excellentValue, // CPW <= 100
  goodValue, // CPW <= 300
  fairValue, // CPW <= 600
  highCostPerWear, // CPW > 600
  unrecordedWears, // Price > 0, wear_count == 0
  missingPrice, // purchase_price is null
}

extension ValueTierExtension on ValueTier {
  String get label {
    switch (this) {
      case ValueTier.excellentValue:
        return 'Excellent Value';
      case ValueTier.goodValue:
        return 'Good Value';
      case ValueTier.fairValue:
        return 'Fair Value';
      case ValueTier.highCostPerWear:
        return 'High CPW';
      case ValueTier.unrecordedWears:
        return 'Never Worn';
      case ValueTier.missingPrice:
        return 'Unpriced';
    }
  }
}

/// Individual garment cost-per-wear detail.
class CostPerWearItem {
  final String garmentId;
  final String garmentName;
  final String mainCategory;
  final String primaryColor;
  final String? thumbnailRef;
  final double? purchasePrice;
  final String purchaseCurrency;
  final DateTime? purchaseDate;
  final int wearCount;
  final double? costPerWear;
  final ValueTier valueTier;

  const CostPerWearItem({
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
}

/// Summary of cost-per-wear analytics across the entire wardrobe.
class CostPerWearSummary {
  final int totalGarmentsCount;
  final int garmentsWithPriceCount;
  final int garmentsWithoutPriceCount;
  final double totalInvestment;
  final String currency;
  final double? averageCostPerWear;
  final List<CostPerWearItem> items;
  final List<CostPerWearItem> bestValueGarments;
  final List<CostPerWearItem> highestCostPerWearGarments;

  const CostPerWearSummary({
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
}

