import '../../../core/auth/auth_service.dart';
import '../../../core/network/api_client.dart';
import '../models/memory_model.dart';

/// MemoryService handles persistence, retrieval, and updating of personal memories.
/// Interacts with FastAPI:
/// - GET /api/v1/memories
/// - POST /api/v1/memories
/// - PUT /api/v1/memories/{id}
/// - DELETE /api/v1/memories/{id}
class MemoryService {
  final ApiClient _apiClient;
  final AuthService _authService;

  MemoryService({
    ApiClient? apiClient,
    AuthService? authService,
  })  : _apiClient = apiClient ?? ApiClient(),
        _authService = authService ?? AuthService();

  AuthService get authService => _authService;

  /// Retrieve all user memories from the continuous memory bank
  Future<List<MemoryModel>> getMemories() async {
    final response = await _apiClient.get('/api/v1/memories');
    if (response is List) {
      return response
          .map((item) => MemoryModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Create a new personal memory entity
  Future<MemoryModel> createMemory({
    required String category,
    required String content,
    int importance = 3,
    String provenance = 'USER_STATED',
  }) async {
    final response = await _apiClient.post(
      '/api/v1/memories',
      body: {
        'category': category.toUpperCase(),
        'content': content,
        'importance': importance,
        'provenance': provenance,
        'is_confirmed': true,
      },
    );

    if (response is Map<String, dynamic>) {
      return MemoryModel.fromJson(response);
    }

    throw ApiException(
      statusCode: 500,
      message: 'Invalid memory creation response from backend',
    );
  }

  /// Update an existing memory
  Future<MemoryModel> updateMemory(
    String memoryId,
    Map<String, dynamic> updates,
  ) async {
    final response = await _apiClient.put(
      '/api/v1/memories/$memoryId',
      body: updates,
    );

    if (response is Map<String, dynamic>) {
      return MemoryModel.fromJson(response);
    }

    throw ApiException(
      statusCode: 500,
      message: 'Failed to update memory',
    );
  }

  /// Delete a personal memory
  Future<void> deleteMemory(String memoryId) async {
    await _apiClient.delete('/api/v1/memories/$memoryId');
  }
}
