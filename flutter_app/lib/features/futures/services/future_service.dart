import '../../../core/auth/auth_service.dart';
import '../../../core/network/api_client.dart';
import '../models/accuracy_model.dart';
import '../models/behavioral_model.dart';
import '../models/forecast_model.dart';
import '../models/future_prediction_model.dart';
import '../models/multiple_futures_model.dart';
import '../models/simulation_model.dart';

/// FutureService communicates with TESS's FastAPI Future Engine endpoints
class FutureService {
  final ApiClient _apiClient;
  final AuthService _authService;

  FutureService({
    ApiClient? apiClient,
    AuthService? authService,
  })  : _apiClient = apiClient ?? ApiClient(),
        _authService = authService ?? AuthService();

  AuthService get authService => _authService;

  /// Retrieve active future predictions and risk alerts
  Future<List<FuturePredictionModel>> getPredictions() async {
    final response = await _apiClient.get('/api/v1/future/predictions');
    if (response is List) {
      return response
          .map((item) => FuturePredictionModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Run counterfactual simulation for a specified time horizon (e.g. '24h', '72h')
  Future<SimulationResponseModel> simulateFuture(String horizon) async {
    final response = await _apiClient.post(
      '/api/v1/future/simulate',
      body: {'horizon': horizon},
    );

    if (response is Map<String, dynamic>) {
      return SimulationResponseModel.fromJson(response);
    }

    throw ApiException(
      statusCode: 500,
      message: 'Invalid simulation payload received from Future Engine',
    );
  }

  /// Generate explainable long-term forecast (30d, 90d, 365d)
  Future<LongTermForecastModel> getForecast(String horizon) async {
    final response = await _apiClient.post(
      '/api/v1/future/forecast',
      body: {'horizon': horizon},
    );

    if (response is Map<String, dynamic>) {
      return LongTermForecastModel.fromJson(response);
    }

    throw ApiException(
      statusCode: 500,
      message: 'Failed to generate forecast for horizon $horizon',
    );
  }

  /// Generate Multiple Future Selves: CURRENT, IMPROVED, and ALTERNATIVE trajectories
  Future<MultipleFuturesModel> getMultipleScenarios({
    String horizon = '30d',
    String? userGoal,
  }) async {
    final response = await _apiClient.post(
      '/api/v1/future/scenarios',
      body: {
        'horizon': horizon,
        if (userGoal != null && userGoal.isNotEmpty) 'user_goal': userGoal,
      },
    );

    if (response is Map<String, dynamic>) {
      return MultipleFuturesModel.fromJson(response);
    }

    throw ApiException(
      statusCode: 500,
      message: 'Failed to generate multiple future trajectories',
    );
  }

  /// Retrieve behavioral patterns, dimensions, and data quality rating
  Future<BehavioralAnalysisModel> getBehavioralProfile({int windowDays = 30}) async {
    final response = await _apiClient.get('/api/v1/future/behavior?window_days=$windowDays');
    if (response is Map<String, dynamic>) {
      return BehavioralAnalysisModel.fromJson(response);
    }
    throw ApiException(
      statusCode: 500,
      message: 'Failed to retrieve behavioral profile',
    );
  }

  /// Retrieve empirical prediction accuracy, Brier scores, and sample size
  Future<AccuracyMetricsModel> getAccuracyMetrics() async {
    final response = await _apiClient.get('/api/v1/future/accuracy');
    if (response is Map<String, dynamic>) {
      return AccuracyMetricsModel.fromJson(response);
    }
    throw ApiException(
      statusCode: 500,
      message: 'Failed to retrieve prediction accuracy metrics',
    );
  }

  /// Trigger fresh Future Analysis over current tasks and summary
  Future<void> analyzeFuture() async {
    await _apiClient.post('/api/v1/future/analyze');
  }
}
