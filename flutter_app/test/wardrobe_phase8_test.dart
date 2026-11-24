import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tess/core/theme/app_theme.dart';
import 'package:tess/features/wardrobe/domain/entities/wishlist_item.dart';
import 'package:tess/features/wardrobe/domain/entities/wardrobe_gap.dart';
import 'package:tess/features/wardrobe/domain/entities/purchase_assessment.dart';
import 'package:tess/features/wardrobe/domain/entities/wishlist_summary.dart';
import 'package:tess/features/wardrobe/domain/entities/garment.dart';
import 'package:tess/features/wardrobe/domain/repositories/wishlist_repository.dart';
import 'package:tess/features/wardrobe/presentation/controllers/wishlist_controller.dart';
import 'package:tess/features/wardrobe/presentation/widgets/wishlist_priority_badge.dart';
import 'package:tess/features/wardrobe/presentation/widgets/wishlist_summary_card.dart';
import 'package:tess/features/wardrobe/presentation/widgets/wishlist_item_card.dart';
import 'package:tess/features/wardrobe/presentation/widgets/wardrobe_gap_card.dart';
import 'package:tess/features/wardrobe/presentation/widgets/purchase_assessment_card.dart';
import 'package:tess/features/wardrobe/presentation/screens/wishlist_screen.dart';
import 'package:tess/features/wardrobe/presentation/screens/wardrobe_gap_analysis_screen.dart';
import 'package:tess/features/wardrobe/presentation/screens/purchase_assessment_screen.dart';
import 'package:tess/features/wardrobe/presentation/screens/wishlist_conversion_screen.dart';

class MockWishlistRepository implements WishlistRepository {
  final List<WishlistItem> _items = [
    WishlistItem(
      id: 'wish_1',
      userId: 'test_user',
      name: 'Black Tailored Trousers',
      category: 'Bottoms',
      subcategory: 'Trousers',
      expectedPrice: 3500.0,
      expectedCurrency: 'INR',
      purchasePriority: PurchasePriority.high,
      occasion: 'Work',
      desiredColour: 'Black',
      status: WishlistStatus.considering,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      updatedAt: DateTime.now(),
    ),
    WishlistItem(
      id: 'wish_2',
      userId: 'test_user',
      name: 'Grey Wool Cardigan',
      category: 'Outerwear',
      subcategory: 'Cardigans',
      expectedPrice: 2800.0,
      expectedCurrency: 'INR',
      purchasePriority: PurchasePriority.medium,
      occasion: 'Casual',
      desiredColour: 'Grey',
      status: WishlistStatus.shortlisted,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      updatedAt: DateTime.now(),
    ),
    WishlistItem(
      id: 'wish_3',
      userId: 'test_user',
      name: 'White Casual Sneakers',
      category: 'Footwear',
      subcategory: 'Sneakers',
      expectedPrice: null, // Unpriced
      expectedCurrency: 'INR',
      purchasePriority: PurchasePriority.low,
      desiredColour: 'White',
      status: WishlistStatus.considering,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now(),
    ),
  ];

  @override
  Future<List<WishlistItem>> getWishlist({
    WishlistStatus? status,
    PurchasePriority? priority,
    String? category,
    String sortBy = 'created_at',
    String sortOrder = 'desc',
  }) async {
    return _items.where((i) {
      if (status != null && i.status != status) return false;
      if (priority != null && i.purchasePriority != priority) return false;
      if (category != null && i.category.toLowerCase() != category.toLowerCase()) return false;
      return true;
    }).toList();
  }

