import '../../../../core/network/api_client.dart';
import '../models/wardrobe_insights_model.dart';
import '../models/cost_per_wear_model.dart';
import '../models/capsule_insight_model.dart';
import '../models/style_memory_model.dart';

class InsightsApiService {
  final ApiClient _apiClient;

  InsightsApiService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// GET /api/v1/wardrobe/insights/overview
  Future<WardrobeOverviewModel> getOverview({
    String period = '30d',
    String? startDate,
    String? endDate,
  }) async {
    String url = '/api/v1/wardrobe/insights/overview?period=$period';
    if (startDate != null) url += '&start_date=$startDate';
    if (endDate != null) url += '&end_date=$endDate';

    final res = await _apiClient.get(url);
    return WardrobeOverviewModel.fromJson(res as Map<String, dynamic>);
  }

  /// GET /api/v1/wardrobe/insights/category-distribution
  Future<List<CategoryDistributionModel>> getCategoryDistribution() async {
    final res = await _apiClient.get('/api/v1/wardrobe/insights/category-distribution');
    final data = res as Map<String, dynamic>;
    final list = data['categories'] as List<dynamic>? ?? [];
    return list.map((e) => CategoryDistributionModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// GET /api/v1/wardrobe/insights/most-worn
  Future<List<GarmentUsageModel>> getMostWorn({
    String period = 'all',
    int limit = 5,
  }) async {
    final res = await _apiClient.get('/api/v1/wardrobe/insights/most-worn?period=$period&limit=$limit');
    final data = res as Map<String, dynamic>;
    final list = data['items'] as List<dynamic>? ?? [];
    return list.map((e) => GarmentUsageModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// GET /api/v1/wardrobe/insights/least-worn
  Future<List<GarmentUsageModel>> getLeastWorn({
    String period = 'all',
    int limit = 5,
  }) async {
    final res = await _apiClient.get('/api/v1/wardrobe/insights/least-worn?period=$period&limit=$limit');
    final data = res as Map<String, dynamic>;
    final list = data['items'] as List<dynamic>? ?? [];
    return list.map((e) => GarmentUsageModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// GET /api/v1/wardrobe/insights/neglected
  Future<List<GarmentUsageModel>> getNeglected({
    int thresholdDays = 60,
    int limit = 10,
  }) async {
    final res = await _apiClient.get('/api/v1/wardrobe/insights/neglected?threshold_days=$thresholdDays&limit=$limit');
    final data = res as Map<String, dynamic>;
    final list = data['items'] as List<dynamic>? ?? [];
    return list.map((e) => GarmentUsageModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// GET /api/v1/wardrobe/insights/colour-analysis
  Future<List<ColourDistributionModel>> getColourAnalysis() async {
    final res = await _apiClient.get('/api/v1/wardrobe/insights/colour-analysis');
    final data = res as Map<String, dynamic>;
    final list = data['distribution'] as List<dynamic>? ?? [];
    return list.map((e) => ColourDistributionModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// GET /api/v1/wardrobe/insights/category-usage
  Future<List<CategoryUsageModel>> getCategoryUsage({String period = '30d'}) async {
    final res = await _apiClient.get('/api/v1/wardrobe/insights/category-usage?period=$period');
    final data = res as Map<String, dynamic>;
    final list = data['categories'] as List<dynamic>? ?? [];
    return list.map((e) => CategoryUsageModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// GET /api/v1/wardrobe/insights/outfit-repetition
  Future<List<OutfitRepetitionModel>> getOutfitRepetition({int limit = 10}) async {
    final res = await _apiClient.get('/api/v1/wardrobe/insights/outfit-repetition?limit=$limit');
    final data = res as Map<String, dynamic>;
    final list = data['outfits'] as List<dynamic>? ?? [];
    return list.map((e) => OutfitRepetitionModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// GET /api/v1/wardrobe/insights/cost-per-wear
  Future<CostPerWearSummaryModel> getCostPerWear() async {
    final res = await _apiClient.get('/api/v1/wardrobe/insights/cost-per-wear');
    return CostPerWearSummaryModel.fromJson(res as Map<String, dynamic>);
  }

  /// GET /api/v1/wardrobe/insights/recommendations
  Future<List<WardrobeRecommendationModel>> getRecommendations() async {
    final res = await _apiClient.get('/api/v1/wardrobe/insights/recommendations');
    final data = res as Map<String, dynamic>;
    final list = data['recommendations'] as List<dynamic>? ?? [];
    return list.map((e) => WardrobeRecommendationModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// GET /api/v1/wardrobe/insights/capsule-intelligence
  Future<CapsuleWardrobeSummaryModel> getCapsuleIntelligence() async {
    final res = await _apiClient.get('/api/v1/wardrobe/insights/capsule-intelligence');
    return CapsuleWardrobeSummaryModel.fromJson(res as Map<String, dynamic>);
  }

  /// GET /api/v1/wardrobe/insights/style-memory
  Future<StyleMemoryModel> getStyleMemory() async {
    final res = await _apiClient.get('/api/v1/wardrobe/insights/style-memory');
    return StyleMemoryModel.fromJson(res as Map<String, dynamic>);
  }

  /// POST /api/v1/wardrobe/insights/style-memory
  Future<StyleMemoryModel> updateStyleMemory(Map<String, dynamic> body) async {
    final res = await _apiClient.post('/api/v1/wardrobe/insights/style-memory', body: body);
    return StyleMemoryModel.fromJson(res as Map<String, dynamic>);
  }
}
