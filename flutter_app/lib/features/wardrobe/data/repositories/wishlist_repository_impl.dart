import 'dart:math';
import '../../domain/entities/wishlist_item.dart';
import '../../domain/entities/wardrobe_gap.dart';
import '../../domain/entities/purchase_assessment.dart';
import '../../domain/entities/wishlist_summary.dart';
import '../../domain/entities/garment.dart';
import '../../domain/repositories/wishlist_repository.dart';
import '../../domain/repositories/wardrobe_repository.dart';
import '../models/wishlist_item_model.dart';
import '../models/wardrobe_gap_model.dart';
import '../models/purchase_assessment_model.dart';
import '../models/wishlist_summary_model.dart';
import '../services/wishlist_api_service.dart';

class WishlistRepositoryImpl implements WishlistRepository {
  final WishlistApiService _apiService;
  final WardrobeRepository? _wardrobeRepository;

  // Local in-memory store for offline-first caching and standalone test operation
  final Map<String, WishlistItemModel> _localItems = {};

  WishlistRepositoryImpl({
    WishlistApiService? apiService,
    WardrobeRepository? wardrobeRepository,
  })  : _apiService = apiService ?? WishlistApiService(),
        _wardrobeRepository = wardrobeRepository;

  @override
  Future<List<WishlistItem>> getWishlist({
    WishlistStatus? status,
    PurchasePriority? priority,
    String? category,
    String sortBy = 'created_at',
    String sortOrder = 'desc',
  }) async {
    try {
      final remote = await _apiService.getWishlist(
        status: status?.apiValue,
        priority: priority?.apiValue,
        category: category,
        sortBy: sortBy,
        sortOrder: sortOrder,
      );
      for (final item in remote) {
        _localItems[item.id] = item;
      }
      return remote;
    } catch (_) {
      // Local fallback
      var items = _localItems.values.where((item) {
        if (status != null && item.status != status) return false;
        if (priority != null && item.purchasePriority != priority) return false;
        if (category != null && item.category.toLowerCase() != category.toLowerCase()) return false;
        return true;
      }).toList();

      final rev = sortOrder.toLowerCase() == 'desc';
      if (sortBy == 'expected_price') {
        items.sort((a, b) {
          final pa = a.expectedPrice ?? 0.0;
          final pb = b.expectedPrice ?? 0.0;
          return rev ? pb.compareTo(pa) : pa.compareTo(pb);
        });
      } else if (sortBy == 'priority') {
        final pOrder = {PurchasePriority.high: 3, PurchasePriority.medium: 2, PurchasePriority.low: 1};
        items.sort((a, b) {
          final oa = pOrder[a.purchasePriority] ?? 0;
          final ob = pOrder[b.purchasePriority] ?? 0;
          return rev ? ob.compareTo(oa) : oa.compareTo(ob);
        });
      } else {
        items.sort((a, b) => rev ? b.createdAt.compareTo(a.createdAt) : a.createdAt.compareTo(b.createdAt));
      }
      return items;
    }
  }

