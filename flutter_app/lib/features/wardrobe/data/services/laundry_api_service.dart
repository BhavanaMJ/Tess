import '../../../../core/network/api_client.dart';
import '../models/garment_model.dart';
import '../models/laundry_batch_model.dart';
import '../models/laundry_history_model.dart';
import '../models/laundry_stats_model.dart';

/// API Service for Wardrobe Laundry Manager backend endpoints.
class LaundryApiService {
  final ApiClient _apiClient;

  LaundryApiService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// GET /api/v1/wardrobe/laundry/stats
  Future<LaundryStatsModel> getLaundryStats() async {
    final response = await _apiClient.get('/api/v1/wardrobe/laundry/stats');
    return LaundryStatsModel.fromJson(response as Map<String, dynamic>);
  }

  /// GET /api/v1/wardrobe/laundry/items
  Future<List<GarmentModel>> getLaundryItems({
    String? status,
    String? category,
    String? search,
    int page = 1,
    int limit = 50,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (status != null && status.isNotEmpty) params['laundry_status'] = status;
    if (category != null && category.isNotEmpty) params['category'] = category;
    if (search != null && search.isNotEmpty) params['search'] = search;

    final queryString = Uri(queryParameters: params).query;
    final url = '/api/v1/wardrobe/laundry/items?$queryString';
    final response = await _apiClient.get(url);
    final data = response as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>? ?? [];
    return items
        .map((i) => GarmentModel.fromJson(i as Map<String, dynamic>))
        .toList();
  }

  /// PATCH /api/v1/wardrobe/items/{garment_id}/laundry-status
  Future<GarmentModel> updateGarmentLaundryStatus(
    String garmentId,
    String? status, {
    String? notes,
    String? idempotencyKey,
  }) async {
    final body = <String, dynamic>{
      'laundry_status': status,
      'source': 'MANUAL',
    };
    if (notes != null) body['notes'] = notes;
    if (idempotencyKey != null) body['idempotency_key'] = idempotencyKey;

    final response = await _apiClient.patch(
      '/api/v1/wardrobe/items/$garmentId/laundry-status',
      body: body,
    );
    return GarmentModel.fromJson(response as Map<String, dynamic>);
  }

  /// GET /api/v1/wardrobe/items/{garment_id}/laundry-history
  Future<List<LaundryHistoryEntryModel>> getGarmentLaundryHistory(
      String garmentId) async {
    final response = await _apiClient
        .get('/api/v1/wardrobe/items/$garmentId/laundry-history');
    final list = response as List<dynamic>? ?? [];
    return list
        .map(
            (i) => LaundryHistoryEntryModel.fromJson(i as Map<String, dynamic>))
        .toList();
  }

  /// POST /api/v1/wardrobe/laundry/batches
  Future<LaundryBatchModel> createBatch(
    List<String> garmentIds, {
    String? name,
    String initialStatus = 'WASHING',
    String? notes,
    String? idempotencyKey,
  }) async {
    final body = <String, dynamic>{
      'garment_ids': garmentIds,
      'initial_status': initialStatus,
    };
    if (name != null) body['name'] = name;
    if (notes != null) body['notes'] = notes;
    if (idempotencyKey != null) body['idempotency_key'] = idempotencyKey;

    final response = await _apiClient.post(
      '/api/v1/wardrobe/laundry/batches',
      body: body,
    );
    return LaundryBatchModel.fromJson(response as Map<String, dynamic>);
  }

  /// GET /api/v1/wardrobe/laundry/batches
  Future<List<LaundryBatchModel>> getBatches({String? status}) async {
    var url = '/api/v1/wardrobe/laundry/batches';
    if (status != null) {
      url += '?status=$status';
    }
    final response = await _apiClient.get(url);
    final list = response as List<dynamic>? ?? [];
    return list
        .map((i) => LaundryBatchModel.fromJson(i as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/v1/wardrobe/laundry/batches/{batch_id}
  Future<LaundryBatchModel> getBatch(String batchId) async {
    final response =
        await _apiClient.get('/api/v1/wardrobe/laundry/batches/$batchId');
    return LaundryBatchModel.fromJson(response as Map<String, dynamic>);
  }

  /// PATCH /api/v1/wardrobe/laundry/batches/{batch_id}/status
  Future<Map<String, dynamic>> advanceBatchStatus(
    String batchId,
    String newStatus, {
    String? notes,
    String? idempotencyKey,
  }) async {
    final body = <String, dynamic>{
      'status': newStatus,
    };
    if (notes != null) body['notes'] = notes;
    if (idempotencyKey != null) body['idempotency_key'] = idempotencyKey;

    final response = await _apiClient.patch(
      '/api/v1/wardrobe/laundry/batches/$batchId/status',
      body: body,
    );
    return response as Map<String, dynamic>;
  }

  /// POST /api/v1/wardrobe/laundry/batches/{batch_id}/items
  Future<LaundryBatchModel> addItemsToBatch(
      String batchId, List<String> garmentIds) async {
    final response = await _apiClient.post(
      '/api/v1/wardrobe/laundry/batches/$batchId/items',
      body: {'garment_ids': garmentIds},
    );
    return LaundryBatchModel.fromJson(response as Map<String, dynamic>);
  }

  /// DELETE /api/v1/wardrobe/laundry/batches/{batch_id}/items/{garment_id}
  Future<bool> removeItemFromBatch(String batchId, String garmentId) async {
    await _apiClient
        .delete('/api/v1/wardrobe/laundry/batches/$batchId/items/$garmentId');
    return true;
  }
}
