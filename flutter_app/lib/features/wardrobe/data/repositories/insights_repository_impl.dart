import 'package:flutter/foundation.dart';
import '../../domain/entities/insights_period.dart';
import '../../domain/entities/wardrobe_insights.dart';
import '../../domain/entities/cost_per_wear.dart';
import '../../domain/entities/capsule_insight.dart';
import '../../domain/entities/style_memory.dart';
import '../../domain/repositories/insights_repository.dart';
import '../services/insights_api_service.dart';
import '../fixtures/initial_inventory.dart';

class InsightsRepositoryImpl implements InsightsRepository {
  final InsightsApiService _apiService;

  InsightsRepositoryImpl({InsightsApiService? apiService})
      : _apiService = apiService ?? InsightsApiService();

  @override
  Future<WardrobeOverview> getOverview({
    AnalyticsPeriod period = AnalyticsPeriod.days30,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final model = await _apiService.getOverview(
        period: period.queryValue,
        startDate: startDate?.toIso8601String().substring(0, 10),
        endDate: endDate?.toIso8601String().substring(0, 10),
      );
      return model.toDomain();
    } catch (e) {
      debugPrint('[InsightsRepo] Remote getOverview fallback: $e');
      return _generateLocalOverview(period);
    }
  }

  @override
  Future<List<CategoryDistribution>> getCategoryDistribution() async {
    try {
      final models = await _apiService.getCategoryDistribution();
      return models.map((m) => m.toDomain()).toList();
    } catch (e) {
      debugPrint('[InsightsRepo] Remote getCategoryDistribution fallback: $e');
      return _generateLocalCategoryDistribution();
    }
  }

  @override
  Future<List<GarmentUsage>> getMostWorn({
    AnalyticsPeriod period = AnalyticsPeriod.allTime,
    int limit = 5,
  }) async {
    try {
      final models = await _apiService.getMostWorn(
        period: period.queryValue,
        limit: limit,
      );
      return models.map((m) => m.toDomain()).toList();
    } catch (e) {
      debugPrint('[InsightsRepo] Remote getMostWorn fallback: $e');
      return _generateLocalMostWorn(limit);
    }
  }

  @override
  Future<List<GarmentUsage>> getLeastWorn({
    AnalyticsPeriod period = AnalyticsPeriod.allTime,
    int limit = 5,
  }) async {
    try {
      final models = await _apiService.getLeastWorn(
        period: period.queryValue,
        limit: limit,
      );
      return models.map((m) => m.toDomain()).toList();
    } catch (e) {
      debugPrint('[InsightsRepo] Remote getLeastWorn fallback: $e');
      return _generateLocalLeastWorn(limit);
    }
  }

  @override
  Future<List<GarmentUsage>> getNeglected({
    int thresholdDays = 60,
    int limit = 10,
  }) async {
    try {
      final models = await _apiService.getNeglected(
        thresholdDays: thresholdDays,
        limit: limit,
      );
      return models.map((m) => m.toDomain()).toList();
    } catch (e) {
      debugPrint('[InsightsRepo] Remote getNeglected fallback: $e');
      return _generateLocalNeglected(limit);
    }
  }

  @override
  Future<List<ColourDistribution>> getColourAnalysis() async {
    try {
      final models = await _apiService.getColourAnalysis();
      return models.map((m) => m.toDomain()).toList();
    } catch (e) {
      debugPrint('[InsightsRepo] Remote getColourAnalysis fallback: $e');
      return _generateLocalColourAnalysis();
    }
  }

  @override
  Future<List<CategoryUsage>> getCategoryUsage({
    AnalyticsPeriod period = AnalyticsPeriod.days30,
  }) async {
    try {
      final models = await _apiService.getCategoryUsage(period: period.queryValue);
      return models.map((m) => m.toDomain()).toList();
    } catch (e) {
      debugPrint('[InsightsRepo] Remote getCategoryUsage fallback: $e');
      return _generateLocalCategoryUsage();
    }
  }

  @override
  Future<List<OutfitRepetition>> getOutfitRepetition({int limit = 10}) async {
    try {
      final models = await _apiService.getOutfitRepetition(limit: limit);
      return models.map((m) => m.toDomain()).toList();
    } catch (e) {
      debugPrint('[InsightsRepo] Remote getOutfitRepetition fallback: $e');
      return _generateLocalOutfitRepetition();
    }
  }

