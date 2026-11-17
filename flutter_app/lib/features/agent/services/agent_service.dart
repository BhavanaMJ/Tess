import '../../../core/auth/auth_service.dart';
import '../../../core/network/api_client.dart';
import '../models/agent_execution_result_model.dart';
import '../models/agent_plan_model.dart';

/// AgentService manages agent objectives, action plans, confirmations, and step execution.
class AgentService {
  final ApiClient _apiClient;
  final AuthService _authService;

  AgentService({
    ApiClient? apiClient,
    AuthService? authService,
  })  : _apiClient = apiClient ?? ApiClient(),
        _authService = authService ?? AuthService();

  AuthService get authService => _authService;

  /// Submits a natural language objective to the TESS Agent Planner to generate an actionable plan.
  Future<AgentPlanModel> createObjective(String objective) async {
    final response = await _apiClient.post(
      '/api/v1/agent/objectives',
      body: {'objective': objective},
    );

    if (response is Map<String, dynamic>) {
      return AgentPlanModel.fromJson(response);
    }
    throw ApiException(
      statusCode: 500,
      message: 'Failed to parse generated agent plan',
    );
  }

  /// Retrieves user's agent action plans and their execution states.
  Future<List<AgentPlanModel>> getPlans() async {
    final response = await _apiClient.get('/api/v1/agent/plans');
    if (response is List) {
      return response
          .map((item) => AgentPlanModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Retrieves a specific plan by ID with latest merged step confirmations.
  Future<AgentPlanModel> getPlan(String planId) async {
    final response = await _apiClient.get('/api/v1/agent/plans/$planId');
    if (response is Map<String, dynamic>) {
      return AgentPlanModel.fromJson(response);
    }
    throw ApiException(
      statusCode: 404,
      message: 'Plan $planId not found',
    );
  }

  /// Confirms all pending confirmation requirements for the plan.
  Future<Map<String, dynamic>> confirmPlan(String planId) async {
    final response = await _apiClient.post('/api/v1/agent/plans/$planId/confirm');
    if (response is Map<String, dynamic>) {
      return response;
    }
    return {'status': 'success'};
  }

  /// Cancels all pending confirmations and marks the plan as CANCELLED.
  Future<Map<String, dynamic>> cancelPlan(String planId) async {
    final response = await _apiClient.post('/api/v1/agent/plans/$planId/cancel');
    if (response is Map<String, dynamic>) {
      return response;
    }
    return {'status': 'cancelled'};
  }

  /// Executes approved plan steps sequentially through backend ToolRouter.
  Future<AgentExecutionResultModel> executePlan(String planId) async {
    final response = await _apiClient.post('/api/v1/agent/plans/$planId/execute');
    if (response is Map<String, dynamic>) {
      return AgentExecutionResultModel.fromJson(response);
    }
    throw ApiException(
      statusCode: 500,
      message: 'Unexpected response from agent executor',
    );
  }
}

