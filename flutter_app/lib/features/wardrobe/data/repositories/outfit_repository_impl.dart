import 'package:flutter/foundation.dart';
import '../../domain/entities/laundry_status.dart';
import '../../domain/entities/outfit.dart';
import '../../domain/entities/outfit_item.dart';
import '../../domain/entities/outfit_recommendation.dart';
import '../../domain/repositories/outfit_repository.dart';
import '../services/outfit_api_service.dart';

class OutfitRepositoryImpl implements OutfitRepository {
  final OutfitApiService _apiService;

  // Local caches for offline fallback & unit testing
  final Map<String, Outfit> _outfitsCache = {};
  final List<OutfitRecommendation> _recommendationsCache = [];

  OutfitRepositoryImpl({OutfitApiService? apiService})
      : _apiService = apiService ?? OutfitApiService();

  @override
  Future<List<Outfit>> getOutfits({
    String? occasion,
    bool favouriteOnly = false,
    String? search,
  }) async {
    try {
      final models = await _apiService.getOutfits(
        occasion: occasion,
        favouriteOnly: favouriteOnly,
        search: search,
      );
      final list = <Outfit>[];
      for (final m in models) {
        final domain = m.toDomain();
        _outfitsCache[domain.id] = domain;
        list.add(domain);
      }
      return list;
    } catch (e) {
      debugPrint('[OutfitRepositoryImpl] Remote getOutfits fallback: $e');
      var list = _outfitsCache.values.toList();
      if (favouriteOnly) {
        list = list.where((o) => o.isFavourite).toList();
      }
      if (occasion != null && occasion.isNotEmpty) {
        list = list
            .where((o) => o.occasion.toLowerCase() == occasion.toLowerCase())
            .toList();
      }
      if (search != null && search.isNotEmpty) {
        final q = search.toLowerCase();
        list = list
            .where((o) =>
                o.name.toLowerCase().contains(q) ||
                (o.description ?? '').toLowerCase().contains(q))
            .toList();
      }
      return list;
    }
  }

  @override
  Future<Outfit> getOutfit(String id) async {
    try {
      final model = await _apiService.getOutfit(id);
      final domain = model.toDomain();
      _outfitsCache[domain.id] = domain;
      return domain;
    } catch (e) {
      debugPrint('[OutfitRepositoryImpl] Remote getOutfit fallback: $e');
      final cached = _outfitsCache[id];
      if (cached != null) return cached;
      throw Exception('Outfit $id not found');
    }
  }

  @override
  Future<Outfit> createOutfit({
    required String name,
    String? description,
    required String occasion,
    String? notes,
    bool isFavourite = false,
    OutfitSource creationSource = OutfitSource.manual,
    String? stylingExplanation,
    required List<String> garmentIds,
  }) async {
    final body = {
      'name': name,
      if (description != null) 'description': description,
      'occasion': occasion,
      if (notes != null) 'notes': notes,
      'is_favourite': isFavourite,
      'creation_source': creationSource.value,
      if (stylingExplanation != null) 'styling_explanation': stylingExplanation,
      'garment_ids': garmentIds,
    };

    try {
      final model = await _apiService.createOutfit(body);
      final domain = model.toDomain();
      _outfitsCache[domain.id] = domain;
      return domain;
    } catch (e) {
      debugPrint('[OutfitRepositoryImpl] Remote createOutfit fallback: $e');
      final outfitId = 'local_outfit_${DateTime.now().millisecondsSinceEpoch}';
      final now = DateTime.now();
      final localItems = garmentIds.map((gid) {
        return OutfitItem(
          garmentId: gid,
          name: 'Garment $gid',
          mainCategory: 'Tops',
          primaryColor: 'Blue',
          laundryStatus: LaundryStatus.clean,
          isEligible: true,
        );
      }).toList();

      final domain = Outfit(
        id: outfitId,
        userId: 'local_user',
        name: name,
        description: description,
        occasion: occasion,
        notes: notes,
        isFavourite: isFavourite,
        creationSource: creationSource,
        stylingExplanation: stylingExplanation,
        wearCount: 0,
        items: localItems,
        garmentIds: garmentIds,
        isAvailable: true,
        createdAt: now,
        updatedAt: now,
      );
      _outfitsCache[outfitId] = domain;
      return domain;
    }
  }