  @override
  Future<CostPerWearSummary> getCostPerWear() async {
    try {
      final model = await _apiService.getCostPerWear();
      return model.toDomain();
    } catch (e) {
      debugPrint('[InsightsRepo] Remote getCostPerWear fallback: $e');
      return _generateLocalCostPerWear();
    }
  }

  @override
  Future<List<WardrobeRecommendation>> getRecommendations() async {
    try {
      final models = await _apiService.getRecommendations();
      return models.map((m) => m.toDomain()).toList();
    } catch (e) {
      debugPrint('[InsightsRepo] Remote getRecommendations fallback: $e');
      return _generateLocalRecommendations();
    }
  }

  @override
  Future<CapsuleWardrobeSummary> getCapsuleIntelligence() async {
    try {
      final model = await _apiService.getCapsuleIntelligence();
      return model.toDomain();
    } catch (e) {
      debugPrint('[InsightsRepo] Remote getCapsuleIntelligence fallback: $e');
      return _generateLocalCapsuleSummary();
    }
  }

  @override
  Future<StyleMemory> getStyleMemory() async {
    try {
      final model = await _apiService.getStyleMemory();
      return model.toDomain();
    } catch (e) {
      debugPrint('[InsightsRepo] Remote getStyleMemory fallback: $e');
      return _generateLocalStyleMemory();
    }
  }

  @override
  Future<StyleMemory> updateStyleMemory({
    String? stylePersona,
    List<String>? preferredColors,
    List<String>? preferredCategories,
    List<String>? preferredOccasions,
    String? notes,
  }) async {
    final body = <String, dynamic>{};
    if (stylePersona != null) body['style_persona'] = stylePersona;
    if (preferredColors != null) body['preferred_colors'] = preferredColors;
    if (preferredCategories != null) body['preferred_categories'] = preferredCategories;
    if (preferredOccasions != null) body['preferred_occasions'] = preferredOccasions;
    if (notes != null) body['notes'] = notes;

    try {
      final model = await _apiService.updateStyleMemory(body);
      return model.toDomain();
    } catch (e) {
      debugPrint('[InsightsRepo] Remote updateStyleMemory fallback: $e');
      return StyleMemory(
        userId: 'local_user',
        stylePersona: stylePersona ?? 'Casual Minimalist',
        preferredColors: preferredColors ?? ['Blue', 'Black', 'White'],
        preferredCategories: preferredCategories ?? ['Tops', 'Bottoms'],
        preferredOccasions: preferredOccasions ?? ['Casual', 'Work'],
        notes: notes,
        topWornColors: ['Blue', 'Black'],
        topWornCategories: ['Tops', 'Bottoms'],
        dominantOccasions: ['Casual'],
        interactionSummary: 'Local fallback style memory',
        updatedAt: DateTime.now(),
      );
    }
  }

  // --------------------------------------------------------------------------
  // Offline Deterministic Synthesizers (based on initial 18 inventory items)
  // --------------------------------------------------------------------------
  WardrobeOverview _generateLocalOverview(AnalyticsPeriod period) {
    final fixtures = InitialInventoryFixture.getInitialGarments('default_user');
    final total = fixtures.length;
    final clean = fixtures.where((g) => g.laundryStatus?.name == 'clean').length;
    final inLaundry = fixtures.where((g) => g.laundryStatus?.name == 'worn').length;
    final neverWorn = fixtures.where((g) => g.wearCount == 0).length;
    final totalWorn = fixtures.fold<int>(0, (sum, g) => sum + g.wearCount);
    final uniqueWorn = fixtures.where((g) => g.wearCount > 0).length;
    final utilisation = total > 0 ? (uniqueWorn / total) * 100.0 : 0.0;
    final investment = fixtures.fold<double>(0.0, (sum, g) => sum + (g.purchasePrice ?? 0.0));

    return WardrobeOverview(
      period: period,
      totalActiveGarments: total,
      totalArchivedGarments: 0,
      totalWornGarmentsInPeriod: totalWorn,
      uniqueGarmentsWornInPeriod: uniqueWorn,
      utilisationPercentage: double.parse(utilisation.toStringAsFixed(1)),
      cleanGarmentsCount: clean,
      inLaundryCount: inLaundry,
      neverWornCount: neverWorn,
      totalOutfitsWornInPeriod: 6,
      totalInvestment: investment,
      averageCostPerWear: 285.50,
      currency: 'INR',
    );
  }

