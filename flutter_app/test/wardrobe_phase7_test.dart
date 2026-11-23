import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tess/core/theme/app_theme.dart';
import 'package:tess/features/wardrobe/domain/entities/insights_period.dart';
import 'package:tess/features/wardrobe/domain/entities/wardrobe_insights.dart';
import 'package:tess/features/wardrobe/domain/entities/cost_per_wear.dart';
import 'package:tess/features/wardrobe/domain/entities/capsule_insight.dart';
import 'package:tess/features/wardrobe/domain/entities/style_memory.dart';
import 'package:tess/features/wardrobe/domain/repositories/insights_repository.dart';
import 'package:tess/features/wardrobe/presentation/controllers/insights_controller.dart';
import 'package:tess/features/wardrobe/presentation/screens/wardrobe_insights_screen.dart';
import 'package:tess/features/wardrobe/presentation/screens/cost_per_wear_screen.dart';
import 'package:tess/features/wardrobe/presentation/screens/capsule_wardrobe_screen.dart';
import 'package:tess/features/wardrobe/presentation/screens/outfit_repetition_screen.dart';
import 'package:tess/features/wardrobe/presentation/screens/style_memory_screen.dart';
import 'package:tess/features/wardrobe/presentation/widgets/wardrobe_utilisation_card.dart';
import 'package:tess/features/wardrobe/presentation/widgets/category_distribution_chart.dart';
import 'package:tess/features/wardrobe/presentation/widgets/colour_distribution_chart.dart';
import 'package:tess/features/wardrobe/presentation/widgets/cost_per_wear_card.dart';

class MockInsightsRepository implements InsightsRepository {
  AnalyticsPeriod lastPeriodRequested = AnalyticsPeriod.days30;

