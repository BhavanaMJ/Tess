import '../../../../core/network/api_client.dart';
import '../models/outfit_model.dart';
import '../models/outfit_recommendation_model.dart';

class OutfitApiService {
  final ApiClient _apiClient;

  OutfitApiService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// GET /api/v1/wardrobe/outfits
  Future<List<OutfitModel>> getOutfits({
    String? occasion,
    bool favouriteOnly = false,
    String? search,
  }) async {
    final params = <String, String>{};
    if (occasion != null && occasion.isNotEmpty) params['occasion'] = occasion;
    if (favouriteOnly) params['favourite_only'] = 'true';
    if (search != null && search.isNotEmpty) params['search'] = search;

    final queryString =
        params.isNotEmpty ? '?${Uri(queryParameters: params).query}' : '';
    final response =
        await _apiClient.get('/api/v1/wardrobe/outfits$queryString');
    final data = response as Map<String, dynamic>;
    final outfits = data['outfits'] as List<dynamic>? ?? [];
    return outfits
        .map((e) => OutfitModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/v1/wardrobe/outfits/{id}
  Future<OutfitModel> getOutfit(String id) async {
    final response = await _apiClient.get('/api/v1/wardrobe/outfits/$id');
    return OutfitModel.fromJson(response as Map<String, dynamic>);
  }

  /// POST /api/v1/wardrobe/outfits
  Future<OutfitModel> createOutfit(Map<String, dynamic> body) async {
    final response =
        await _apiClient.post('/api/v1/wardrobe/outfits', body: body);
    return OutfitModel.fromJson(response as Map<String, dynamic>);
  }

  /// PUT /api/v1/wardrobe/outfits/{id}
  Future<OutfitModel> updateOutfit(String id, Map<String, dynamic> body) async {
    final response =
        await _apiClient.put('/api/v1/wardrobe/outfits/$id', body: body);
    return OutfitModel.fromJson(response as Map<String, dynamic>);
  }

  /// DELETE /api/v1/wardrobe/outfits/{id}
  Future<void> deleteOutfit(String id) async {
    await _apiClient.delete('/api/v1/wardrobe/outfits/$id');
  }

  /// POST /api/v1/wardrobe/outfits/generate (Mode A: Automatic)
  Future<List<OutfitRecommendationModel>> generateRecommendations(
      Map<String, dynamic> body) async {
    final response =
        await _apiClient.post('/api/v1/wardrobe/outfits/generate', body: body);
    final data = response as Map<String, dynamic>;
    final recs = data['recommendations'] as List<dynamic>? ?? [];
    return recs
        .map((e) =>
            OutfitRecommendationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /api/v1/wardrobe/outfits/guided (Mode B: Guided)
  Future<List<OutfitRecommendationModel>> generateGuidedStyling(
      Map<String, dynamic> body) async {
    final response =
        await _apiClient.post('/api/v1/wardrobe/outfits/guided', body: body);
    final data = response as Map<String, dynamic>;
    final recs = data['recommendations'] as List<dynamic>? ?? [];
    return recs
        .map((e) =>
            OutfitRecommendationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /api/v1/wardrobe/outfits/validate (Mode C: Manual)
  Future<Map<String, dynamic>> validateOutfit(List<String> garmentIds) async {
    final response = await _apiClient.post(
      '/api/v1/wardrobe/outfits/validate',
      body: {'garment_ids': garmentIds},
    );
    return response as Map<String, dynamic>;
  }

  /// POST /api/v1/wardrobe/outfits/{id}/wear (Phase 4 Integration)
  Future<Map<String, dynamic>> wearOutfit(
    String id, {
    String? notes,
    String? idempotencyKey,
  }) async {
    final response = await _apiClient.post(
      '/api/v1/wardrobe/outfits/$id/wear',
      body: {
        if (notes != null) 'notes': notes,
        if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      },
    );
    return response as Map<String, dynamic>;
  }
}