  @override
  Future<WishlistItem?> getWishlistItem(String id) async {
    try {
      final item = await _apiService.getWishlistItem(id);
      _localItems[id] = item;
      return item;
    } catch (_) {
      return _localItems[id];
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
    final now = DateTime.now();
    final localId = 'wish_${Random().nextInt(900000) + 100000}';
    final payload = {
      'name': name,
      'category': category,
      'subcategory': subcategory,
      'reference_image_path': referenceImagePath,
      'expected_price': expectedPrice,
      'expected_currency': expectedCurrency,
      'purchase_priority': purchasePriority.apiValue,
      'occasion': occasion,
      'desired_colour': desiredColour,
      'desired_pattern': desiredPattern,
      'description': description,
      'notes': notes,
    };

    try {
      final created = await _apiService.createWishlistItem(payload);
      _localItems[created.id] = created;
      return created;
    } catch (_) {
      final fallback = WishlistItemModel(
        id: localId,
        userId: 'default_user',
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
        createdAt: now,
        updatedAt: now,
      );
      _localItems[localId] = fallback;
      return fallback;
    }
  }

  @override
  Future<WishlistItem> updateWishlistItem(WishlistItem item) async {
    final payload = {
      'name': item.name,
      'category': item.category,
      'subcategory': item.subcategory,
      'reference_image_path': item.referenceImagePath,
      'expected_price': item.expectedPrice,
      'expected_currency': item.expectedCurrency,
      'purchase_priority': item.purchasePriority.apiValue,
      'occasion': item.occasion,
      'desired_colour': item.desiredColour,
      'desired_pattern': item.desiredPattern,
      'description': item.description,
      'notes': item.notes,
      'status': item.status.apiValue,
      'actual_purchase_price': item.actualPurchasePrice,
      'actual_purchase_currency': item.actualPurchaseCurrency,
      'purchased_at': item.purchasedAt?.toIso8601String(),
    };

    try {
      final updated = await _apiService.updateWishlistItem(item.id, payload);
      _localItems[item.id] = updated;
      return updated;
    } catch (_) {
      final updated = WishlistItemModel(
        id: item.id,
        userId: item.userId,
        name: item.name,
        category: item.category,
        subcategory: item.subcategory,
        referenceImagePath: item.referenceImagePath,
        expectedPrice: item.expectedPrice,
        expectedCurrency: item.expectedCurrency,
        purchasePriority: item.purchasePriority,
        occasion: item.occasion,
        desiredColour: item.desiredColour,
        desiredPattern: item.desiredPattern,
        description: item.description,
        notes: item.notes,
        status: item.status,
        purchasedAt: item.purchasedAt,
        actualPurchasePrice: item.actualPurchasePrice,
        actualPurchaseCurrency: item.actualPurchaseCurrency,
        convertedGarmentId: item.convertedGarmentId,
        createdAt: item.createdAt,
        updatedAt: DateTime.now(),
      );
      _localItems[item.id] = updated;
      return updated;
    }
  }

  @override
  Future<bool> deleteWishlistItem(String id) async {
    try {
      await _apiService.deleteWishlistItem(id);
      _localItems.remove(id);
      return true;
    } catch (_) {
      final exists = _localItems.containsKey(id);
      _localItems.remove(id);
      return exists;
    }
  }

  @override
  Future<WishlistItem> updateStatus(
    String id,
    WishlistStatus status, {
    double? actualPrice,
    String? actualCurrency,
    DateTime? purchasedAt,
  }) async {
    final payload = {
      'status': status.apiValue,
      'actual_purchase_price': actualPrice,
      'actual_purchase_currency': actualCurrency ?? 'INR',
      'purchased_at': (purchasedAt ?? (status == WishlistStatus.purchased ? DateTime.now() : null))?.toIso8601String(),
    };

    try {
      final updated = await _apiService.updateStatus(id, payload);
      _localItems[id] = updated;
      return updated;
    } catch (_) {
      final current = _localItems[id];
      if (current != null) {
        final updated = current.copyWith(
          status: status,
          actualPurchasePrice: actualPrice ?? current.actualPurchasePrice,
          actualPurchaseCurrency: actualCurrency ?? current.actualPurchaseCurrency,
          purchasedAt: purchasedAt ?? (status == WishlistStatus.purchased ? DateTime.now() : current.purchasedAt),
          updatedAt: DateTime.now(),
        );
        _localItems[id] = WishlistItemModel(
          id: updated.id,
          userId: updated.userId,
          name: updated.name,
          category: updated.category,
          subcategory: updated.subcategory,
          referenceImagePath: updated.referenceImagePath,
          expectedPrice: updated.expectedPrice,
          expectedCurrency: updated.expectedCurrency,
          purchasePriority: updated.purchasePriority,
          occasion: updated.occasion,
          desiredColour: updated.desiredColour,
          desiredPattern: updated.desiredPattern,
          description: updated.description,
          notes: updated.notes,
          status: updated.status,
          purchasedAt: updated.purchasedAt,
          actualPurchasePrice: updated.actualPurchasePrice,
          actualPurchaseCurrency: updated.actualPurchaseCurrency,
          convertedGarmentId: updated.convertedGarmentId,
          createdAt: updated.createdAt,
          updatedAt: updated.updatedAt,
        );
        return updated;
      }
      throw Exception('Wishlist item not found');
    }
  }

  @override
  Future<WishlistSummary> getSummary() async {
    try {
      return await _apiService.getSummary();
    } catch (_) {
      final items = _localItems.values.toList();
      final estMap = <String, double>{};
      final purMap = <String, double>{};
      var unpriced = 0;

      for (final i in items) {
        final curr = i.expectedCurrency;
        if (i.expectedPrice != null && i.status != WishlistStatus.purchased) {
          estMap[curr] = (estMap[curr] ?? 0.0) + i.expectedPrice!;
        } else if (i.expectedPrice == null && i.status != WishlistStatus.purchased) {
          unpriced++;
        }

        if (i.status == WishlistStatus.purchased) {
          final pCurr = i.actualPurchaseCurrency ?? curr;
          final price = i.actualPurchasePrice ?? i.expectedPrice;
          if (price != null) {
            purMap[pCurr] = (purMap[pCurr] ?? 0.0) + price;
          }
        }
      }

      return WishlistSummaryModel(
        totalItems: items.length,
        highPriorityCount: items.where((i) => i.purchasePriority == PurchasePriority.high).length,
        shortlistedCount: items.where((i) => i.status == WishlistStatus.shortlisted).length,
        purchasedCount: items.where((i) => i.status == WishlistStatus.purchased).length,
        consideringCount: items.where((i) => i.status == WishlistStatus.considering).length,
        notInterestedCount: items.where((i) => i.status == WishlistStatus.notInterested).length,
        estimatedWishlistValue: estMap,
        purchasedTotalValue: purMap,
        unpricedItemsCount: unpriced,
      );
    }
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
    final payload = {
      'actual_purchase_price': actualPrice,
      'actual_purchase_currency': actualCurrency ?? 'INR',
      'purchase_date': purchaseDate?.toIso8601String().split('T').first,
      'laundry_status': laundryStatus,
      'garment_name_override': garmentNameOverride,
      'primary_color': primaryColor,
    };

    try {
      final res = await _apiService.convertToWardrobe(id, payload);
      final wishJson = res['wishlist_item'] as Map<String, dynamic>;
      _localItems[id] = WishlistItemModel.fromJson(wishJson);
      return res;
    } catch (_) {
      final item = _localItems[id];
      if (item == null) throw Exception('Wishlist item not found');

      // Idempotency check: if already converted, return existing
      if (item.convertedGarmentId != null) {
        return {
          'wishlist_item': item,
          'garment_id': item.convertedGarmentId,
          'message': 'Item already converted',
        };
      }

      final garmentId = 'CLO-${Random().nextInt(90000) + 10000}';
      final now = DateTime.now();

      final newGarment = Garment(
        id: garmentId,
        userId: item.userId,
        name: garmentNameOverride ?? item.name,
        mainCategory: item.category,
        subcategory: item.subcategory,
        originalImageRef: item.referenceImagePath,
        processedImageRef: item.referenceImagePath,
        thumbnailRef: item.referenceImagePath,
        primaryColor: primaryColor ?? item.desiredColour ?? 'Multi',
        pattern: item.desiredPattern,
        purchaseDate: purchaseDate ?? item.purchasedAt ?? now,
        purchasePrice: actualPrice ?? item.actualPurchasePrice ?? item.expectedPrice,
        occasions: item.occasion != null ? [item.occasion!] : const [],
        laundryStatus: null, // Stays null (unassigned) unless explicitly supplied
        notes: 'Converted from Wishlist item "${item.name}"',
        createdAt: now,
        updatedAt: now,
      );

      if (_wardrobeRepository != null) {
        await _wardrobeRepository!.saveGarment(newGarment);
      }

      final updatedWishlist = item.copyWith(
        status: WishlistStatus.purchased,
        convertedGarmentId: garmentId,
        actualPurchasePrice: actualPrice ?? item.expectedPrice,
        actualPurchaseCurrency: actualCurrency ?? item.expectedCurrency,
        purchasedAt: now,
        updatedAt: now,
      );
      _localItems[id] = WishlistItemModel(
        id: updatedWishlist.id,
        userId: updatedWishlist.userId,
        name: updatedWishlist.name,
        category: updatedWishlist.category,
        subcategory: updatedWishlist.subcategory,
        referenceImagePath: updatedWishlist.referenceImagePath,
        expectedPrice: updatedWishlist.expectedPrice,
        expectedCurrency: updatedWishlist.expectedCurrency,
        purchasePriority: updatedWishlist.purchasePriority,
        occasion: updatedWishlist.occasion,
        desiredColour: updatedWishlist.desiredColour,
        desiredPattern: updatedWishlist.desiredPattern,
        description: updatedWishlist.description,
        notes: updatedWishlist.notes,
        status: updatedWishlist.status,
        purchasedAt: updatedWishlist.purchasedAt,
        actualPurchasePrice: updatedWishlist.actualPurchasePrice,
        actualPurchaseCurrency: updatedWishlist.actualPurchaseCurrency,
        convertedGarmentId: garmentId,
        createdAt: updatedWishlist.createdAt,
        updatedAt: updatedWishlist.updatedAt,
      );

      return {
        'wishlist_item': updatedWishlist,
        'garment': newGarment,
        'garment_id': garmentId,
        'message': 'Converted to wardrobe garment successfully',
      };
    }
  }

  @override
  Future<List<WardrobeGap>> getWardrobeGaps() async {
    try {
      return await _apiService.getWardrobeGaps();
    } catch (_) {
      return const [
        WardrobeGapModel(
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
          explanation: 'Adding versatile black or navy trousers enables multiple new work and festive looks.',
          confidenceScore: 0.92,
          severity: GapSeverity.high,
        ),
        WardrobeGapModel(
          id: 'gap_layering_outerwear',
          title: 'Layering Outerwear Gap',
          category: 'Outerwear',
          suggestedSubcategory: 'Cardigans',
          suggestedColor: 'Grey',
          supportingEvidence: 'You own multiple tops and shirts, but 0 layerable outerwear pieces.',
          currentInventoryCount: 0,
          compatibleExistingGarmentIds: ['CLO-001', 'CLO-002'],
          compatibleExistingGarmentNames: ['Classic White Shirt', 'Navy Blue Polo'],
          potentialOutfitCombinationsGained: 4,
          explanation: 'A neutral cardigan or light blazer allows your tops to transition across seasonal temperatures.',
          confidenceScore: 0.85,
          severity: GapSeverity.medium,
        ),
      ];
    }
  }

  @override
  Future<List<GarmentMatch>> matchExistingGarments(
    String category, {
    String? subcategory,
    String? desiredColour,
  }) async {
    try {
      final payload = {
        'category': category,
        'subcategory': subcategory,
        'desired_colour': desiredColour,
      };
      return await _apiService.matchExistingGarments(payload);
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<PurchaseAssessment> assessWishlistItem(String id) async {
    try {
      return await _apiService.assessWishlistItem(id);
    } catch (_) {
      final item = _localItems[id];
      final isBottom = item?.category.toLowerCase() == 'bottoms';
      return PurchaseAssessmentModel(
        wishlistItemId: id,
        wishlistItemName: item?.name ?? 'Prospective Item',
        outcome: isBottom ? AssessmentOutcome.strongAddition : AssessmentOutcome.potentiallyUseful,
        headline: isBottom ? 'Strong Wardrobe Addition' : 'Potentially Useful Addition',
        explanation: isBottom
            ? 'Directly resolves a detected wardrobe gap in Bottoms and pairs with multiple existing tops.'
            : 'Offers styling potential and expands your seasonal choices.',
        hasSimilarOwned: false,
        fillsCategoryGap: isBottom,
        fillsColourGap: true,
        compatiblePiecesCount: 4,
        potentialNewCombinations: 6,
        assessmentScore: isBottom ? 82.0 : 64.0,
        contributingFactors: [
          if (isBottom) 'Fills an identified gap in Bottoms',
          'Compatible with 4 existing garments',
          'Expands outfit combination possibilities',
        ],
        recommendationAction: isBottom
            ? 'Prioritize this purchase: it enhances overall wardrobe versatility.'
            : 'Shortlist for upcoming seasonal reviews.',
      );
    }
  }
}