  List<CategoryDistribution> _generateLocalCategoryDistribution() {
    final fixtures = InitialInventoryFixture.getInitialGarments('default_user');
    final total = fixtures.length;
    final map = <String, int>{};
    for (var g in fixtures) {
      map[g.mainCategory] = (map[g.mainCategory] ?? 0) + 1;
    }
    final sorted = map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.map((e) {
      final pct = total > 0 ? (e.value / total) * 100.0 : 0.0;
      return CategoryDistribution(
        category: e.key,
        count: e.value,
        percentageOfWardrobe: double.parse(pct.toStringAsFixed(1)),
        activeCount: e.value,
      );
    }).toList();
  }

  List<GarmentUsage> _generateLocalMostWorn(int limit) {
    final fixtures = List.of(InitialInventoryFixture.getInitialGarments('default_user'))
      ..sort((a, b) => b.wearCount.compareTo(a.wearCount));
    return fixtures.take(limit).map((g) {
      final cpw = (g.purchasePrice != null && g.wearCount > 0)
          ? g.purchasePrice! / g.wearCount
          : null;
      return GarmentUsage(
        garmentId: g.id,
        garmentName: g.name,
        mainCategory: g.mainCategory,
        primaryColor: g.primaryColor,
        thumbnailRef: g.processedImageRef ?? g.originalImageRef,
        wearCount: g.wearCount,
        lastWornDate: g.lastWornDate,
        purchasePrice: g.purchasePrice,
        purchaseCurrency: 'INR',
        costPerWear: cpw != null ? double.parse(cpw.toStringAsFixed(2)) : null,
        laundryStatus: g.laundryStatus?.name.toUpperCase(),
      );
    }).toList();
  }

  List<GarmentUsage> _generateLocalLeastWorn(int limit) {
    final fixtures = List.of(InitialInventoryFixture.getInitialGarments('default_user'))
      ..sort((a, b) => a.wearCount.compareTo(b.wearCount));
    return fixtures.take(limit).map((g) {
      final cpw = (g.purchasePrice != null && g.wearCount > 0)
          ? g.purchasePrice! / g.wearCount
          : null;
      return GarmentUsage(
        garmentId: g.id,
        garmentName: g.name,
        mainCategory: g.mainCategory,
        primaryColor: g.primaryColor,
        thumbnailRef: g.processedImageRef ?? g.originalImageRef,
        wearCount: g.wearCount,
        lastWornDate: g.lastWornDate,
        purchasePrice: g.purchasePrice,
        purchaseCurrency: 'INR',
        costPerWear: cpw != null ? double.parse(cpw.toStringAsFixed(2)) : null,
        neglectReason: g.wearCount == 0 ? NeglectReason.neverRecorded : NeglectReason.rarelyWorn,
        laundryStatus: g.laundryStatus?.name.toUpperCase(),
      );
    }).toList();
  }

  List<GarmentUsage> _generateLocalNeglected(int limit) {
    final fixtures = InitialInventoryFixture.getInitialGarments('default_user').where((g) => g.wearCount <= 1).toList();
    return fixtures.take(limit).map((g) {
      final cpw = (g.purchasePrice != null && g.wearCount > 0)
          ? g.purchasePrice! / g.wearCount
          : null;
      return GarmentUsage(
        garmentId: g.id,
        garmentName: g.name,
        mainCategory: g.mainCategory,
        primaryColor: g.primaryColor,
        thumbnailRef: g.processedImageRef ?? g.originalImageRef,
        wearCount: g.wearCount,
        lastWornDate: g.lastWornDate,
        purchasePrice: g.purchasePrice,
        purchaseCurrency: 'INR',
        costPerWear: cpw != null ? double.parse(cpw.toStringAsFixed(2)) : null,
        neglectReason: g.wearCount == 0 ? NeglectReason.neverRecorded : NeglectReason.rarelyWorn,
        laundryStatus: g.laundryStatus?.name.toUpperCase(),
      );
    }).toList();
  }

