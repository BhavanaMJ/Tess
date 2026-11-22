import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tess/core/network/api_client.dart';
import 'package:tess/features/chat/models/chat_message_model.dart';
import 'package:tess/features/chat/models/conversation_model.dart';
import 'package:tess/features/chat/screens/chat_screen.dart';
import 'package:tess/features/chat/services/chat_service.dart';
import 'package:tess/features/memory/models/memory_model.dart';
import 'package:tess/features/memory/screens/memory_screen.dart';
import 'package:tess/features/memory/services/memory_service.dart';
import 'test_helpers.dart';

void main() {
  group('Phase 14.5: Chat Models & JSON Parsing', () {
    test('ConversationModel parses valid backend JSON and formats date', () {
      final json = {
        'id': 'conv_001',
        'user_id': 'usr_999',
        'title': 'Tactical Simulation',
        'created_at': '2026-11-17T10:00:00Z',
        'updated_at': '2026-11-17T10:30:00Z',
      };

      final conv = ConversationModel.fromJson(json);
      expect(conv.id, 'conv_001');
      expect(conv.userId, 'usr_999');
      expect(conv.title, 'Tactical Simulation');
      expect(conv.formattedDate.isNotEmpty, true);

      final serialized = conv.toJson();
      expect(serialized['id'], 'conv_001');
      expect(serialized['title'], 'Tactical Simulation');
    });

    test('ConversationModel handles missing or null fields gracefully', () {
      final conv = ConversationModel.fromJson({});
      expect(conv.id, '');
      expect(conv.title, 'New Conversation');
      expect(conv.userId, '');
    });

    test('ChatMessageModel parses user and assistant roles with timestamps', () {
      final userJson = {
        'id': 'msg_1',
        'conversation_id': 'conv_1',
        'role': 'user',
        'content': 'What are my priority directives?',
        'created_at': '2026-11-17T14:45:00Z',
      };

      final userMsg = ChatMessageModel.fromJson(userJson);
      expect(userMsg.isUser, true);
      expect(userMsg.isAssistant, false);
      expect(userMsg.content, 'What are my priority directives?');
      expect(userMsg.formattedTime, '14:45');
      expect(userMsg.isPending, false);
      expect(userMsg.hasFailed, false);

      final assistantJson = {
        'id': 'msg_2',
        'conversation_id': 'conv_1',
        'role': 'assistant',
        'content': 'All work packages are synchronized.',
        'created_at': '2026-11-17T14:45:10Z',
      };

      final assistantMsg = ChatMessageModel.fromJson(assistantJson);
      expect(assistantMsg.isUser, false);
      expect(assistantMsg.isAssistant, true);
    });
  });

  group('Phase 14.5: Memory Models & JSON Parsing', () {
    test('MemoryModel parses category, importance and provenance', () {
      final json = {
        'id': 'mem_1',
        'user_id': 'usr_1',
        'category': 'work',
        'content': 'Prefers deep work sprints before noon',
        'importance': 4,
        'is_confirmed': true,
        'provenance': 'USER_STATED',
        'created_at': '2026-11-17T09:00:00Z',
        'updated_at': '2026-11-17T09:00:00Z',
      };

      final mem = MemoryModel.fromJson(json);
      expect(mem.id, 'mem_1');
      expect(mem.category, 'WORK');
      expect(mem.importance, 4);
      expect(mem.isConfirmed, true);
      expect(mem.provenance, 'USER_STATED');
      expect(mem.formattedDate, contains('2026'));
    });

    test('MemoryModel defaults null category to GENERAL and importance to 1', () {
      final mem = MemoryModel.fromJson({'content': 'Ad-hoc note'});
      expect(mem.category, 'GENERAL');
      expect(mem.importance, 1);
      expect(mem.isConfirmed, true);
      expect(mem.provenance, 'USER_STATED');
    });
  });

  group('Phase 14.5: ChatService Mocked Unit Tests', () {
    test('getConversations handles array and empty response', () async {
      final fakeAuth = FakeAuthService(initialAuthenticated: true);
      final mockHttp = MockClient((request) async {
        if (request.url.path == '/api/v1/conversations') {
          return http.Response(
            jsonEncode([
              {'id': 'c1', 'title': 'Thread 1'},
              {'id': 'c2', 'title': 'Thread 2'},
            ]),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final service = ChatService(
        apiClient: ApiClient(authService: fakeAuth, httpClient: mockHttp),
        authService: fakeAuth,
      );

      final list = await service.getConversations();
      expect(list.length, 2);
      expect(list.first.title, 'Thread 1');
    });

    test('createConversation posts title and returns created model', () async {
      final fakeAuth = FakeAuthService(initialAuthenticated: true);
      final mockHttp = MockClient((request) async {
        if (request.url.path == '/api/v1/conversations' && request.method == 'POST') {
          final body = jsonDecode(request.body);
          expect(body['title'], 'New Mission');
          return http.Response(
            jsonEncode({'id': 'c_new', 'title': 'New Mission'}),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final service = ChatService(
        apiClient: ApiClient(authService: fakeAuth, httpClient: mockHttp),
        authService: fakeAuth,
      );

      final created = await service.createConversation(title: 'New Mission');
      expect(created.id, 'c_new');
      expect(created.title, 'New Mission');
    });

    test('sendMessage posts message and parses ChatResponse { response: ... }', () async {
      final fakeAuth = FakeAuthService(initialAuthenticated: true);
      final mockHttp = MockClient((request) async {
        if (request.url.path == '/api/v1/conversations/c1/messages' && request.method == 'POST') {
          final body = jsonDecode(request.body);
          expect(body['message'], 'Status report');
          return http.Response(
            jsonEncode({'response': 'All telemetry green.'}),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final service = ChatService(
        apiClient: ApiClient(authService: fakeAuth, httpClient: mockHttp),
        authService: fakeAuth,
      );

      final reply = await service.sendMessage(conversationId: 'c1', message: 'Status report');
      expect(reply, 'All telemetry green.');
    });

    test('sendMessage handles 401 Unauthorized by throwing ApiException', () async {
      final fakeAuth = FakeAuthService(initialAuthenticated: true);
      final mockHttp = MockClient((request) async {
        return http.Response(jsonEncode({'detail': 'Not authenticated'}), 401);
      });

      final service = ChatService(
        apiClient: ApiClient(authService: fakeAuth, httpClient: mockHttp),
        authService: fakeAuth,
      );

      expect(
        () => service.sendMessage(conversationId: 'c1', message: 'Hello'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('Phase 14.5: MemoryService Mocked Unit Tests', () {
    test('getMemories, createMemory, and deleteMemory execute proper HTTP calls', () async {
      final fakeAuth = FakeAuthService(initialAuthenticated: true);
      bool deleteCalled = false;

      final mockHttp = MockClient((request) async {
        if (request.url.path == '/api/v1/memories' && request.method == 'GET') {
          return http.Response(
            jsonEncode([
              {'id': 'm1', 'category': 'WORK', 'content': 'Memory 1', 'importance': 3},
            ]),
            200,
          );
        } else if (request.url.path == '/api/v1/memories' && request.method == 'POST') {
          final body = jsonDecode(request.body);
          return http.Response(
            jsonEncode({
              'id': 'm_new',
              'category': body['category'],
              'content': body['content'],
              'importance': body['importance'],
            }),
            200,
          );
        } else if (request.url.path == '/api/v1/memories/m1' && request.method == 'DELETE') {
          deleteCalled = true;
          return http.Response('', 204);
        }
        return http.Response('Not Found', 404);
      });

      final service = MemoryService(
        apiClient: ApiClient(authService: fakeAuth, httpClient: mockHttp),
        authService: fakeAuth,
      );

      final memories = await service.getMemories();
      expect(memories.length, 1);
      expect(memories.first.content, 'Memory 1');

      final created = await service.createMemory(
        category: 'HEALTH',
        content: 'Stay hydrated',
        importance: 5,
      );
      expect(created.id, 'm_new');
      expect(created.category, 'HEALTH');
      expect(created.importance, 5);

      await service.deleteMemory('m1');
      expect(deleteCalled, true);
    });
  });

  group('Phase 14.5: ChatScreen UI & Interaction Tests', () {
    testWidgets('Renders message stream, transmits message and transitions Mascot state', (tester) async {
      final fakeAuth = FakeAuthService(initialAuthenticated: true);

      final mockHttp = MockClient((request) async {
        if (request.url.path == '/api/v1/conversations' && request.method == 'GET') {
          return http.Response(
            jsonEncode([{'id': 'c1', 'title': 'Command Thread'}]),
            200,
          );
        } else if (request.url.path == '/api/v1/conversations/c1/messages' && request.method == 'GET') {
          return http.Response(
            jsonEncode([
              {
                'id': 'm1',
                'conversation_id': 'c1',
                'role': 'assistant',
                'content': 'TESS online. Trajectories synchronized.',
                'created_at': '2026-11-17T12:00:00Z',
              }
            ]),
            200,
          );
        } else if (request.url.path == '/api/v1/conversations/c1/messages' && request.method == 'POST') {
          return http.Response(
            jsonEncode({'response': 'Telemetry confirmed. Nominal.'}),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final chatService = ChatService(
        apiClient: ApiClient(authService: fakeAuth, httpClient: mockHttp),
        authService: fakeAuth,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChatScreen(chatService: chatService),
        ),
      );

      // Allow async initialization
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Header and initial assistant message
      expect(find.text('TESS COGNITIVE CHAT'), findsOneWidget);
      expect(find.text('Command Thread'), findsOneWidget);
      expect(find.text('TESS online. Trajectories synchronized.'), findsOneWidget);

      // Enter user text
      await tester.enterText(find.byType(TextField), 'Check radar');
      await tester.pump();

      // Tap Send Button
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump(); // Triggers optimistic rendering

      // Optimistic message should appear
      expect(find.text('Check radar'), findsOneWidget);

      // Let network future complete
      await tester.pump(const Duration(milliseconds: 300));

      // Assistant reply should appear
      expect(find.text('Telemetry confirmed. Nominal.'), findsOneWidget);
      // Mascot should be HAPPY
      expect(find.text('Ready to assist'), findsOneWidget);
    });

    testWidgets('Triggers Mascot ATTENTION state when response contains warning keywords', (tester) async {
      final fakeAuth = FakeAuthService(initialAuthenticated: true);

      final mockHttp = MockClient((request) async {
        if (request.url.path == '/api/v1/conversations' && request.method == 'GET') {
          return http.Response(jsonEncode([{'id': 'c1', 'title': 'Alert Thread'}]), 200);
        } else if (request.url.path == '/api/v1/conversations/c1/messages' && request.method == 'GET') {
          return http.Response(jsonEncode([]), 200);
        } else if (request.url.path == '/api/v1/conversations/c1/messages' && request.method == 'POST') {
          return http.Response(
            jsonEncode({'response': 'Critical Warning: Overdue work package detected.'}),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final chatService = ChatService(
        apiClient: ApiClient(authService: fakeAuth, httpClient: mockHttp),
        authService: fakeAuth,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChatScreen(chatService: chatService),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(find.byType(TextField), 'Audit risks');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Needs attention'), findsOneWidget);
    });

    testWidgets('Shows error banner and retry button on transmission failure', (tester) async {
      final fakeAuth = FakeAuthService(initialAuthenticated: true);
      bool shouldFail = true;

      final mockHttp = MockClient((request) async {
        if (request.url.path == '/api/v1/conversations' && request.method == 'GET') {
          return http.Response(jsonEncode([{'id': 'c1', 'title': 'Fail Thread'}]), 200);
        } else if (request.url.path == '/api/v1/conversations/c1/messages' && request.method == 'GET') {
          return http.Response(jsonEncode([]), 200);
        } else if (request.url.path == '/api/v1/conversations/c1/messages' && request.method == 'POST') {
          if (shouldFail) {
            return http.Response(jsonEncode({'detail': 'Neural engine timeout'}), 500);
          }
          return http.Response(jsonEncode({'response': 'Reconnected.'}), 200);
        }
        return http.Response('Not Found', 404);
      });

      final chatService = ChatService(
        apiClient: ApiClient(authService: fakeAuth, httpClient: mockHttp),
        authService: fakeAuth,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChatScreen(chatService: chatService),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(find.byType(TextField), 'Test retry message');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Error banner and failed indicator should appear
      expect(find.text('Failed to transmit. Tap to retry.'), findsOneWidget);
      expect(find.text('Connection error'), findsOneWidget);

      // Now fix backend and tap retry
      shouldFail = false;
      await tester.tap(find.text('Failed to transmit. Tap to retry.'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Reconnected.'), findsOneWidget);
    });
  });

  group('Phase 14.5: MemoryScreen UI & Filter Tests', () {
    testWidgets('Filters memories by category chips and search query', (tester) async {
      final fakeAuth = FakeAuthService(initialAuthenticated: true);

      final mockHttp = MockClient((request) async {
        if (request.url.path == '/api/v1/memories') {
          return http.Response(
            jsonEncode([
              {
                'id': 'm1',
                'category': 'WORK',
                'content': 'Sprint planning on Mondays',
                'importance': 4,
                'is_confirmed': true,
              },
              {
                'id': 'm2',
                'category': 'PERSONAL',
                'content': 'Enjoys espresso before 10 AM',
                'importance': 2,
                'is_confirmed': true,
              },
            ]),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final memoryService = MemoryService(
        apiClient: ApiClient(authService: fakeAuth, httpClient: mockHttp),
        authService: fakeAuth,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MemoryScreen(memoryService: memoryService),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Both should be visible initially under ALL
      expect(find.text('Sprint planning on Mondays'), findsOneWidget);
      expect(find.text('Enjoys espresso before 10 AM'), findsOneWidget);

      // Filter by PERSONAL
      await tester.tap(find.widgetWithText(FilterChip, 'PERSONAL'));
      await tester.pump();

      expect(find.text('Sprint planning on Mondays'), findsNothing);
      expect(find.text('Enjoys espresso before 10 AM'), findsOneWidget);

      // Filter back to ALL
      await tester.tap(find.widgetWithText(FilterChip, 'ALL'));
      await tester.pump();

      // Search query filtering
      await tester.enterText(find.byType(TextField), 'espresso');
      await tester.pump();

      expect(find.text('Sprint planning on Mondays'), findsNothing);
      expect(find.text('Enjoys espresso before 10 AM'), findsOneWidget);
    });

    testWidgets('Renders empty state when no memories exist', (tester) async {
      final fakeAuth = FakeAuthService(initialAuthenticated: true);

      final mockHttp = MockClient((request) async {
        return http.Response(jsonEncode([]), 200);
      });

      final memoryService = MemoryService(
        apiClient: ApiClient(authService: fakeAuth, httpClient: mockHttp),
        authService: fakeAuth,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MemoryScreen(memoryService: memoryService),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('No Personal Memories Stored'), findsOneWidget);
      expect(find.text('Encode First Memory'), findsOneWidget);
    });
  });
}
