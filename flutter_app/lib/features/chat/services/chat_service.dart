import '../../../core/auth/auth_service.dart';
import '../../../core/network/api_client.dart';
import '../models/chat_message_model.dart';
import '../models/conversation_model.dart';

/// ChatService orchestrates communication with TESS conversational endpoints:
/// - GET /api/v1/conversations
/// - POST /api/v1/conversations
/// - GET /api/v1/conversations/{id}/messages
/// - POST /api/v1/conversations/{id}/messages
class ChatService {
  final ApiClient _apiClient;
  final AuthService _authService;

  ChatService({
    ApiClient? apiClient,
    AuthService? authService,
  })  : _apiClient = apiClient ?? ApiClient(),
        _authService = authService ?? AuthService();

  AuthService get authService => _authService;

  /// Retrieve all user conversation threads
  Future<List<ConversationModel>> getConversations() async {
    final response = await _apiClient.get('/api/v1/conversations');
    if (response is List) {
      return response
          .map((item) => ConversationModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Create a new conversation thread
  Future<ConversationModel> createConversation({String title = 'New Conversation'}) async {
    final response = await _apiClient.post(
      '/api/v1/conversations',
      body: {'title': title},
    );
    if (response is Map<String, dynamic>) {
      return ConversationModel.fromJson(response);
    }
    throw ApiException(
      statusCode: 500,
      message: 'Invalid conversation creation response from backend',
    );
  }

  /// Retrieve historical messages for a conversation thread
  Future<List<ChatMessageModel>> getMessages(String conversationId) async {
    final response = await _apiClient.get('/api/v1/conversations/$conversationId/messages');
    if (response is List) {
      return response
          .map((item) => ChatMessageModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Transmit a message to TESS and receive cognitive response
  /// Returns the assistant's reply string from ChatResponse { "response": "..." }
  Future<String> sendMessage({
    required String conversationId,
    required String message,
  }) async {
    final response = await _apiClient.post(
      '/api/v1/conversations/$conversationId/messages',
      body: {'message': message},
    );

    if (response is Map<String, dynamic> && response.containsKey('response')) {
      return response['response'] as String;
    }

    throw ApiException(
      statusCode: 500,
      message: 'Unexpected chat response format from TESS backend',
    );
  }
}