  @override
  Future<WardrobeOverview> getOverview({
    AnalyticsPeriod period = AnalyticsPeriod.days30,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    lastPeriodRequested = period;
    return WardrobeOverview(
      period: period,
      totalActiveGarments: 18,
      totalArchivedGarments: 2,
      totalWornGarmentsInPeriod: period == AnalyticsPeriod.days7 ? 4 : 12,
      uniqueGarmentsWornInPeriod: period == AnalyticsPeriod.days7 ? 3 : 8,
      utilisationPercentage: period == AnalyticsPeriod.days7 ? 16.7 : 44.4,
      cleanGarmentsCount: 12,
      inLaundryCount: 6,
      neverWornCount: 3,
      totalOutfitsWornInPeriod: 6,
      totalInvestment: 38400.0,
      averageCostPerWear: 320.0,
      currency: 'INR',
    );
  }

  @override
  Future<List<CategoryDistribution>> getCategoryDistribution() async {
    return const [
      CategoryDistribution(
        category: 'Tops',
        count: 7,
        percentageOfWardrobe: 38.9,
        activeCount: 7,
      ),
      CategoryDistribution(
        category: 'Bottoms',
        count: 5,
        percentageOfWardrobe: 27.8,
        activeCount: 5,
      ),
      CategoryDistribution(
        category: 'Ethnic wear',
        count: 3,
        percentageOfWardrobe: 16.7,
        activeCount: 3,
      ),
    ];
  }

  @override
  Future<List<GarmentUsage>> getMostWorn({
    AnalyticsPeriod period = AnalyticsPeriod.allTime,
    int limit = 5,
  }) async {
    return [
      const GarmentUsage(
        garmentId: 'CLO-001',
        garmentName: 'Classic White Shirt',
        mainCategory: 'Tops',
        primaryColor: 'White',
        wearCount: 14,
        purchasePrice: 2400.0,
        purchaseCurrency: 'INR',
        costPerWear: 171.4,
        laundryStatus: 'CLEAN',
      ),
      const GarmentUsage(
        garmentId: 'CLO-002',
        garmentName: 'Indigo Jeans',
        mainCategory: 'Bottoms',
        primaryColor: 'Blue',
        wearCount: 10,
        purchasePrice: 3500.0,
        purchaseCurrency: 'INR',
        costPerWear: 350.0,
        laundryStatus: 'WORN',
      ),
    ];
  }

  @override
  Future<List<GarmentUsage>> getLeastWorn({
    AnalyticsPeriod period = AnalyticsPeriod.allTime,
    int limit = 5,
  }) async {
    return [
      const GarmentUsage(
        garmentId: 'CLO-009',
        garmentName: 'Yellow Party Top',
        mainCategory: 'Tops',
        primaryColor: 'Yellow',
        wearCount: 0,
        purchasePrice: 1800.0,
        purchaseCurrency: 'INR',
        neglectReason: NeglectReason.neverRecorded,
        laundryStatus: 'CLEAN',
      ),
    ];
  }

  @override
  Future<List<GarmentUsage>> getNeglected({
    int thresholdDays = 60,
    int limit = 10,
  }) async {
    return [
      const GarmentUsage(
        garmentId: 'CLO-009',
        garmentName: 'Yellow Party Top',
        mainCategory: 'Tops',
        primaryColor: 'Yellow',
        wearCount: 0,
        purchasePrice: 1800.0,
        purchaseCurrency: 'INR',
        neglectReason: NeglectReason.neverRecorded,
        laundryStatus: 'CLEAN',
      ),
      const GarmentUsage(
        garmentId: 'CLO-010',
        garmentName: 'Silk Stole',
        mainCategory: 'Accessories',
        primaryColor: 'Red',
        wearCount: 1,
        purchasePrice: 900.0,
        purchaseCurrency: 'INR',
        neglectReason: NeglectReason.notWornRecently,
        laundryStatus: 'CLEAN',
      ),
    ];
  }

  @override
  Future<List<ColourDistribution>> getColourAnalysis() async {
    return const [
      ColourDistribution(
        colorGroup: 'Blue',
        originalColors: ['Navy', 'Sky Blue'],
        count: 6,
        percentage: 33.3,
      ),
      ColourDistribution(
        colorGroup: 'White',
        originalColors: ['White', 'Ivory'],
        count: 4,
        percentage: 22.2,
      ),
      ColourDistribution(
        colorGroup: 'Black',
        originalColors: ['Black'],
        count: 3,
        percentage: 16.7,
      ),
    ];
  }

  @override
  Future<List<CategoryUsage>> getCategoryUsage({
    AnalyticsPeriod period = AnalyticsPeriod.days30,
  }) async {
    return const [
      CategoryUsage(
        category: 'Tops',
        totalGarments: 7,
        wearCount: 18,
        uniqueGarmentsWorn: 5,
        utilisationPercentage: 71.4,
      ),
      CategoryUsage(
        category: 'Bottoms',
        totalGarments: 5,
        wearCount: 12,
        uniqueGarmentsWorn: 4,
        utilisationPercentage: 80.0,
      ),
    ];
  }

  @override
  Future<List<OutfitRepetition>> getOutfitRepetition({int limit = 10}) async {
    return [
      OutfitRepetition(
        outfitId: 'rep_1',
        outfitName: 'Office Smart Look',
        wearCount: 4,
        garmentNames: ['Classic White Shirt', 'Indigo Jeans'],
        garmentIds: ['CLO-001', 'CLO-002'],
        lastWornDate: DateTime.now().subtract(const Duration(days: 4)),
        averageIntervalDays: 7.0,
        occasion: 'Work',
      ),
    ];
  }

  @override
  Future<CostPerWearSummary> getCostPerWear() async {
    const item1 = CostPerWearItem(
      garmentId: 'CLO-001',
      garmentName: 'Classic White Shirt',
      mainCategory: 'Tops',
      primaryColor: 'White',
      purchasePrice: 2400.0,
      purchaseCurrency: 'INR',
      wearCount: 14,
      costPerWear: 171.4,
      valueTier: ValueTier.goodValue,
    );
    const item2 = CostPerWearItem(
      garmentId: 'CLO-002',
      garmentName: 'Indigo Jeans',
      mainCategory: 'Bottoms',
      primaryColor: 'Blue',
      purchasePrice: 3500.0,
      purchaseCurrency: 'INR',
      wearCount: 10,
      costPerWear: 350.0,
      valueTier: ValueTier.fairValue,
    );
    const item3 = CostPerWearItem(
      garmentId: 'CLO-009',
      garmentName: 'Yellow Party Top',
      mainCategory: 'Tops',
      primaryColor: 'Yellow',
      purchasePrice: 1800.0,
      purchaseCurrency: 'INR',
      wearCount: 0,
      costPerWear: null,
      valueTier: ValueTier.unrecordedWears,
    );
    const item4 = CostPerWearItem(
      garmentId: 'CLO-015',
      garmentName: 'Vintage Gift Scarf',
      mainCategory: 'Accessories',
      primaryColor: 'Pink',
      purchasePrice: null,
      purchaseCurrency: 'INR',
      wearCount: 3,
      costPerWear: null,
      valueTier: ValueTier.missingPrice,
    );

    return const CostPerWearSummary(
      totalGarmentsCount: 4,
      garmentsWithPriceCount: 3,
      garmentsWithoutPriceCount: 1,
      totalInvestment: 7700.0,
      currency: 'INR',
      averageCostPerWear: 260.7,
      items: [item1, item2, item3, item4],
      bestValueGarments: [item1],
      highestCostPerWearGarments: [item2],
    );
  }

  @override
  Future<List<WardrobeRecommendation>> getRecommendations() async {
    return const [
      WardrobeRecommendation(
        id: 'rec_1',
        type: RecommendationType.reviveNeglected,
        title: 'Revive your Yellow Party Top',
        description: 'Clean and stored, but has 0 recorded wears. Try styling it this weekend!',
        garmentIds: ['CLO-009'],
        garmentNames: ['Yellow Party Top'],
        suggestedAction: 'Create Outfit',
        confidenceScore: 0.92,
      ),
      WardrobeRecommendation(
        id: 'rec_2',
        type: RecommendationType.highWearFavorite,
        title: 'MVP: Classic White Shirt',
        description: 'Worn 14 times with an exceptional ₹171 CPW!',
        garmentIds: ['CLO-001'],
        garmentNames: ['Classic White Shirt'],
        suggestedAction: 'View Pairings',
        confidenceScore: 0.97,
      ),
    ];
  }

  @override
  Future<CapsuleWardrobeSummary> getCapsuleIntelligence() async {
    return const CapsuleWardrobeSummary(
      totalActiveGarments: 18,
      capsuleReadyGarmentsCount: 3,
      averageVersatilityScore: 78.5,
      anchorGarments: [
        CapsuleGarmentInsight(
          garmentId: 'CLO-001',
          garmentName: 'Classic White Shirt',
          mainCategory: 'Tops',
          primaryColor: 'White',
          compatiblePairingsCount: 5,
          versatilityScore: 90.0,
          isCapsuleAnchor: true,
        ),
      ],
      potentialOutfitCombinations: 16,
    );
  }

  @override
  Future<StyleMemory> getStyleMemory() async {
    return StyleMemory(
      userId: 'test_user',
      stylePersona: 'Smart Casual Classic',
      preferredColors: const ['Blue', 'White', 'Black'],
      preferredCategories: const ['Tops', 'Bottoms'],
      preferredOccasions: const ['Work', 'Casual'],
      topWornColors: const ['White', 'Blue'],
      topWornCategories: const ['Tops', 'Bottoms'],
      dominantOccasions: const ['Work'],
      interactionSummary: 'Smart Casual Classic persona with clear neutral preference.',
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<StyleMemory> updateStyleMemory({
    String? stylePersona,
    List<String>? preferredColors,
    List<String>? preferredCategories,
    List<String>? preferredOccasions,
    String? notes,
  }) async {
    return StyleMemory(
      userId: 'test_user',
      stylePersona: stylePersona ?? 'Smart Casual Classic',
      preferredColors: preferredColors ?? const ['Blue', 'White'],
      preferredCategories: preferredCategories ?? const ['Tops', 'Bottoms'],
      preferredOccasions: preferredOccasions ?? const ['Work'],
      notes: notes,
      topWornColors: const ['White', 'Blue'],
      topWornCategories: const ['Tops', 'Bottoms'],
      dominantOccasions: const ['Work'],
      interactionSummary: 'Updated style memory preferences.',
      updatedAt: DateTime.now(),
    );
  }
}

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: child,
    );
  }

