import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tess/core/network/api_client.dart';
import 'package:tess/features/interventions/models/intervention_effectiveness_model.dart';
import 'package:tess/features/interventions/models/intervention_model.dart';
import 'package:tess/features/interventions/screens/interventions_screen.dart';
import 'package:tess/features/interventions/services/intervention_service.dart';
import 'test_helpers.dart';

void main() {
  group('Phase 14.7: Intervention Models & JSON Parsing', () {
    test('InterventionModel parses CRITICAL priority, value score, and date', () {
      final json = {
        'id': 'intv_001',
        'user_id': 'usr_999',
        'type': 'SCHEDULE_WARNING',
        'priority': 'CRITICAL',
        'title': 'Overdue Work Package Conflict',
        'message': 'Work package #402 is 24h overdue and blocks milestone.',
        'reason': 'Context convergence risk detected by Future Engine.',
        'value_score': 8.8,
        'status': 'SENT',
        'created_at': '2026-11-17T11:00:00Z',
      };

      final model = InterventionModel.fromJson(json);
      expect(model.id, 'intv_001');
      expect(model.isCritical, true);
      expect(model.isHighPriority, true);
      expect(model.isPending, true);
      expect(model.isActed, false);
      expect(model.valueScore, 8.8);
      expect(model.formattedValueScore, 'Value: 8.8 / 10');
      expect(model.formattedTime.isNotEmpty, true);

      final serialized = model.toJson();
      expect(serialized['id'], 'intv_001');
      expect(serialized['priority'], 'CRITICAL');
    });

    test('InterventionModel handles defaults for missing optional fields', () {
      final model = InterventionModel.fromJson({'title': 'Generic Advice'});
      expect(model.priority, 'MEDIUM');
      expect(model.valueScore, 5.0);
      expect(model.status, 'SENT');
      expect(model.isCritical, false);
      expect(model.isPending, true);
    });

    test('InterventionEffectivenessModel parses acceptance and conversion rates', () {
      final json = {
        'total_interventions': 10,
        'accepted_count': 8,
        'dismissed_count': 2,
        'actions_completed_count': 6,
        'acceptance_rate': 0.80, // 80%
        'action_conversion_rate': 0.75, // 75%
        'insights': [
          '80% of proactive suggestions were accepted by user.',
          '6 actions completed through autonomous confirmation workflows.',
        ],
      };

      final model = InterventionEffectivenessModel.fromJson(json);
      expect(model.totalInterventions, 10);
      expect(model.acceptedCount, 8);
      expect(model.acceptanceRatePercentage, 80.0);
      expect(model.actionConversionRatePercentage, 75.0);
      expect(model.insights.length, 2);
    });
  });

  group('Phase 14.7: InterventionService Mocked Unit Tests', () {
    test('getInterventions and evaluateProactive retrieve intervention lists', () async {
      final fakeAuth = FakeAuthService(initialAuthenticated: true);

      final mockHttp = MockClient((request) async {
        if (request.url.path == '/api/v1/proactive/interventions' && request.method == 'GET') {
          return http.Response(
            jsonEncode([
              {
                'id': 'i1',
                'priority': 'HIGH',
                'title': 'High Load Warning',
                'status': 'SENT',
              }
            ]),
            200,
          );
        } else if (request.url.path == '/api/v1/proactive/evaluate' && request.method == 'POST') {
          return http.Response(
            jsonEncode([
              {
                'id': 'i_spawned',
                'priority': 'CRITICAL',
                'title': 'Schedule Block Required',
                'status': 'SENT',
              }
            ]),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final service = InterventionService(
        apiClient: ApiClient(authService: fakeAuth, httpClient: mockHttp),
        authService: fakeAuth,
      );

      final list = await service.getInterventions();
      expect(list.length, 1);
      expect(list.first.isPending, true);

      final spawned = await service.evaluateProactive();
      expect(spawned.length, 1);
      expect(spawned.first.isCritical, true);
    });

    test('respondIntervention posts ACTED, LATER, and DISMISS actions', () async {
      final fakeAuth = FakeAuthService(initialAuthenticated: true);
      String lastAction = '';

      final mockHttp = MockClient((request) async {
        if (request.url.path == '/api/v1/proactive/interventions/i1/respond' && request.method == 'POST') {
          final body = jsonDecode(request.body);
          lastAction = body['action'];
          return http.Response(jsonEncode({'status': 'success'}), 200);
        }
        return http.Response('Not Found', 404);
      });

      final service = InterventionService(
        apiClient: ApiClient(authService: fakeAuth, httpClient: mockHttp),
        authService: fakeAuth,
      );

      await service.respondIntervention(interventionId: 'i1', action: 'ACTED');
      expect(lastAction, 'ACTED');

      await service.respondIntervention(interventionId: 'i1', action: 'LATER');
      expect(lastAction, 'LATER');

      await service.respondIntervention(interventionId: 'i1', action: 'DISMISS');
      expect(lastAction, 'DISMISS');
    });

    test('getEffectiveness retrieves empirical conversion model', () async {
      final fakeAuth = FakeAuthService(initialAuthenticated: true);

      final mockHttp = MockClient((request) async {
        if (request.url.path == '/api/v1/future/intervention-effectiveness') {
          return http.Response(
            jsonEncode({
              'total_interventions': 5,
              'accepted_count': 4,
              'dismissed_count': 1,
              'actions_completed_count': 3,
              'acceptance_rate': 0.8,
              'action_conversion_rate': 0.75,
              'insights': ['High acceptance observed.'],
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final service = InterventionService(
        apiClient: ApiClient(authService: fakeAuth, httpClient: mockHttp),
        authService: fakeAuth,
      );

      final eff = await service.getEffectiveness();
      expect(eff.totalInterventions, 5);
      expect(eff.acceptedCount, 4);
      expect(eff.insights.first, contains('High acceptance'));
    });

    test('InterventionService handles 401 Unauthorized by throwing ApiException', () async {
      final fakeAuth = FakeAuthService(initialAuthenticated: true);
      final mockHttp = MockClient((request) async {
        return http.Response(jsonEncode({'detail': 'Not authenticated'}), 401);
      });

      final service = InterventionService(
        apiClient: ApiClient(authService: fakeAuth, httpClient: mockHttp),
        authService: fakeAuth,
      );

      expect(
        () => service.getInterventions(),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('Phase 14.7: InterventionsScreen UI & Interaction Tests', () {
    testWidgets('Renders pending recommendations, executes user actions and prevents duplicate submissions', (tester) async {
      final fakeAuth = FakeAuthService(initialAuthenticated: true);
      String recordedAction = '';

      final mockHttp = MockClient((request) async {
        if (request.url.path == '/api/v1/proactive/interventions' && request.method == 'GET') {
          return http.Response(
            jsonEncode([
              {
                'id': 'intv_act',
                'priority': 'CRITICAL',
                'title': 'Overdue Sprint Task',
                'message': 'Package #102 is overdue.',
                'reason': 'Deadline crossed yesterday',
                'value_score': 9.2,
                'status': 'SENT',
              }
            ]),
            200,
          );
        } else if (request.url.path.contains('/respond') && request.method == 'POST') {
          final body = jsonDecode(request.body);
          recordedAction = body['action'];
          return http.Response(jsonEncode({'status': 'success'}), 200);
        }
        return http.Response(jsonEncode({}), 200);
      });

      final interventionService = InterventionService(
        apiClient: ApiClient(authService: fakeAuth, httpClient: mockHttp),
        authService: fakeAuth,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: InterventionsScreen(interventionService: interventionService),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 1. Verify Header & Mascot ATTENTION state due to CRITICAL priority
      expect(find.text('PROACTIVE INTELLIGENCE'), findsOneWidget);
      expect(find.text('CRITICAL INTERVENTION ACTION REQUIRED'), findsOneWidget);

      // 2. Verify Card Content
      expect(find.text('Overdue Sprint Task'), findsOneWidget);
      expect(find.text('CRITICAL'), findsOneWidget);
      expect(find.text('Value: 9.2 / 10'), findsOneWidget);
      expect(find.textContaining('Deadline crossed yesterday'), findsOneWidget);

      // 3. Tap FIX IT / ACT Button
      final fixItFinder = find.text('FIX IT / ACT');
      expect(fixItFinder, findsOneWidget);
      await tester.tap(fixItFinder);
      await tester.pump(); // Triggers optimistic submission

      // Verify action was posted
      await tester.pump(const Duration(milliseconds: 300));
      expect(recordedAction, 'ACTED');

      // Status should transition from PENDING to ACCEPTED & ACTED
      // In PENDING tab, list should now be empty
      expect(find.text('No Pending Interventions'), findsOneWidget);

      // 4. Switch to HISTORY Tab and verify acted intervention is cataloged
      await tester.tap(find.text('HISTORY'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Overdue Sprint Task'), findsOneWidget);
      expect(find.text('ACCEPTED & ACTED'), findsOneWidget);
    });

    testWidgets('Postpone (Later) updates status to DEFERRED', (tester) async {
      final fakeAuth = FakeAuthService(initialAuthenticated: true);
      String recordedAction = '';

      final mockHttp = MockClient((request) async {
        if (request.url.path == '/api/v1/proactive/interventions' && request.method == 'GET') {
          return http.Response(
            jsonEncode([
              {
                'id': 'intv_defer',
                'priority': 'MEDIUM',
                'title': 'Take a breather',
                'message': 'Continuous 90m work period.',
                'value_score': 6.0,
                'status': 'SENT',
              }
            ]),
            200,
          );
        } else if (request.url.path.contains('/respond') && request.method == 'POST') {
          final body = jsonDecode(request.body);
          recordedAction = body['action'];
          return http.Response(jsonEncode({'status': 'success'}), 200);
        }
        return http.Response(jsonEncode({}), 200);
      });

      final interventionService = InterventionService(
        apiClient: ApiClient(authService: fakeAuth, httpClient: mockHttp),
        authService: fakeAuth,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: InterventionsScreen(interventionService: interventionService),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap Later (4h)
      await tester.tap(find.text('Later (4h)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(recordedAction, 'LATER');

      // Switch to HISTORY tab
      await tester.tap(find.text('HISTORY'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('DEFERRED (POSTPONED)'), findsOneWidget);
    });

    testWidgets('Renders empty state when no interventions exist', (tester) async {
      final fakeAuth = FakeAuthService(initialAuthenticated: true);

      final mockHttp = MockClient((request) async {
        return http.Response(jsonEncode([]), 200);
      });

      final interventionService = InterventionService(
        apiClient: ApiClient(authService: fakeAuth, httpClient: mockHttp),
        authService: fakeAuth,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: InterventionsScreen(interventionService: interventionService),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('No Pending Interventions'), findsOneWidget);
      expect(find.text('NO INTERVENTIONS PENDING // TRAJECTORY NOMINAL'), findsOneWidget);
    });

    testWidgets('Displays error banner and retry button on API failure', (tester) async {
      final fakeAuth = FakeAuthService(initialAuthenticated: true);
      bool shouldFail = true;

      final mockHttp = MockClient((request) async {
        if (shouldFail) {
          return http.Response(jsonEncode({'detail': 'Decision engine offline'}), 503);
        }
        return http.Response(jsonEncode([]), 200);
      });

      final interventionService = InterventionService(
        apiClient: ApiClient(authService: fakeAuth, httpClient: mockHttp),
        authService: fakeAuth,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: InterventionsScreen(interventionService: interventionService),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Retry'), findsOneWidget);

      // Fix backend state and retry
      shouldFail = false;
      await tester.tap(find.text('Retry'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('No Pending Interventions'), findsOneWidget);
    });
  });
}
