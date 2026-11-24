import '../../../../core/network/api_client.dart';
import '../models/wishlist_item_model.dart';
import '../models/wishlist_summary_model.dart';
import '../models/wardrobe_gap_model.dart';
import '../models/purchase_assessment_model.dart';

class WishlistApiService {
  final ApiClient _apiClient;

  WishlistApiService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// GET /api/v1/wardrobe/wishlist
  Future<List<WishlistItemModel>> getWishlist({
    String? status,
    String? priority,
    String? category,
    String sortBy = 'created_at',
    String sortOrder = 'desc',
  }) async {
    String url = '/api/v1/wardrobe/wishlist?sort_by=$sortBy&sort_order=$sortOrder';
    if (status != null) url += '&status=$status';
    if (priority != null) url += '&priority=$priority';
    if (category != null) url += '&category=$category';

    final res = await _apiClient.get(url);
    final list = res as List<dynamic>? ?? [];
    return list.map((e) => WishlistItemModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// GET /api/v1/wardrobe/wishlist/{id}
  Future<WishlistItemModel> getWishlistItem(String id) async {
    final res = await _apiClient.get('/api/v1/wardrobe/wishlist/$id');
    return WishlistItemModel.fromJson(res as Map<String, dynamic>);
  }

  /// POST /api/v1/wardrobe/wishlist
  Future<WishlistItemModel> createWishlistItem(Map<String, dynamic> data) async {
    final res = await _apiClient.post('/api/v1/wardrobe/wishlist', body: data);
    return WishlistItemModel.fromJson(res as Map<String, dynamic>);
  }

  /// PUT /api/v1/wardrobe/wishlist/{id}
  Future<WishlistItemModel> updateWishlistItem(String id, Map<String, dynamic> data) async {
    final res = await _apiClient.put('/api/v1/wardrobe/wishlist/$id', body: data);
    return WishlistItemModel.fromJson(res as Map<String, dynamic>);
  }

  /// DELETE /api/v1/wardrobe/wishlist/{id}
  Future<void> deleteWishlistItem(String id) async {
    await _apiClient.delete('/api/v1/wardrobe/wishlist/$id');
  }

  /// PATCH /api/v1/wardrobe/wishlist/{id}/status
  Future<WishlistItemModel> updateStatus(String id, Map<String, dynamic> data) async {
    final res = await _apiClient.patch('/api/v1/wardrobe/wishlist/$id/status', body: data);
    return WishlistItemModel.fromJson(res as Map<String, dynamic>);
  }

  /// GET /api/v1/wardrobe/wishlist/summary
  Future<WishlistSummaryModel> getSummary() async {
    final res = await _apiClient.get('/api/v1/wardrobe/wishlist/summary');
    return WishlistSummaryModel.fromJson(res as Map<String, dynamic>);
  }

  /// POST /api/v1/wardrobe/wishlist/{id}/convert-to-wardrobe
  Future<Map<String, dynamic>> convertToWardrobe(String id, Map<String, dynamic> data) async {
    final res = await _apiClient.post('/api/v1/wardrobe/wishlist/$id/convert-to-wardrobe', body: data);
    return res as Map<String, dynamic>;
  }

  /// GET /api/v1/wardrobe/shopping-intelligence/gaps
  Future<List<WardrobeGapModel>> getWardrobeGaps() async {
    final res = await _apiClient.get('/api/v1/wardrobe/shopping-intelligence/gaps');
    final list = res as List<dynamic>? ?? [];
    return list.map((e) => WardrobeGapModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// POST /api/v1/wardrobe/shopping-intelligence/match
  Future<List<GarmentMatchModel>> matchExistingGarments(Map<String, dynamic> data) async {
    final res = await _apiClient.post('/api/v1/wardrobe/shopping-intelligence/match', body: data);
    final list = res as List<dynamic>? ?? [];
    return list.map((e) => GarmentMatchModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// GET /api/v1/wardrobe/shopping-intelligence/assessment/{id}
  Future<PurchaseAssessmentModel> assessWishlistItem(String id) async {
    final res = await _apiClient.get('/api/v1/wardrobe/shopping-intelligence/assessment/$id');
    return PurchaseAssessmentModel.fromJson(res as Map<String, dynamic>);
  }
}
