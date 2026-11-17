import '../../../core/auth/auth_service.dart';
import '../../../core/network/api_client.dart';
import '../models/intervention_effectiveness_model.dart';
import '../models/intervention_model.dart';

/// InterventionService handles proactive intelligence and user decisions
class InterventionService {
  final ApiClient _apiClient;
  final AuthService _authService;

  InterventionService({
    ApiClient? apiClient,
    AuthService? authService,
  })  : _apiClient = apiClient ?? ApiClient(),
        _authService = authService ?? AuthService();

  AuthService get authService => _authService;

  /// Retrieve all user interventions (pending, deferred, acted, dismissed)
  Future<List<InterventionModel>> getInterventions() async {
    final response = await _apiClient.get('/api/v1/proactive/interventions');
    if (response is List) {
      return response
          .map((item) => InterventionModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Trigger proactive evaluation over current predictions to spawn new interventions
  Future<List<InterventionModel>> evaluateProactive() async {
    final response = await _apiClient.post('/api/v1/proactive/evaluate');
    if (response is List) {
      return response
          .map((item) => InterventionModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Respond to a pending intervention with a verified user decision:
  /// - 'ACTED': User accepts the recommendation and initiates corrective action
  /// - 'LATER': Postpones recommendation for 4 hours
  /// - 'DISMISS': Rejects and dismisses recommendation
  Future<void> respondIntervention({
    required String interventionId,
    required String action, // 'ACTED' | 'LATER' | 'DISMISS'
  }) async {
    await _apiClient.post(
      '/api/v1/proactive/interventions/$interventionId/respond',
      body: {'action': action},
    );
  }

  /// Retrieve empirical acceptance and conversion metrics
  Future<InterventionEffectivenessModel> getEffectiveness() async {
    final response = await _apiClient.get('/api/v1/future/intervention-effectiveness');
    if (response is Map<String, dynamic>) {
      return InterventionEffectivenessModel.fromJson(response);
    }
    throw ApiException(
      statusCode: 500,
      message: 'Failed to retrieve intervention effectiveness metrics',
    );
  }
}
