import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tess/core/network/api_client.dart';
import 'package:tess/features/chat/services/chat_service.dart';
import 'package:tess/features/voice/controllers/voice_conversation_controller.dart';
import 'package:tess/features/voice/models/audio_playback_state.dart';
import 'package:tess/features/voice/models/device_registration_model.dart';
import 'package:tess/features/voice/models/screen_analysis_model.dart';
import 'package:tess/features/voice/models/speech_transcription_model.dart';
import 'package:tess/features/voice/models/voice_interaction_model.dart';
import 'package:tess/features/voice/screens/voice_screen.dart';
import 'package:tess/features/voice/services/audio_playback_service.dart';
import 'package:tess/features/voice/services/audio_recorder_service.dart';
import 'package:tess/features/voice/services/device_notification_service.dart';
import 'package:tess/features/voice/services/screen_analysis_service.dart';
import 'package:tess/features/voice/services/voice_api_service.dart';
import 'package:tess/features/voice/widgets/transcript_review_card.dart';
import 'package:tess/features/voice/widgets/tts_player_widget.dart';
import 'package:tess/features/voice/widgets/voice_recorder_button.dart';
import 'test_helpers.dart';

void main() {
  group('Phase 14.9: Audio Recording & Permission Lifecycle', () {
    test('AudioRecorderService records audio, updates duration and generates valid WAV', () async {
      final recorder = AudioRecorderService();
      expect(recorder.isRecording, false);

      await recorder.startRecording();
      expect(recorder.isRecording, true);

      // Simulate 300ms recording duration
      await Future.delayed(const Duration(milliseconds: 300));
      final bytes = await recorder.stopRecording();

      expect(recorder.isRecording, false);
      expect(bytes.isNotEmpty, true);
      expect(AudioRecorderService.isValidWav(bytes), true);

      recorder.dispose();
    });

    test('AudioRecorderService throws Exception when microphone permission is denied', () async {
      final recorder = AudioRecorderService();
      recorder.setPermissionDenied();

      expect(() => recorder.startRecording(), throwsA(isA<Exception>()));
      recorder.dispose();
    });

    test('AudioRecorderService cancels active recording cleanly', () async {
      final recorder = AudioRecorderService();
      await recorder.startRecording();
      expect(recorder.isRecording, true);

      recorder.cancelRecording();
      expect(recorder.isRecording, false);
      expect(recorder.currentDuration, Duration.zero);

      recorder.dispose();
    });
  });

  group('Phase 14.9: Voice & Device Models & Parsing', () {
    test('SpeechTranscriptionModel handles inline edits and effective text', () {
      final model = SpeechTranscriptionModel.fromApi('Create high priority task');
      expect(model.originalTranscript, 'Create high priority task');
      expect(model.effectiveText, 'Create high priority task');
      expect(model.isEdited, false);

      final edited = model.copyWith(editedTranscript: 'Create critical priority task');
      expect(edited.effectiveText, 'Create critical priority task');
      expect(edited.isEdited, true);
      expect(edited.isEmpty, false);
    });

    test('VoiceInteractionModel parses base64 audio and text', () {
      final json = {
        'transcript': 'Status check',
        'response_text': 'Neural core nominal',
        'audio_base64': base64Encode(Uint8List.fromList([1, 2, 3, 4])),
      };

      final model = VoiceInteractionModel.fromJson(json);
      expect(model.transcript, 'Status check');
      expect(model.responseText, 'Neural core nominal');
      expect(model.hasAudio, true);
      expect(model.audioBytes.length, 4);
    });

    test('AudioPlaybackState progress calculation and status helpers', () {
      const state = AudioPlaybackState(
        status: AudioPlaybackStatus.playing,
        position: Duration(seconds: 15),
        duration: Duration(seconds: 60),
      );

      expect(state.isPlaying, true);
      expect(state.isPaused, false);
      expect(state.progress, 0.25);
    });

    test('DeviceRegistrationModel parses device id, platform and permission', () {
      final json = {
        'device_id': 'device-android-100',
        'device_name': 'Pixel 8 Pro',
        'platform': 'android',
        'notification_permission': 'granted',
      };

      final device = DeviceRegistrationModel.fromJson(json);
      expect(device.deviceId, 'device-android-100');
      expect(device.isNotificationsEnabled, true);
      expect(device.platform, 'android');
    });

    test('ScreenAnalysisModel parses query, dimensions and vision suggestions', () {
      final json = {
        'query': 'Troubleshoot crash',
        'dimensions': {'width': 1080, 'height': 2400},
        'analysis': 'Memory overflow detected in log output.',
        'suggestions': ['Increase buffer', 'Inspect network tab'],
      };

      final screen = ScreenAnalysisModel.fromJson(json);
      expect(screen.query, 'Troubleshoot crash');
      expect(screen.resolutionDisplay, '1080x2400 px');
      expect(screen.analysis, contains('Memory overflow'));
      expect(screen.suggestions.length, 2);
    });
  });

  group('Phase 14.9: VoiceApiService Mocked Unit Tests', () {
    test('transcribeAudio, synthesizeSpeech, and voiceInteract call expected endpoints', () async {
      final fakeAuth = FakeAuthService(initialAuthenticated: true);

      final mockHttp = MockClient((request) async {
        if (request.url.path == '/api/v1/voice/transcribe' && request.method == 'POST') {
          return http.Response(jsonEncode({'transcript': 'Voice directive test'}), 200);
        }
        if (request.url.path == '/api/v1/voice/synthesize' && request.method == 'POST') {
          return http.Response.bytes(Uint8List.fromList([82, 73, 70, 70]), 200);
        }
        if (request.url.path == '/api/v1/voice/interact' && request.method == 'POST') {
          return http.Response(
            jsonEncode({
              'transcript': 'What is my plan?',
              'response_text': 'You have 2 pending tasks.',
              'audio_base64': base64Encode(Uint8List.fromList([1, 2, 3])),
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final voiceApi = VoiceApiService(
        apiClient: ApiClient(authService: fakeAuth, httpClient: mockHttp),
      );

      final sampleWav = Uint8List.fromList([82, 73, 70, 70, 0, 0, 0, 0, 87, 65, 86, 69]);
      final transcript = await voiceApi.transcribeAudio(sampleWav);
      expect(transcript, 'Voice directive test');

      final audioBytes = await voiceApi.synthesizeSpeech('Hello from TESS');
      expect(audioBytes.length, 4);

      final cycle = await voiceApi.voiceInteract(sampleWav);
      expect(cycle.transcript, 'What is my plan?');
      expect(cycle.responseText, 'You have 2 pending tasks.');
      expect(cycle.hasAudio, true);
    });

    test('VoiceApiService handles 401 Unauthorized by throwing ApiException', () async {
      final fakeAuth = FakeAuthService(initialAuthenticated: false);
      final mockHttp = MockClient((request) async {
        return http.Response('{"detail": "Unauthorized session token"}', 401);
      });

      final voiceApi = VoiceApiService(
        apiClient: ApiClient(authService: fakeAuth, httpClient: mockHttp),
      );

      expect(
        () => voiceApi.transcribeAudio(Uint8List.fromList([1, 2, 3, 4])),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('Phase 14.9: Device Notification & Screen Analysis Services', () {
    test('DeviceNotificationService registers terminal token with backend', () async {
      final fakeAuth = FakeAuthService(initialAuthenticated: true);
      final mockHttp = MockClient((request) async {
        if (request.url.path == '/api/v1/devices/register' && request.method == 'POST') {
          return http.Response(jsonEncode({'status': 'success', 'device_id': 'pixel-01'}), 200);
        }
        if (request.url.path == '/api/v1/devices' && request.method == 'GET') {
          return http.Response(
            jsonEncode([
              {
                'device_id': 'pixel-01',
                'device_name': 'Pixel Terminal',
                'platform': 'android',
              }
            ]),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final service = DeviceNotificationService(
        apiClient: ApiClient(authService: fakeAuth, httpClient: mockHttp),
      );

      final registered = await service.registerDevice(deviceId: 'pixel-01');
      expect(registered.deviceId, 'pixel-01');

      final list = await service.getRegisteredDevices();
      expect(list.length, 1);
      expect(list.first.deviceId, 'pixel-01');
    });

    test('ScreenAnalysisService requires explicit consent before uploading screenshot', () async {
      final fakeAuth = FakeAuthService(initialAuthenticated: true);
      final mockHttp = MockClient((request) async {
        return http.Response(jsonEncode({}), 200);
      });

      final service = ScreenAnalysisService(
        apiClient: ApiClient(authService: fakeAuth, httpClient: mockHttp),
      );

      // Must reject when hasUserConsent is false
      expect(
        () => service.analyzeScreen(
          imageBytes: [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A],
          query: 'Check errors',
          hasUserConsent: false,
        ),
        throwsA(isA<ApiException>()),
      );
    });

    test('ScreenAnalysisService submits consented screenshot and parses vision response', () async {
      final fakeAuth = FakeAuthService(initialAuthenticated: true);
      final mockHttp = MockClient((request) async {
        if (request.url.path == '/api/v1/screen/analyze' && request.method == 'POST') {
          return http.Response(
            jsonEncode({
              'query': 'Explain error',
              'dimensions': {'width': 800, 'height': 600},
              'analysis': 'Null pointer exception detected at line 42.',
              'suggestions': ['Check reference initialization'],
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

      final result = await service.analyzeScreen(
        imageBytes: validPng,
        query: 'Explain error',
        hasUserConsent: true,
      );

      expect(result.width, 800);
      expect(result.analysis, contains('Null pointer'));
      expect(result.suggestions.length, 1);
    });
  });

  group('Phase 14.9: Audio Playback Service Unit Tests', () {
    test('AudioPlaybackService plays bytes, updates status, and stops cleanly', () async {
      final playback = AudioPlaybackService();
      expect(playback.state.isStopped, true);

      final fakeWavBytes = Uint8List.fromList(List.filled(1000, 0));
      await playback.playBytes(fakeWavBytes, estimatedDuration: const Duration(milliseconds: 500));
      expect(playback.state.isPlaying, true);

      playback.pause();
      expect(playback.state.isPaused, true);

      playback.resume();
      expect(playback.state.isPlaying, true);

      playback.stop();
      expect(playback.state.isStopped, true);

      playback.dispose();
    });
  });

  group('Phase 14.9: VoiceScreen UI & Interaction Tests', () {
    testWidgets('Renders microphone recorder button, stops recording, and displays review card', (tester) async {
      final fakeAuth = FakeAuthService(initialAuthenticated: true);

      final mockHttp = MockClient((request) async {
        if (request.url.path == '/api/v1/voice/transcribe' && request.method == 'POST') {
          return http.Response(jsonEncode({'transcript': 'Schedule strategy briefing tomorrow'}), 200);
        }
        if (request.url.path == '/api/v1/devices' && request.method == 'GET') {
          return http.Response(jsonEncode([]), 200);
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(authService: fakeAuth, httpClient: mockHttp);
      final voiceApi = VoiceApiService(apiClient: apiClient);
      final deviceService = DeviceNotificationService(apiClient: apiClient);

      final controller = VoiceConversationController(voiceApi: voiceApi);

      await tester.pumpWidget(
        MaterialApp(
          home: VoiceScreen(
            controller: controller,
            deviceService: deviceService,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(VoiceRecorderButton), findsOneWidget);
      expect(find.text('Tap to Speak Directive'), findsOneWidget);

      // Start recording
      await tester.tap(find.byType(VoiceRecorderButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(controller.isRecording, true);

      // Stop recording
      await tester.tap(find.byType(VoiceRecorderButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Review card should be rendered
      expect(find.byType(TranscriptReviewCard), findsOneWidget);
      expect(find.text('Schedule strategy briefing tomorrow'), findsOneWidget);
      expect(find.text('Submit to Chat'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('Submitting transcript transmits to chat and renders TTS player', (tester) async {
      final fakeAuth = FakeAuthService(initialAuthenticated: true);

      final mockHttp = MockClient((request) async {
        if (request.url.path == '/api/v1/conversations' && request.method == 'POST') {
          return http.Response(jsonEncode({'id': 'conv_voice', 'title': 'Voice Directive'}), 200);
        }
        if (request.url.path == '/api/v1/conversations/conv_voice/messages' && request.method == 'POST') {
          return http.Response(jsonEncode({'response': 'Strategy session registered on your calendar.'}), 200);
        }
        if (request.url.path == '/api/v1/voice/synthesize' && request.method == 'POST') {
          return http.Response.bytes(Uint8List.fromList([82, 73, 70, 70]), 200);
        }
        if (request.url.path == '/api/v1/devices' && request.method == 'GET') {
          return http.Response(jsonEncode([]), 200);
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(authService: fakeAuth, httpClient: mockHttp);
      final voiceApi = VoiceApiService(apiClient: apiClient);
      final chatService = ChatService(apiClient: apiClient, authService: fakeAuth);
      final deviceService = DeviceNotificationService(apiClient: apiClient);

      final controller = VoiceConversationController(
        voiceApi: voiceApi,
        chatService: chatService,
      );

      // Pre-set transcript to simulate STT output
      controller.editTranscript('Schedule strategy briefing');

      await tester.pumpWidget(
        MaterialApp(
          home: VoiceScreen(
            controller: controller,
            deviceService: deviceService,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Submit to Chat'), findsOneWidget);

      await tester.tap(find.text('Submit to Chat'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Check Assistant response and TTS player controls
      expect(find.byType(TTSPlayerWidget), findsOneWidget);
      expect(find.text('Strategy session registered on your calendar.'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('Device & Vision tab switching and device registration flow', (tester) async {
      final fakeAuth = FakeAuthService(initialAuthenticated: true);

      final mockHttp = MockClient((request) async {
        if (request.url.path == '/api/v1/devices' && request.method == 'GET') {
          return http.Response(jsonEncode([]), 200);
        }
        if (request.url.path == '/api/v1/devices/register' && request.method == 'POST') {
          return http.Response(jsonEncode({'status': 'success', 'device_id': 'pixel-test-terminal'}), 200);
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(authService: fakeAuth, httpClient: mockHttp);
      final deviceService = DeviceNotificationService(apiClient: apiClient);

      await tester.pumpWidget(
        MaterialApp(
          home: VoiceScreen(deviceService: deviceService),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Switch to DEVICE & VISION tab
      await tester.tap(find.text('DEVICE & VISION'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('DEVICE NOTIFICATION IDENTITY'), findsOneWidget);
      expect(find.text('Register Device Terminal'), findsOneWidget);

      // Tap Register Device Terminal
      await tester.tap(find.text('Register Device Terminal'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('REGISTERED'), findsOneWidget);
      expect(find.text('Notifications Ready'), findsOneWidget);
    });
  });
}