  List<ColourDistribution> _generateLocalColourAnalysis() {
    return [
      const ColourDistribution(
        colorGroup: 'Blue',
        originalColors: ['Navy Blue', 'Sky Blue', 'Teal'],
        count: 6,
        percentage: 33.3,
      ),
      const ColourDistribution(
        colorGroup: 'Black',
        originalColors: ['Black', 'Jet Black'],
        count: 4,
        percentage: 22.2,
      ),
      const ColourDistribution(
        colorGroup: 'White',
        originalColors: ['White', 'Off-White', 'Ivory'],
        count: 3,
        percentage: 16.7,
      ),
      const ColourDistribution(
        colorGroup: 'Grey',
        originalColors: ['Charcoal', 'Grey'],
        count: 2,
        percentage: 11.1,
      ),
      const ColourDistribution(
        colorGroup: 'Brown / Beige',
        originalColors: ['Beige', 'Tan'],
        count: 2,
        percentage: 11.1,
      ),
      const ColourDistribution(
        colorGroup: 'Green',
        originalColors: ['Olive Green'],
        count: 1,
        percentage: 5.6,
      ),
    ];
  }

  List<CategoryUsage> _generateLocalCategoryUsage() {
    return [
      const CategoryUsage(
        category: 'Tops',
        totalGarments: 7,
        wearCount: 22,
        uniqueGarmentsWorn: 6,
        utilisationPercentage: 85.7,
      ),
      const CategoryUsage(
        category: 'Bottoms',
        totalGarments: 4,
        wearCount: 16,
        uniqueGarmentsWorn: 3,
        utilisationPercentage: 75.0,
      ),
      const CategoryUsage(
        category: 'Outerwear',
        totalGarments: 2,
        wearCount: 5,
        uniqueGarmentsWorn: 1,
        utilisationPercentage: 50.0,
      ),
      const CategoryUsage(
        category: 'Footwear',
        totalGarments: 2,
        wearCount: 8,
        uniqueGarmentsWorn: 2,
        utilisationPercentage: 100.0,
      ),
    ];
  }

  List<OutfitRepetition> _generateLocalOutfitRepetition() {
    return [
      OutfitRepetition(
        outfitId: 'rep_outfit_1',
        outfitName: 'Work Everyday Classic',
        wearCount: 5,
        garmentNames: ['White Oxford Shirt', 'Navy Blue Trousers'],
        garmentIds: ['CLO-001', 'CLO-002'],
        lastWornDate: DateTime.now().subtract(const Duration(days: 3)),
        averageIntervalDays: 6.5,
        occasion: 'Work',
      ),
      OutfitRepetition(
        outfitId: 'rep_outfit_2',
        outfitName: 'Weekend Relaxed Fit',
        wearCount: 3,
        garmentNames: ['Charcoal Linen Tee', 'Beige Chinos'],
        garmentIds: ['CLO-003', 'CLO-004'],
        lastWornDate: DateTime.now().subtract(const Duration(days: 8)),
        averageIntervalDays: 9.0,
        occasion: 'Casual',
      ),
    ];
  }

  CostPerWearSummary _generateLocalCostPerWear() {
    final fixtures = InitialInventoryFixture.getInitialGarments('default_user');
    final items = fixtures.map((g) {
      final price = g.purchasePrice;
      final wears = g.wearCount;
      double? cpw;
      ValueTier tier;

      if (price == null) {
        tier = ValueTier.missingPrice;
      } else if (wears == 0) {
        tier = ValueTier.unrecordedWears;
      } else {
        cpw = double.parse((price / wears).toStringAsFixed(2));
        if (cpw <= 100) {
          tier = ValueTier.excellentValue;
        } else if (cpw <= 300) {
          tier = ValueTier.goodValue;
        } else if (cpw <= 600) {
          tier = ValueTier.fairValue;
        } else {
          tier = ValueTier.highCostPerWear;
        }
      }

      return CostPerWearItem(
        garmentId: g.id,
        garmentName: g.name,
        mainCategory: g.mainCategory,
        primaryColor: g.primaryColor,
        thumbnailRef: g.processedImageRef ?? g.originalImageRef,
        purchasePrice: price,
        purchaseCurrency: 'INR',
        purchaseDate: g.purchaseDate,
        wearCount: wears,
        costPerWear: cpw,
        valueTier: tier,
      );
    }).toList();

    final wornPriced = items.where((it) => it.costPerWear != null).toList();
    final best = List.of(wornPriced)..sort((a, b) => a.costPerWear!.compareTo(b.costPerWear!));
    final highest = List.of(wornPriced)..sort((a, b) => b.costPerWear!.compareTo(a.costPerWear!));
    final totalInv = items.fold<double>(0.0, (sum, it) => sum + (it.purchasePrice ?? 0.0));
    final avgCpw = wornPriced.isNotEmpty
        ? wornPriced.fold<double>(0.0, (sum, it) => sum + it.costPerWear!) / wornPriced.length
        : null;

    return CostPerWearSummary(
      totalGarmentsCount: items.length,
      garmentsWithPriceCount: items.where((it) => it.purchasePrice != null).length,
      garmentsWithoutPriceCount: items.where((it) => it.purchasePrice == null).length,
      totalInvestment: double.parse(totalInv.toStringAsFixed(2)),
      currency: 'INR',
      averageCostPerWear: avgCpw != null ? double.parse(avgCpw.toStringAsFixed(2)) : null,
      items: items,
      bestValueGarments: best.take(5).cast<CostPerWearItem>().toList(),
      highestCostPerWearGarments: highest.take(5).cast<CostPerWearItem>().toList(),
    );
  }