  group('Phase 7: Wardrobe Insights & Personal Style Intelligence Unit and Widget Tests', () {
    late MockInsightsRepository mockRepo;
    late InsightsController controller;

    setUp(() async {
      mockRepo = MockInsightsRepository();
      controller = InsightsController(repository: mockRepo);
      await controller.loadDashboard();
    });

    test('InsightsController loads dashboard and populates telemetry successfully', () {
      expect(controller.overview, isNotNull);
      expect(controller.overview!.totalActiveGarments, 18);
      expect(controller.overview!.utilisationPercentage, 44.4);
      expect(controller.categoryDistribution.length, 3);
      expect(controller.mostWorn.length, 2);
      expect(controller.neglected.length, 2);
      expect(controller.colourDistribution.length, 3);
      expect(controller.recommendations.length, 2);
      expect(controller.capsuleSummary, isNotNull);
      expect(controller.styleMemory, isNotNull);
    });

    test('InsightsController changes period filter and reloads period data without clearing static metrics', () async {
      await controller.selectPeriod(AnalyticsPeriod.days7);

      expect(controller.selectedPeriod, AnalyticsPeriod.days7);
      expect(mockRepo.lastPeriodRequested, AnalyticsPeriod.days7);
      expect(controller.overview!.utilisationPercentage, 16.7);
      expect(controller.overview!.uniqueGarmentsWornInPeriod, 3);
      // Category distribution was preserved from initial dashboard load
      expect(controller.categoryDistribution.length, 3);
    });

    test('InsightsController loads cost-per-wear and outfit repetition', () async {
      await controller.loadCostPerWear();
      expect(controller.costPerWearSummary, isNotNull);
      expect(controller.costPerWearSummary!.totalGarmentsCount, 4);
      expect(controller.costPerWearSummary!.totalInvestment, 7700.0);

      await controller.loadOutfitRepetition();
      expect(controller.outfitRepetition.length, 1);
      expect(controller.outfitRepetition.first.outfitName, 'Office Smart Look');
    });

    test('InsightsController updates style memory persona and notes', () async {
      final success = await controller.updateStyleMemory(
        stylePersona: 'Architectural Minimalist',
        notes: 'Monochrome only',
      );

      expect(success, isTrue);
      expect(controller.styleMemory!.stylePersona, 'Architectural Minimalist');
      expect(controller.styleMemory!.notes, 'Monochrome only');
    });

    testWidgets('WardrobeUtilisationCard renders percentage, count ratio, and progress', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const WardrobeUtilisationCard(
            utilisationPercentage: 44.4,
            uniqueGarmentsWorn: 8,
            totalActiveGarments: 18,
            totalOutfitsWorn: 6,
            summaryText: 'You wore 8 of your 18 garments.',
          ),
        ),
      );
      await tester.pump();

      expect(find.text('WARDROBE UTILISATION'), findsOneWidget);
      expect(find.text('44%'), findsOneWidget);
      expect(find.text('8 of 18 Pieces Worn'), findsOneWidget);
      expect(find.text('6 total outfit logged appearances'), findsOneWidget);
      expect(find.text('You wore 8 of your 18 garments.'), findsOneWidget);
    });

    testWidgets('CategoryDistributionChart renders category bars and count percentages', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const CategoryDistributionChart(
            distribution: [
              CategoryDistribution(
                category: 'Tops',
                count: 7,
                percentageOfWardrobe: 38.9,
                activeCount: 7,
              ),
              CategoryDistribution(
                category: 'Bottoms',
                count: 5,
                percentageOfWardrobe: 27.8,
                activeCount: 5,
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(find.text('CATEGORY COMPOSITION'), findsOneWidget);
      expect(find.text('Tops'), findsOneWidget);
      expect(find.text('7 items (38.9%)'), findsOneWidget);
      expect(find.text('Bottoms'), findsOneWidget);
      expect(find.text('5 items (27.8%)'), findsOneWidget);
    });

    testWidgets('ColourDistributionChart renders palette and legend chips', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const ColourDistributionChart(
            distribution: [
              ColourDistribution(
                colorGroup: 'Blue',
                originalColors: ['Navy Blue'],
                count: 6,
                percentage: 33.3,
              ),
              ColourDistribution(
                colorGroup: 'White',
                originalColors: ['White'],
                count: 4,
                percentage: 22.2,
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(find.text('COLOUR PALETTE DISTRIBUTION'), findsOneWidget);
      expect(find.text('Top: Blue'), findsOneWidget);
      expect(find.text('Blue (33.3%)'), findsOneWidget);
      expect(find.text('White (22.2%)'), findsOneWidget);
    });

    testWidgets('CostPerWearCard renders price, wear count, and value tier badge', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const CostPerWearCard(
            item: CostPerWearItem(
              garmentId: 'CLO-001',
              garmentName: 'Classic White Shirt',
              mainCategory: 'Tops',
              primaryColor: 'White',
              purchasePrice: 2400.0,
              wearCount: 14,
              costPerWear: 171.4,
              valueTier: ValueTier.goodValue,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Classic White Shirt'), findsOneWidget);
      expect(find.text('Bought: ₹2400 • 14 Wears'), findsOneWidget);
      expect(find.text('₹171'), findsOneWidget);
      expect(find.text('/ wear'), findsOneWidget);
      expect(find.text('Good Value'), findsOneWidget);
    });

    testWidgets('WardrobeInsightsScreen renders app bar, badge, and quick jump pills', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildTestableWidget(
          WardrobeInsightsScreen(controller: controller),
        ),
      );
      await tester.pump();

      expect(find.text('Wardrobe Insights'), findsOneWidget);
      expect(find.text('PHASE 7'), findsOneWidget);
      expect(find.text('Cost-Per-Wear'), findsOneWidget);
      expect(find.text('Capsule Wardrobe'), findsOneWidget);
      expect(find.text('Outfit Repetition'), findsOneWidget);
      expect(find.text('Style Memory'), findsOneWidget);
      expect(find.text('WARDROBE UTILISATION'), findsOneWidget);
      expect(find.text('MOST WORN PIECES'), findsOneWidget);
      expect(find.text('NEGLECTED & UNUSED'), findsOneWidget);
    });

    testWidgets('CostPerWearScreen renders investment summary and filter chips', (tester) async {
      await controller.loadCostPerWear();
      await tester.pumpWidget(
        buildTestableWidget(
          CostPerWearScreen(controller: controller),
        ),
      );
      await tester.pump();

      expect(find.text('Cost-Per-Wear Analytics'), findsOneWidget);
      expect(find.text('TOTAL WARDROBE INVESTMENT'), findsOneWidget);
      expect(find.text('₹7700'), findsOneWidget);
      expect(find.text('All Items'), findsOneWidget);
      expect(find.text('Best Value'), findsWidgets);
      expect(find.text('Highest CPW'), findsOneWidget);
      expect(find.text('Unpriced'), findsNWidgets(2));
    });

    testWidgets('CapsuleWardrobeScreen renders versatility score and anchor pieces', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          CapsuleWardrobeScreen(controller: controller),
        ),
      );
      await tester.pump();

      expect(find.text('Capsule Wardrobe Intelligence'), findsOneWidget);
      expect(find.text('Capsule Versatility Score'), findsOneWidget);
      expect(find.text('CAPSULE ANCHOR PIECES'), findsOneWidget);
      expect(find.text('78.5%'), findsOneWidget);
      expect(find.text('16'), findsOneWidget);
    });

    testWidgets('OutfitRepetitionScreen renders recurring combinations header and empty/filled state', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          OutfitRepetitionScreen(controller: controller),
        ),
      );
      await tester.pump();

      expect(find.text('Outfit Repetition Analysis'), findsOneWidget);
      expect(find.text('Recurring Combinations'), findsOneWidget);
      expect(find.text('Office Smart Look'), findsOneWidget);
      expect(find.text('4 Wears'), findsOneWidget);
      expect(find.text('Avg interval: every 7.0 days'), findsOneWidget);
    });

    testWidgets('StyleMemoryScreen renders persona, empirical taste, and save button', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          StyleMemoryScreen(controller: controller),
        ),
      );
      await tester.pump();

      expect(find.text('Personal Style Memory'), findsOneWidget);
      expect(find.text('Style Persona'), findsOneWidget);
      expect(find.text('Smart Casual Classic'), findsNWidgets(2));
      expect(find.text('EMPIRICAL WEAR TASTE'), findsOneWidget);
      expect(find.text('CUSTOMIZE STYLE MEMORY'), findsOneWidget);
      expect(find.text('Save Preferences'), findsOneWidget);
    });
  });
}