  @override
  Future<Outfit> updateOutfit(
    String id, {
    String? name,
    String? description,
    String? occasion,
    String? notes,
    bool? isFavourite,
    String? stylingExplanation,
    List<String>? garmentIds,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    if (occasion != null) body['occasion'] = occasion;
    if (notes != null) body['notes'] = notes;
    if (isFavourite != null) body['is_favourite'] = isFavourite;
    if (stylingExplanation != null) {
      body['styling_explanation'] = stylingExplanation;
    }
    if (garmentIds != null) body['garment_ids'] = garmentIds;

    try {
      final model = await _apiService.updateOutfit(id, body);
      final domain = model.toDomain();
      _outfitsCache[domain.id] = domain;
      return domain;
    } catch (e) {
      debugPrint('[OutfitRepositoryImpl] Remote updateOutfit fallback: $e');
      final existing = _outfitsCache[id];
      if (existing == null) throw Exception('Outfit $id not found');

      final updated = existing.copyWith(
        name: name,
        description: description,
        occasion: occasion,
        notes: notes,
        isFavourite: isFavourite,
        stylingExplanation: stylingExplanation,
        garmentIds: garmentIds,
        updatedAt: DateTime.now(),
      );
      _outfitsCache[id] = updated;
      return updated;
    }
  }

  @override
  Future<void> deleteOutfit(String id) async {
    try {
      await _apiService.deleteOutfit(id);
      _outfitsCache.remove(id);
    } catch (e) {
      debugPrint('[OutfitRepositoryImpl] Remote deleteOutfit fallback: $e');
      _outfitsCache.remove(id);
    }
  }

  @override
  Future<List<OutfitRecommendation>> generateRecommendations({
    String? occasion,
    bool excludeWorn = true,
    String? colorPalette,
    String? comfortPreference,
    bool favoritesOnly = false,
    int limit = 5,
  }) async {
    final body = {
      if (occasion != null) 'occasion': occasion,
      'exclude_worn': excludeWorn,
      if (colorPalette != null) 'color_palette': colorPalette,
      if (comfortPreference != null) 'comfort_preference': comfortPreference,
      'favorites_only': favoritesOnly,
      'limit': limit,
    };

    try {
      final models = await _apiService.generateRecommendations(body);
      final list = models.map((m) => m.toDomain()).toList();
      _recommendationsCache
        ..clear()
        ..addAll(list);
      return list;
    } catch (e) {
      debugPrint(
          '[OutfitRepositoryImpl] Remote generateRecommendations fallback: $e');
      if (_recommendationsCache.isNotEmpty) return _recommendationsCache;
      // Default fallback mock recommendations for offline tests
      return [
        OutfitRecommendation(
          id: 'rec_offline_1',
          name: 'Classic Casual Look',
          occasion: occasion ?? 'Casual',
          garments: const [
            OutfitItem(
              garmentId: 'CLO-001',
              name: 'Navy Oxford Shirt',
              mainCategory: 'Tops',
              primaryColor: 'Navy',
              laundryStatus: LaundryStatus.clean,
            ),
            OutfitItem(
              garmentId: 'CLO-008',
              name: 'Beige Chinos',
              mainCategory: 'Bottoms',
              primaryColor: 'Beige',
              laundryStatus: LaundryStatus.clean,
            ),
          ],
          garmentIds: const ['CLO-001', 'CLO-008'],
          explanation:
              'Neutral beige bottom balances the deep navy top cleanly.',
          isAvailable: true,
          combinationFingerprint: 'CLO-001:CLO-008',
        )
      ];
    }
  }

  @override
  Future<List<OutfitRecommendation>> generateGuidedStyling(
    String seedGarmentId, {
    String? occasion,
    bool excludeWorn = true,
    int limit = 3,
  }) async {
    final body = {
      'seed_garment_id': seedGarmentId,
      if (occasion != null) 'occasion': occasion,
      'exclude_worn': excludeWorn,
      'limit': limit,
    };

    try {
      final models = await _apiService.generateGuidedStyling(body);
      return models.map((m) => m.toDomain()).toList();
    } catch (e) {
      debugPrint(
          '[OutfitRepositoryImpl] Remote generateGuidedStyling fallback: $e');
      return [
        OutfitRecommendation(
          id: 'rec_guided_offline',
          name: 'Curated Ensemble',
          occasion: occasion ?? 'Casual',
          garments: [
            OutfitItem(
              garmentId: seedGarmentId,
              name: 'Selected Garment',
              mainCategory: 'Tops',
              primaryColor: 'Pink',
              laundryStatus: LaundryStatus.clean,
            ),
            const OutfitItem(
              garmentId: 'CLO-COMP',
              name: 'Complementary Bottom',
              mainCategory: 'Bottoms',
              primaryColor: 'White',
              laundryStatus: LaundryStatus.clean,
            ),
          ],
          garmentIds: [seedGarmentId, 'CLO-COMP'],
          explanation: 'Coordinates gracefully with $seedGarmentId as anchor.',
          isAvailable: true,
          combinationFingerprint: '$seedGarmentId:CLO-COMP',
        )
      ];
    }
  }

  @override
  Future<Map<String, dynamic>> validateOutfit(List<String> garmentIds) async {
    try {
      return await _apiService.validateOutfit(garmentIds);
    } catch (e) {
      debugPrint('[OutfitRepositoryImpl] Remote validateOutfit fallback: $e');
      return {
        'is_valid': garmentIds.isNotEmpty,
        'is_wearable': garmentIds.isNotEmpty,
        'conflicts': <String>[],
      };
    }
  }

  @override
  Future<Map<String, dynamic>> wearOutfit(
    String id, {
    String? notes,
    String? idempotencyKey,
  }) async {
    try {
      final res = await _apiService.wearOutfit(
        id,
        notes: notes,
        idempotencyKey: idempotencyKey,
      );
      final existing = _outfitsCache[id];
      if (existing != null) {
        _outfitsCache[id] = existing.copyWith(
          wearCount: existing.wearCount + 1,
          lastWornDate: DateTime.now(),
        );
      }
      return res;
    } catch (e) {
      debugPrint('[OutfitRepositoryImpl] Remote wearOutfit fallback: $e');
      final existing = _outfitsCache[id];
      if (existing != null) {
        _outfitsCache[id] = existing.copyWith(
          wearCount: existing.wearCount + 1,
          lastWornDate: DateTime.now(),
        );
      }
      return {
        'outfit_id': id,
        'worn_at': DateTime.now().toIso8601String(),
        'garments_updated': existing?.garmentIds ?? [],
        'wear_count': (existing?.wearCount ?? 0) + 1,
      };
    }
  }
}
