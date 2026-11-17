import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tess/core/network/api_client.dart';
import 'package:tess/features/agent/services/agent_service.dart';
import 'package:tess/features/chat/services/chat_service.dart';
import 'package:tess/features/futures/services/future_service.dart';
import 'package:tess/features/home/services/dashboard_service.dart';
import 'package:tess/features/interventions/services/intervention_service.dart';
import 'package:tess/features/memory/services/memory_service.dart';
import 'package:tess/features/voice/controllers/voice_conversation_controller.dart';
import 'package:tess/features/voice/services/device_notification_service.dart';
import 'package:tess/features/voice/services/screen_analysis_service.dart';
import 'package:tess/features/voice/services/voice_api_service.dart';
import 'test_helpers.dart';

void main() {
  group('Phase 14.10: Cross-Feature End-to-End Integration Tests', () {
    test('Workflow A: Productivity Intelligence (Login -> Summary -> Predictions)', () async {
      final fakeAuth = FakeAuthService(initialAuthenticated: true);

      final mockHttp = MockClient((request) async {
        if (request.url.path == '/api/v1/productivity/summary') {
          return http.Response(
            jsonEncode({
              'total_active': 5,
              'overdue': 1,
              'due_today': 2,
              'due_this_week': 4,
              'completed_recently': 3,
            }),
            200,
          );
        }
        if (request.url.path == '/api/v1/future/predictions') {
          return http.Response(
            jsonEncode([
              {
                'id': 'pred_wf_a',
                'title': 'Milestone Convergence Risk',
                'prediction_type': 'RISK',
                'time_horizon': '72h',
                'confidence': 'HIGH',
                'probability': 85.0,
              }
            ]),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(authService: fakeAuth, httpClient: mockHttp);
      final dashboardService = DashboardService(apiClient: apiClient, authService: fakeAuth);

      final dashboard = await dashboardService.fetchDashboardData();
      expect(dashboard.summary.totalActive, 5);
      expect(dashboard.summary.overdue, 1);
      expect(dashboard.predictions.length, 1);
      expect(dashboard.predictions.first.isRisk, true);
      expect(dashboard.predictions.first.probability, 85.0);
    });

    test('Workflow B: Memory Continuity (Create Memory -> Conversation Context)', () async {
      final fakeAuth = FakeAuthService(initialAuthenticated: true);
      final memoryStore = <Map<String, dynamic>>[];

      final mockHttp = MockClient((request) async {
        if (request.url.path == '/api/v1/memories' && request.method == 'POST') {
          final body = jsonDecode(request.body);
          final mem = {
            'id': 'mem_01',
            'user_id': 'u1',
            'category': body['category'] ?? 'PREFERENCE',
            'content': body['content'],
            'importance': body['importance'] ?? 5,
            'source': 'flutter_workflow_test',
          };
          memoryStore.add(mem);
          return http.Response(jsonEncode(mem), 200);
        }
        if (request.url.path == '/api/v1/conversations' && request.method == 'POST') {
          return http.Response(jsonEncode({'id': 'conv_wf_b', 'title': 'Context Thread'}), 200);
        }
        if (request.url.path == '/api/v1/conversations/conv_wf_b/messages' && request.method == 'POST') {
          // Assistant recalls created memory
          final contextContent = memoryStore.isNotEmpty ? memoryStore.first['content'] : 'No memory';
          return http.Response(
            jsonEncode({
              'response': 'I recall your preference: "$contextContent". Let us proceed accordingly.'
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(authService: fakeAuth, httpClient: mockHttp);
      final memoryService = MemoryService(apiClient: apiClient, authService: fakeAuth);
      final chatService = ChatService(apiClient: apiClient, authService: fakeAuth);

      // 1. Create personal memory
      final createdMem = await memoryService.createMemory(
        category: 'PREFERENCE',
        content: 'Prefers concise bullet-point task summaries',
        importance: 5,
      );
      expect(createdMem.content, contains('bullet-point'));

      // 2. Start conversation thread
      final conv = await chatService.createConversation(title: 'Context Thread');

      // 3. Ask question and verify memory context in response
      final reply = await chatService.sendMessage(
        conversationId: conv.id,
        message: 'How should my task reviews be formatted?',
      );
      expect(reply, contains('bullet-point task summaries'));
    });

    test('Workflow C: Future Correction (Prediction -> Intervention -> Agent Objective)', () async {
      final fakeAuth = FakeAuthService(initialAuthenticated: true);

      final mockHttp = MockClient((request) async {
        if (request.url.path == '/api/v1/future/predictions') {
          return http.Response(
            jsonEncode([
              {
                'id': 'pred_intv_wf',
                'title': 'Overdue OpenProject Package #402',
                'category': 'WORKLOAD_SPIKE',
                'probability': 0.90,
                'confidence': 'HIGH',
              }
            ]),
            200,
          );
        }
        if (request.url.path == '/api/v1/proactive/interventions') {
          return http.Response(
            jsonEncode([
              {
                'id': 'intv_corr',
                'prediction_id': 'pred_intv_wf',
                'priority': 'CRITICAL',
                'title': 'Overdue Work Package Conflict',
                'message': 'Work package #402 is 24h overdue. Log 2 hours to prevent milestone slip.',
                'value_score': 9.2,
                'status': 'SENT',
              }
            ]),
            200,
          );
        }
        if (request.url.path == '/api/v1/proactive/interventions/intv_corr/respond') {
          return http.Response(jsonEncode({'status': 'success'}), 200);
        }
        if (request.url.path == '/api/v1/agent/objectives') {
          return http.Response(
            jsonEncode({
              'id': 'plan_wf_c',
              'user_id': 'u1',
              'objective': 'Log 2 hours on work package #402',
              'status': 'READY',
              'steps': [
                {
                  'id': 'step_wf_c',
                  'plan_id': 'plan_wf_c',
                  'step_order': 1,
                  'tool_name': 'openproject_update_worklog',
                  'action_type': 'UPDATE_WORKLOG',
                  'parameters': {'task_id': '402', 'hours': 2.0},
                  'risk_level': 'MEDIUM',
                  'status': 'PENDING',
                }
              ],
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(authService: fakeAuth, httpClient: mockHttp);
      final futureService = FutureService(apiClient: apiClient, authService: fakeAuth);
      final interventionService = InterventionService(apiClient: apiClient, authService: fakeAuth);
      final agentService = AgentService(apiClient: apiClient, authService: fakeAuth);

      // 1. View future prediction
      final predictions = await futureService.getPredictions();
      expect(predictions.first.id, 'pred_intv_wf');

      // 2. Retrieve corresponding proactive intervention
      final interventions = await interventionService.getInterventions();
      final intervention = interventions.first;
      expect(intervention.predictionId, 'pred_intv_wf');

      // 3. Accept intervention
      await interventionService.respondIntervention(interventionId: intervention.id, action: 'ACTED');

      // 4. Formulate Agent Objective directly from intervention directive
      final plan = await agentService.createObjective('Log 2 hours on work package #402');
      expect(plan.steps.length, 1);
      expect(plan.steps.first.toolName, 'openproject_update_worklog');
      expect(plan.steps.first.parameters['hours'], 2.0);
    });

    test('Workflow D: Approved Action (Plan Formulation -> Review -> Confirmation -> Execution)', () async {
      final fakeAuth = FakeAuthService(initialAuthenticated: true);
      bool wasConfirmed = false;
      bool wasExecuted = false;

      final mockHttp = MockClient((request) async {
        if (request.url.path == '/api/v1/agent/objectives' && request.method == 'POST') {
          return http.Response(
            jsonEncode({
              'id': 'plan_d',
              'user_id': 'u1',
              'objective': 'Update OpenProject worklog: 2 hours on task 1',
              'status': 'READY',
              'steps': [
                {
                  'id': 'st_d1',
                  'plan_id': 'plan_d',
                  'step_order': 1,
                  'tool_name': 'openproject_update_worklog',
                  'action_type': 'UPDATE_WORKLOG',
                  'parameters': {'task_id': '1', 'hours': 2.0},
                  'risk_level': 'MEDIUM',
                  'status': 'PENDING',
                  'confirmation': {
                    'id': 'cf_d1',
                    'status': 'PENDING',
                    'summary': 'Update task 1 with 2 hours [fp:d0e1f2a3b4c5]',
                  },
                }
              ],
            }),
            200,
          );
        }
        if (request.url.path == '/api/v1/agent/plans/plan_d/confirm' && request.method == 'POST') {
          wasConfirmed = true;
          return http.Response(jsonEncode({'status': 'success', 'confirmed_count': 1}), 200);
        }
        if (request.url.path == '/api/v1/agent/plans/plan_d/execute' && request.method == 'POST') {
          if (!wasConfirmed) {
            return http.Response('{"detail": "PermissionError: Step unconfirmed"}', 403);
          }
          wasExecuted = true;
          return http.Response(jsonEncode({'status': 'success', 'results': [{'task_id': '1', 'updated': true}]}), 200);
        }
        return http.Response('Not Found', 404);
      });

      final service = AgentService(
        apiClient: ApiClient(authService: fakeAuth, httpClient: mockHttp),
        authService: fakeAuth,
      );

      // 1. Generate Plan
      final plan = await service.createObjective('Update OpenProject worklog: 2 hours on task 1');
      expect(plan.isExecutable, false); // requires confirmation first

      // 2. Confirm Plan
      final confRes = await service.confirmPlan(plan.id);
      expect(confRes['confirmed_count'], 1);

      // 3. Execute Plan
      final execRes = await service.executePlan(plan.id);
      expect(wasExecuted, true);
      expect(execRes.isSuccess, true);
    });

    test('Workflow E: Voice Interaction (Record -> STT -> Review -> Chat -> TTS)', () async {
      final fakeAuth = FakeAuthService(initialAuthenticated: true);

      final mockHttp = MockClient((request) async {
        if (request.url.path == '/api/v1/voice/transcribe') {
          return http.Response(jsonEncode({'transcript': 'Draft status update to team'}), 200);
        }
        if (request.url.path == '/api/v1/conversations') {
          return http.Response(jsonEncode({'id': 'conv_wf_e', 'title': 'Voice Directive'}), 200);
        }
        if (request.url.path == '/api/v1/conversations/conv_wf_e/messages') {
          return http.Response(jsonEncode({'response': 'Draft prepared and queued for review.'}), 200);
        }
        if (request.url.path == '/api/v1/voice/synthesize') {
          return http.Response.bytes(Uint8List.fromList([82, 73, 70, 70, 0, 0, 0, 0, 87, 65, 86, 69]), 200);
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(authService: fakeAuth, httpClient: mockHttp);
      final voiceApi = VoiceApiService(apiClient: apiClient);
      final chatService = ChatService(apiClient: apiClient, authService: fakeAuth);

      final controller = VoiceConversationController(
        voiceApi: voiceApi,
        chatService: chatService,
      );

      // 1. Record & Transcribe
      await controller.startRecording();
      await Future.delayed(const Duration(milliseconds: 250));
      await controller.stopRecordingAndTranscribe();

      expect(controller.transcription?.originalTranscript, 'Draft status update to team');

      // 2. Edit Transcript
      controller.editTranscript('Draft priority status update to engineering');
      expect(controller.transcription?.effectiveText, 'Draft priority status update to engineering');

      // 3. Submit to Chat
      await controller.submitTranscriptToChat();
      expect(controller.aiResponseText, 'Draft prepared and queued for review.');

      // 4. Verify TTS Audio synthesis & playback
      expect(controller.aiAudioBytes?.isNotEmpty, true);
      expect(controller.playbackState.isPlaying, true);

      controller.dispose();
    });

    test('Workflow F: Consented Screen Understanding (Consent -> Validate -> Analyze)', () async {
      final fakeAuth = FakeAuthService(initialAuthenticated: true);

      final mockHttp = MockClient((request) async {
        if (request.url.path == '/api/v1/screen/analyze') {
          return http.Response(
            jsonEncode({
              'query': 'Inspect terminal output',
              'dimensions': {'width': 1920, 'height': 1080},
              'analysis': 'Build failed due to missing dependency in pubspec.yaml.',
              'suggestions': ['Run flutter pub get', 'Check package version constraints'],
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final service = ScreenAnalysisService(
        apiClient: ApiClient(authService: fakeAuth, httpClient: mockHttp),
      );

      final validPng = [
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
        0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
      ];

      // Rejects without consent
      expect(
        () => service.analyzeScreen(imageBytes: validPng, query: 'Inspect', hasUserConsent: false),
        throwsA(isA<ApiException>()),
      );

      // Succeeds with explicit consent
      final result = await service.analyzeScreen(
        imageBytes: validPng,
        query: 'Inspect terminal output',
        hasUserConsent: true,
      );
      expect(result.width, 1920);
      expect(result.analysis, contains('missing dependency'));
      expect(result.suggestions.length, 2);
    });

    test('Workflow G: Cross-Device Continuity (Device Registration & Telemetry Query)', () async {
      final fakeAuth = FakeAuthService(initialAuthenticated: true);
      final registeredDevices = <Map<String, dynamic>>[];

      final mockHttp = MockClient((request) async {
        if (request.url.path == '/api/v1/devices/register' && request.method == 'POST') {
          final body = jsonDecode(request.body);
          final entry = {
            'device_id': body['device_id'],
            'device_name': body['device_name'],
            'platform': body['platform'],
            'last_seen_at': DateTime.now().toUtc().toIso8601String(),
          };
          registeredDevices.add(entry);
          return http.Response(jsonEncode({'status': 'success', 'device_id': body['device_id']}), 200);
        }
        if (request.url.path == '/api/v1/devices' && request.method == 'GET') {
          return http.Response(jsonEncode(registeredDevices), 200);
        }
        return http.Response('Not Found', 404);
      });

      final service = DeviceNotificationService(
        apiClient: ApiClient(authService: fakeAuth, httpClient: mockHttp),
      );

      // 1. Register Flutter mobile client
      await service.registerDevice(deviceId: 'tess-flutter-client', deviceName: 'Android Mobile Terminal', platform: 'android');

      // 2. Query registered devices (simulating desktop TESS checking peer active sessions)
      final devices = await service.getRegisteredDevices();
      expect(devices.length, 1);
      expect(devices.first.deviceId, 'tess-flutter-client');
      expect(devices.first.platform, 'android');
    });
  });
}