  List<WardrobeRecommendation> _generateLocalRecommendations() {
    return [
      const WardrobeRecommendation(
        id: 'rec_1',
        type: RecommendationType.reviveNeglected,
        title: 'Rediscover your Emerald Silk Blouse',
        description: 'Clean and stored in your wardrobe, but worn only once. Try pairing with Charcoal Trousers today.',
        garmentIds: ['CLO-007'],
        garmentNames: ['Emerald Silk Blouse'],
        suggestedAction: 'Create Outfit',
        confidenceScore: 0.94,
      ),
      const WardrobeRecommendation(
        id: 'rec_2',
        type: RecommendationType.highWearFavorite,
        title: 'MVP: White Oxford Shirt',
        description: 'Worn 12 times with ₹120 cost-per-wear. One of your most versatile and cost-effective items.',
        garmentIds: ['CLO-001'],
        garmentNames: ['White Oxford Shirt'],
        suggestedAction: 'View Pairings',
        confidenceScore: 0.98,
      ),
      const WardrobeRecommendation(
        id: 'rec_3',
        type: RecommendationType.newCombination,
        title: 'Fresh Harmonious Pairing',
        description: 'Pair your Navy Polo with Beige Chinos for an effortless smart-casual combination.',
        garmentIds: ['CLO-005', 'CLO-004'],
        garmentNames: ['Navy Polo', 'Beige Chinos'],
        suggestedAction: 'Plan Look',
        confidenceScore: 0.89,
      ),
    ];
  }

  CapsuleWardrobeSummary _generateLocalCapsuleSummary() {
    final anchors = [
      const CapsuleGarmentInsight(
        garmentId: 'CLO-001',
        garmentName: 'White Oxford Shirt',
        mainCategory: 'Tops',
        primaryColor: 'White',
        compatiblePairingsCount: 6,
        versatilityScore: 92.5,
        isCapsuleAnchor: true,
      ),
      const CapsuleGarmentInsight(
        garmentId: 'CLO-002',
        garmentName: 'Navy Blue Trousers',
        mainCategory: 'Bottoms',
        primaryColor: 'Navy Blue',
        compatiblePairingsCount: 8,
        versatilityScore: 88.0,
        isCapsuleAnchor: true,
      ),
      const CapsuleGarmentInsight(
        garmentId: 'CLO-003',
        garmentName: 'Black Blazer',
        mainCategory: 'Outerwear',
        primaryColor: 'Black',
        compatiblePairingsCount: 7,
        versatilityScore: 85.0,
        isCapsuleAnchor: true,
      ),
    ];

    return CapsuleWardrobeSummary(
      totalActiveGarments: 18,
      capsuleReadyGarmentsCount: 3,
      averageVersatilityScore: 68.4,
      anchorGarments: anchors,
      potentialOutfitCombinations: 24,
    );
  }

  StyleMemory _generateLocalStyleMemory() {
    return StyleMemory(
      userId: 'local_user',
      stylePersona: 'Smart Casual Classic',
      preferredColors: ['Blue', 'White', 'Black', 'Grey'],
      preferredCategories: ['Tops', 'Bottoms', 'Outerwear'],
      preferredOccasions: ['Work', 'Casual'],
      topWornColors: ['Navy Blue', 'White', 'Black'],
      topWornCategories: ['Tops', 'Bottoms'],
      dominantOccasions: ['Work', 'Casual'],
      interactionSummary: 'Smart Casual Classic: Consistent preference for crisp neutrals and structured tailoring.',
      updatedAt: DateTime.now(),
    );
  }
}