  @override
  Future<WishlistItem?> getWishlistItem(String id) async {
    try {
      return _items.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<WishlistItem> createWishlistItem({
    required String name,
    required String category,
    String? subcategory,
    String? referenceImagePath,
    double? expectedPrice,
    String expectedCurrency = 'INR',
    PurchasePriority purchasePriority = PurchasePriority.medium,
    String? occasion,
    String? desiredColour,
    String? desiredPattern,
    String? description,
    String? notes,
  }) async {
    final newItem = WishlistItem(
      id: 'wish_${_items.length + 1}',
      userId: 'test_user',
      name: name,
      category: category,
      subcategory: subcategory,
      referenceImagePath: referenceImagePath,
      expectedPrice: expectedPrice,
      expectedCurrency: expectedCurrency,
      purchasePriority: purchasePriority,
      occasion: occasion,
      desiredColour: desiredColour,
      desiredPattern: desiredPattern,
      description: description,
      notes: notes,
      status: WishlistStatus.considering,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _items.insert(0, newItem);
    return newItem;
  }

  @override
  Future<WishlistItem> updateWishlistItem(WishlistItem item) async {
    final idx = _items.indexWhere((i) => i.id == item.id);
    if (idx != -1) {
      _items[idx] = item;
    }
    return item;
  }

  @override
  Future<bool> deleteWishlistItem(String id) async {
    _items.removeWhere((i) => i.id == id);
    return true;
  }

  @override
  Future<WishlistItem> updateStatus(
    String id,
    WishlistStatus status, {
    double? actualPrice,
    String? actualCurrency,
    DateTime? purchasedAt,
  }) async {
    final item = await getWishlistItem(id);
    if (item == null) throw Exception('Item not found');
    final updated = item.copyWith(
      status: status,
      actualPurchasePrice: actualPrice,
      actualPurchaseCurrency: actualCurrency,
      purchasedAt: purchasedAt ?? (status == WishlistStatus.purchased ? DateTime.now() : null),
    );
    final idx = _items.indexWhere((i) => i.id == id);
    _items[idx] = updated;
    return updated;
  }

  @override
  Future<WishlistSummary> getSummary() async {
    return const WishlistSummary(
      totalItems: 3,
      highPriorityCount: 1,
      shortlistedCount: 1,
      purchasedCount: 0,
      consideringCount: 2,
      notInterestedCount: 0,
      estimatedWishlistValue: {'INR': 6300.0},
      purchasedTotalValue: {},
      unpricedItemsCount: 1,
    );
  }

  @override
  Future<String> uploadReferenceImage(List<int> bytes, String filename) async {
    return 'assets/images/wishlist_placeholder.jpg';
  }

  @override
  Future<Map<String, dynamic>> convertToWardrobe(
    String id, {
    double? actualPrice,
    String? actualCurrency,
    DateTime? purchaseDate,
    String? laundryStatus,
    String? garmentNameOverride,
    String? primaryColor,
  }) async {
    final item = await getWishlistItem(id);
    if (item == null) throw Exception('Item not found');

    // Idempotency: if already converted, return existing
    if (item.convertedGarmentId != null) {
      return {
        'wishlist_item': item,
        'garment_id': item.convertedGarmentId,
        'message': 'Already converted',
      };
    }

    const garmentId = 'CLO-WISH-99';
    final updated = item.copyWith(
      status: WishlistStatus.purchased,
      convertedGarmentId: garmentId,
      actualPurchasePrice: actualPrice ?? item.expectedPrice,
      actualPurchaseCurrency: actualCurrency ?? item.expectedCurrency,
      purchasedAt: DateTime.now(),
    );
    final idx = _items.indexWhere((i) => i.id == id);
    _items[idx] = updated;

    final newGarment = Garment(
      id: garmentId,
      userId: 'test_user',
      name: garmentNameOverride ?? item.name,
      mainCategory: item.category,
      subcategory: item.subcategory,
      primaryColor: primaryColor ?? item.desiredColour ?? 'Black',
      purchasePrice: actualPrice ?? item.expectedPrice,
      laundryStatus: null, // Unassigned safety!
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return {
      'wishlist_item': updated,
      'garment': newGarment,
      'garment_id': garmentId,
    };
  }

  @override
  Future<List<WardrobeGap>> getWardrobeGaps() async {
    return const [
      WardrobeGap(
        id: 'gap_bottoms_imbalance',
        title: 'Bottoms & Kurta Pairing Imbalance',
        category: 'Bottoms',
        suggestedSubcategory: 'Trousers',
        suggestedColor: 'Black',
        supportingEvidence: 'You own 7 upper pieces but only 2 versatile bottoms.',
        currentInventoryCount: 2,
        compatibleExistingGarmentIds: ['CLO-001', 'CLO-003'],
        compatibleExistingGarmentNames: ['Classic White Shirt', 'Embroidered Kurta'],
        potentialOutfitCombinationsGained: 6,
        explanation: 'Adding versatile black trousers enables multiple new work and festive looks.',
        confidenceScore: 0.92,
        severity: GapSeverity.high,
      ),
    ];
  }

  @override
  Future<List<GarmentMatch>> matchExistingGarments(
    String category, {
    String? subcategory,
    String? desiredColour,
  }) async {
    return [
      const GarmentMatch(
        garmentId: 'CLO-001',
        garmentName: 'Classic White Shirt',
        mainCategory: 'Tops',
        subcategory: 'Shirts',
        primaryColor: 'White',
        similarityReason: 'Matches category (Tops) and color (White)',
        matchType: GarmentMatchType.exactColorAndCategory,
      ),
    ];
  }

  @override
  Future<PurchaseAssessment> assessWishlistItem(String id) async {
    final item = await getWishlistItem(id);
    final isBottom = item?.category == 'Bottoms';

    return PurchaseAssessment(
      wishlistItemId: id,
      wishlistItemName: item?.name ?? 'Black Tailored Trousers',
      outcome: isBottom ? AssessmentOutcome.strongAddition : AssessmentOutcome.potentiallyUseful,
      headline: isBottom ? 'Strong Wardrobe Addition' : 'Potentially Useful Addition',
      explanation: isBottom
          ? 'Fills an authentic wardrobe gap in Bottoms and pairs with 5 existing tops.'
          : 'Offers styling potential and expands your seasonal choices.',
      hasSimilarOwned: !isBottom,
      existingSimilarGarments: isBottom
          ? []
          : [
              const GarmentMatch(
                garmentId: 'CLO-001',
                garmentName: 'Classic White Shirt',
                mainCategory: 'Tops',
                subcategory: 'Shirts',
                primaryColor: 'White',
                similarityReason: 'You already own similar white tops',
                matchType: GarmentMatchType.exactColorAndCategory,
              ),
            ],
      fillsCategoryGap: isBottom,
      fillsColourGap: true,
      compatiblePiecesCount: 5,
      potentialNewCombinations: 6,
      assessmentScore: isBottom ? 85.0 : 58.0,
      contributingFactors: const [
        'Directly resolves a detected wardrobe gap in Bottoms',
        'Pairs with 5 existing upper pieces',
        'High purchase priority set by user',
      ],
      recommendationAction: 'Prioritize this purchase: it enhances wardrobe versatility.',
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

  group('Phase 8: Wardrobe Wishlist & Shopping Intelligence Unit & Controller Tests', () {
    late MockWishlistRepository repository;
    late WishlistController controller;

    setUp(() async {
      repository = MockWishlistRepository();
      controller = WishlistController(repository: repository);
      await controller.loadDashboard();
    });

    test('WishlistController loads dashboard, summary, and wardrobe gaps', () {
      expect(controller.items.length, 3);
      expect(controller.summary, isNotNull);
      expect(controller.summary!.totalItems, 3);
      expect(controller.summary!.highPriorityCount, 1);
      expect(controller.summary!.primaryEstimatedValue, 6300.0);
      expect(controller.summary!.unpricedItemsCount, 1);
      expect(controller.gaps.length, 1);
      expect(controller.gaps.first.title, 'Bottoms & Kurta Pairing Imbalance');
    });

    test('WishlistController filters items by purchase priority', () async {
      await controller.setPriorityFilter(PurchasePriority.high);
      expect(controller.filteredItems.length, 1);
      expect(controller.filteredItems.first.name, 'Black Tailored Trousers');

      await controller.setPriorityFilter(PurchasePriority.low);
      expect(controller.filteredItems.length, 1);
      expect(controller.filteredItems.first.name, 'White Casual Sneakers');
    });

    test('WishlistController creates a new wishlist item', () async {
      final created = await controller.createItem(
        name: 'Denim Jacket',
        category: 'Outerwear',
        expectedPrice: 4200.0,
        purchasePriority: PurchasePriority.medium,
        desiredColour: 'Blue',
      );

      expect(created, isNotNull);
      expect(controller.items.length, 4);
      expect(controller.items.first.name, 'Denim Jacket');
    });

    test('WishlistController converts purchased wishlist item to wardrobe with idempotency', () async {
      final res = await controller.convertToWardrobe(
        'wish_1',
        actualPrice: 3299.0,
        actualCurrency: 'INR',
      );

      expect(res, isNotNull);
      final item = controller.items.firstWhere((i) => i.id == 'wish_1');
      expect(item.status, WishlistStatus.purchased);
      expect(item.convertedGarmentId, isNotNull);
      expect(item.actualPurchasePrice, 3299.0);
      expect(item.expectedPrice, 3500.0); // Preserved expected price!

      // Idempotency: second conversion should return existing
      final res2 = await controller.convertToWardrobe('wish_1');
      expect(res2, isNotNull);
      expect(res2!['garment_id'], item.convertedGarmentId);
    });

    test('WishlistController evaluates purchase assessment', () async {
      await controller.assessItem('wish_1');
      expect(controller.currentAssessment, isNotNull);
      expect(controller.currentAssessment!.outcome, AssessmentOutcome.strongAddition);
      expect(controller.currentAssessment!.assessmentScore, 85.0);
      expect(controller.currentAssessment!.potentialNewCombinations, 6);
    });
  });

  group('Phase 8: Presentation Widgets & Screens UI Tests', () {
    late MockWishlistRepository repository;
    late WishlistController controller;

    setUp(() async {
      repository = MockWishlistRepository();
      controller = WishlistController(repository: repository);
      await controller.loadDashboard();
    });

    testWidgets('WishlistPriorityBadge renders priority label and styling', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const WishlistPriorityBadge(priority: PurchasePriority.high),
        ),
      );
      await tester.pump();
      expect(find.text('HIGH'), findsOneWidget);
    });

    testWidgets('WishlistSummaryCard renders estimated budget and counts', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const WishlistSummaryCard(
            summary: WishlistSummary(
              totalItems: 3,
              highPriorityCount: 1,
              shortlistedCount: 1,
              purchasedCount: 0,
              consideringCount: 2,
              notInterestedCount: 0,
              estimatedWishlistValue: {'INR': 6300.0},
              purchasedTotalValue: {},
              unpricedItemsCount: 1,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('WISHLIST OVERVIEW'), findsOneWidget);
      expect(find.text('₹6300'), findsOneWidget);
      expect(find.text('3 ITEMS'), findsOneWidget);
      expect(find.text('1 item(s) without estimated price'), findsOneWidget);
    });

    testWidgets('WishlistItemCard renders name, price, and assess button', (tester) async {
      final item = WishlistItem(
        id: 'wish_1',
        userId: 'test_user',
        name: 'Black Tailored Trousers',
        category: 'Bottoms',
        expectedPrice: 3500.0,
        expectedCurrency: 'INR',
        purchasePriority: PurchasePriority.high,
        status: WishlistStatus.considering,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        buildTestableWidget(
          WishlistItemCard(
            item: item,
            onTap: () {},
            onAssess: () {},
            onToggleStatus: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Black Tailored Trousers'), findsOneWidget);
      expect(find.text('₹3500'), findsOneWidget);
      expect(find.text('Assess'), findsOneWidget);
    });

    testWidgets('WardrobeGapCard renders gap title and potential combination stats', (tester) async {
      const gap = WardrobeGap(
        id: 'gap_1',
        title: 'Bottoms & Kurta Pairing Imbalance',
        category: 'Bottoms',
        supportingEvidence: 'You own 7 upper pieces but only 2 bottoms.',
        currentInventoryCount: 2,
        potentialOutfitCombinationsGained: 6,
        explanation: 'Adding versatile black trousers enables new combinations.',
        confidenceScore: 0.92,
        severity: GapSeverity.high,
      );

      await tester.pumpWidget(
        buildTestableWidget(
          WardrobeGapCard(
            gap: gap,
            onAddWishlistItem: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Bottoms & Kurta Pairing Imbalance'), findsOneWidget);
      expect(find.text('+6 new outfit combinations possible'), findsOneWidget);
      expect(find.text('Add to Wishlist to Fill Gap'), findsOneWidget);
    });

    testWidgets('PurchaseAssessmentCard renders score, outcome and factors', (tester) async {
      const assessment = PurchaseAssessment(
        wishlistItemId: 'wish_1',
        wishlistItemName: 'Black Tailored Trousers',
        outcome: AssessmentOutcome.strongAddition,
        headline: 'Strong Wardrobe Addition',
        explanation: 'Fills an authentic gap in Bottoms.',
        hasSimilarOwned: false,
        fillsCategoryGap: true,
        fillsColourGap: true,
        compatiblePiecesCount: 5,
        potentialNewCombinations: 6,
        assessmentScore: 85.0,
        contributingFactors: ['Resolves Bottoms gap', 'Pairs with 5 tops'],
        recommendationAction: 'Prioritize this purchase.',
      );

      await tester.pumpWidget(
        buildTestableWidget(
          const PurchaseAssessmentCard(assessment: assessment),
        ),
      );
      await tester.pump();

      expect(find.text('STRONG WARDROBE ADDITION'), findsOneWidget);
      expect(find.text('85 / 100'), findsOneWidget);
      expect(find.text('Strong Wardrobe Addition'), findsOneWidget);
      expect(find.text('Prioritize this purchase.'), findsOneWidget);
    });

    testWidgets('WishlistScreen renders app bar, badge, and summary card', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildTestableWidget(
          WishlistScreen(controller: controller),
        ),
      );
      await tester.pump();

      expect(find.text('Wardrobe Wishlist'), findsOneWidget);
      expect(find.text('PHASE 8'), findsOneWidget);
      expect(find.text('WISHLIST OVERVIEW'), findsOneWidget);
      expect(find.text('1 Wardrobe Gaps Identified'), findsOneWidget);
      expect(find.text('Add to Wishlist'), findsOneWidget);
    });

    testWidgets('WardrobeGapAnalysisScreen renders gap evidence and action', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          WardrobeGapAnalysisScreen(controller: controller),
        ),
      );
      await tester.pump();

      expect(find.text('Wardrobe Gap Analysis'), findsOneWidget);
      expect(find.text('EMPIRICAL WARDROBE GAPS'), findsOneWidget);
      expect(find.text('Bottoms & Kurta Pairing Imbalance'), findsOneWidget);
    });

    testWidgets('PurchaseAssessmentScreen renders decision support breakdown', (tester) async {
      final item = controller.items.first;

      await tester.pumpWidget(
        buildTestableWidget(
          PurchaseAssessmentScreen(
            item: item,
            controller: controller,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Purchase Assessment'), findsOneWidget);
      expect(find.text('Compatible Pieces'), findsOneWidget);
      expect(find.text('Potential Looks'), findsOneWidget);
    });

    testWidgets('WishlistConversionScreen renders unassigned laundry safety banner', (tester) async {
      final item = controller.items.first;

      await tester.pumpWidget(
        buildTestableWidget(
          WishlistConversionScreen(
            item: item,
            controller: controller,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Confirm Purchase & Register'), findsOneWidget);
      expect(find.text('Unassigned Laundry Status Protection'), findsOneWidget);
      expect(find.text('ACTUAL PURCHASE DETAILS'), findsOneWidget);
      expect(find.text('Confirm & Register in My Wardrobe'), findsOneWidget);
    });
  });
}
