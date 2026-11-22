import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../models/category_model.dart';
import '../models/garment_model.dart';
import '../models/wardrobe_stats_model.dart';

/// HTTP Client Service for Wardrobe API communication.
/// Connects to FastAPI endpoint family `/api/v1/wardrobe/...` with bearer auth.
class WardrobeApiService {
  final ApiClient _apiClient;

  WardrobeApiService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// GET /api/v1/wardrobe/items
  Future<List<GarmentModel>> getItems({
    String? category,
    String? laundryStatus,
    bool? favoritesOnly,
    String? search,
    String? sortBy,
    String? sortOrder,
    int? page,
    int? limit,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (category != null && category.isNotEmpty)
        queryParams['category'] = category;
      if (laundryStatus != null && laundryStatus.isNotEmpty)
        queryParams['laundry_status'] = laundryStatus;
      if (favoritesOnly != null)
        queryParams['is_favorite'] = favoritesOnly.toString();
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (sortBy != null) queryParams['sort_by'] = sortBy;
      if (sortOrder != null) queryParams['sort_order'] = sortOrder;
      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) queryParams['limit'] = limit.toString();

      final queryString = queryParams.isNotEmpty
          ? '?${queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}'
          : '';

      final response =
          await _apiClient.get('/api/v1/wardrobe/items$queryString');
      if (response is List) {
        return response
            .map((item) => GarmentModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else if (response is Map<String, dynamic> &&
          response['items'] is List) {
        return (response['items'] as List)
            .map((item) => GarmentModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('[WardrobeApiService] getItems notice: $e');
      rethrow;
    }
  }

  /// GET /api/v1/wardrobe/items/{id}
  Future<GarmentModel?> getItemById(String id) async {
    try {
      final response = await _apiClient.get('/api/v1/wardrobe/items/$id');
      if (response is Map<String, dynamic>) {
        return GarmentModel.fromJson(response);
      }
      return null;
    } catch (e) {
      debugPrint('[WardrobeApiService] getItemById notice: $e');
      rethrow;
    }
  }

  /// POST /api/v1/wardrobe/items
  Future<GarmentModel> createItem(GarmentModel model) async {
    final response = await _apiClient.post(
      '/api/v1/wardrobe/items',
      body: model.toJson(),
    );
    if (response is Map<String, dynamic>) {
      return GarmentModel.fromJson(response);
    }
    throw ApiException(
        statusCode: 500, message: 'Invalid response saving garment');
  }

  /// PATCH /api/v1/wardrobe/items/{id}
  Future<GarmentModel> patchItem(String id, Map<String, dynamic> delta) async {
    final response = await _apiClient.patch(
      '/api/v1/wardrobe/items/$id',
      body: delta,
    );
    if (response is Map<String, dynamic>) {
      return GarmentModel.fromJson(response);
    }
    throw ApiException(
        statusCode: 500, message: 'Invalid response patching garment');
  }

  /// PUT /api/v1/wardrobe/items/{id}
  Future<GarmentModel> updateItem(String id, GarmentModel model) async {
    final response = await _apiClient.put(
      '/api/v1/wardrobe/items/$id',
      body: model.toJson(),
    );
    if (response is Map<String, dynamic>) {
      return GarmentModel.fromJson(response);
    }
    throw ApiException(
        statusCode: 500, message: 'Invalid response updating garment');
  }

  /// DELETE /api/v1/wardrobe/items/{id}
  Future<bool> deleteItem(String id, {bool hardDelete = false}) async {
    await _apiClient
        .delete('/api/v1/wardrobe/items/$id?hard_delete=$hardDelete');
    return true;
  }

  /// GET /api/v1/wardrobe/categories
  Future<List<WardrobeCategoryModel>> getCategories() async {
    try {
      final response = await _apiClient.get('/api/v1/wardrobe/categories');
      if (response is List) {
        return response
            .map((item) =>
                WardrobeCategoryModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('[WardrobeApiService] getCategories notice: $e');
      rethrow;
    }
  }

  /// GET /api/v1/wardrobe/stats
  Future<WardrobeStatsModel> getStats() async {
    try {
      final response = await _apiClient.get('/api/v1/wardrobe/stats');
      if (response is Map<String, dynamic>) {
        return WardrobeStatsModel.fromJson(response);
      }
      return const WardrobeStatsModel(
        totalGarments: 0,
        cleanCount: 0,
        wornCount: 0,
        inLaundryCount: 0,
        storedCount: 0,
        unassignedCount: 0,
      );
    } catch (e) {
      debugPrint('[WardrobeApiService] getStats notice: $e');
      rethrow;
    }
  }

  /// POST /api/v1/wardrobe/import-initial
  Future<Map<String, dynamic>> importInitial(
      List<GarmentModel> garments) async {
    final payload = {
      'garments': garments.map((g) => g.toJson()).toList(),
    };
    final response = await _apiClient.post(
      '/api/v1/wardrobe/import-initial',
      body: payload,
    );
    if (response is Map<String, dynamic>) {
      return response;
    }
    return {'imported_count': 0, 'skipped_count': 0, 'total_garments': 0};
  }
}
