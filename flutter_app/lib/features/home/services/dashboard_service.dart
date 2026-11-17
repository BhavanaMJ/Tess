import 'package:flutter/foundation.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/network/api_client.dart';
import '../models/dashboard_model.dart';

/// DashboardService orchestrates real API data fetching for the TESS Home Screen.
/// Interacts directly with FastAPI backend via authenticated ApiClient.
class DashboardService {
  final ApiClient _apiClient;
  final AuthService _authService;

  DashboardService({
    ApiClient? apiClient,
    AuthService? authService,
  })  : _apiClient = apiClient ?? ApiClient(),
        _authService = authService ?? AuthService();

  /// Fetches real productivity metrics and Future Engine predictions in parallel
  Future<DashboardData> fetchDashboardData() async {
    try {
      // 1. Resolve User Persona from authenticated Supabase session
      final user = _authService.currentUser;
      final userEmail = user?.email ?? 'commander@tess.ai';
      final metadata = user?.userMetadata ?? {};
      final callsign = metadata['callsign'] as String? ??
          metadata['full_name'] as String? ??
          'Commander';

      // 2. Fetch Backend APIs in parallel using Future.wait
      final results = await Future.wait([
        _fetchSummary(),
        _fetchPredictions(),
      ]);

      final summary = results[0] as ProductivitySummaryModel;
      final predictions = results[1] as List<BackendFuturePredictionModel>;

      return DashboardData(
        summary: summary,
        predictions: predictions,
        userEmail: userEmail,
        callsign: callsign,
      );
    } catch (e) {
      debugPrint('[DashboardService] Error fetching dashboard data: $e');
      rethrow;
    }
  }

  /// Helper to fetch productivity summary from GET /api/v1/productivity/summary
  Future<ProductivitySummaryModel> _fetchSummary() async {
    final res = await _apiClient.get('/api/v1/productivity/summary');
    if (res is Map<String, dynamic>) {
      return ProductivitySummaryModel.fromJson(res);
    }
    return const ProductivitySummaryModel();
  }

  /// Helper to fetch predictions from GET /api/v1/future/predictions
  Future<List<BackendFuturePredictionModel>> _fetchPredictions() async {
    final res = await _apiClient.get('/api/v1/future/predictions');
    if (res is List) {
      return res
          .map((item) => BackendFuturePredictionModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}
