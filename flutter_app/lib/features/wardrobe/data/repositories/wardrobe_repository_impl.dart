import 'package:flutter/foundation.dart';
import '../../../../core/auth/auth_service.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/garment.dart';
import '../../domain/entities/laundry_status.dart';
import '../../domain/repositories/wardrobe_repository.dart';
import '../models/garment_model.dart';
import '../services/wardrobe_api_service.dart';

/// Concrete Implementation of WardrobeRepository.
/// Integrates with WardrobeApiService while providing graceful fallback cache
/// during early Phase 1 rollout before backend endpoints are fully deployed.
class WardrobeRepositoryImpl implements WardrobeRepository {
  final WardrobeApiService _apiService;
  final AuthService _authService;

  // In-memory cache for instant UI response and seamless Phase 1 offline testing
  final Map<String, Garment> _localCache = {};

  WardrobeRepositoryImpl({
    WardrobeApiService? apiService,
    AuthService? authService,
  })  : _apiService = apiService ?? WardrobeApiService(),
        _authService = authService ?? AuthService();

  String get _currentUserId => _authService.currentUser?.id ?? 'tess_default_user';

  @override
  Future<List<Garment>> getGarments({
    String? category,
    LaundryStatus? laundryStatus,
    bool? favoritesOnly,
  }) async {
    try {
      final models = await _apiService.getItems(
        category: category,
        laundryStatus: laundryStatus?.value,
        favoritesOnly: favoritesOnly,
      );
      for (final m in models) {
        final entity = m.toDomain();
        _localCache[entity.id] = entity;
      }
    } catch (e) {
      debugPrint('[WardrobeRepo] Remote API unavailable or pending, using local store: $e');
    }

    var list = _localCache.values.toList();
    if (category != null && category.isNotEmpty) {
      list = list.where((g) => g.mainCategory.toLowerCase() == category.toLowerCase()).toList();
    }
    if (laundryStatus != null) {
      list = list.where((g) => g.laundryStatus == laundryStatus).toList();
    }
    if (favoritesOnly == true) {
      list = list.where((g) => g.isFavorite).toList();
    }

    // Sort by id / name
    list.sort((a, b) => a.id.compareTo(b.id));
    return list;
  }

  @override
  Future<Garment?> getGarmentById(String id) async {
    if (_localCache.containsKey(id)) {
      return _localCache[id];
    }

    try {
      final model = await _apiService.getItemById(id);
      if (model != null) {
        final entity = model.toDomain();
        _localCache[entity.id] = entity;
        return entity;
      }
    } catch (_) {}

    return null;
  }

  @override
  Future<Garment> saveGarment(Garment garment) async {
    final now = DateTime.now();
    final updated = garment.copyWith(
      userId: garment.userId.isEmpty ? _currentUserId : garment.userId,
      updatedAt: now,
    );

    _localCache[updated.id] = updated;

    try {
      final model = GarmentModel.fromDomain(updated);
      final savedModel = await _apiService.createItem(model);
      final entity = savedModel.toDomain();
      _localCache[entity.id] = entity;
      return entity;
    } catch (e) {
      debugPrint('[WardrobeRepo] Remote save pending backend route, kept in local cache: $e');
      return updated;
    }
  }

  @override
  Future<bool> deleteGarment(String id) async {
    _localCache.remove(id);
    try {
      await _apiService.deleteItem(id);
    } catch (_) {}
    return true;
  }

  @override
  Future<Garment> updateLaundryStatus(String id, LaundryStatus status) async {
    final existing = await getGarmentById(id);
    if (existing == null) {
      throw Exception('Garment $id not found');
    }

    final updated = existing.copyWith(
      laundryStatus: status,
      updatedAt: DateTime.now(),
    );
    return saveGarment(updated);
  }

  @override
  Future<Garment> toggleFavorite(String id) async {
    final existing = await getGarmentById(id);
    if (existing == null) {
      throw Exception('Garment $id not found');
    }

    final updated = existing.copyWith(
      isFavorite: !existing.isFavorite,
      updatedAt: DateTime.now(),
    );
    return saveGarment(updated);
  }

  @override
  Future<List<WardrobeCategory>> getCategories() async {
    try {
      final models = await _apiService.getCategories();
      if (models.isNotEmpty) {
        return models.map((m) => m.toDomain()).toList();
      }
    } catch (_) {}

    return WardrobeCategory.defaultCategories;
  }

  @override
  Future<int> importInitialInventory(List<Garment> garments) async {
    int count = 0;
    for (final garment in garments) {
      await saveGarment(garment);
      count++;
    }
    return count;
  }
}
