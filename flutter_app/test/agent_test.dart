import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tess/core/network/api_client.dart';
import 'package:tess/features/agent/models/action_confirmation_model.dart';
import 'package:tess/features/agent/models/agent_execution_result_model.dart';
import 'package:tess/features/agent/models/agent_objective_model.dart';
import 'package:tess/features/agent/models/agent_plan_model.dart';
import 'package:tess/features/agent/models/agent_step_model.dart';
import 'package:tess/features/agent/screens/agent_screen.dart';
import 'package:tess/features/agent/services/agent_service.dart';
import 'package:tess/features/agent/widgets/objective_composer.dart';
import 'package:tess/features/agent/widgets/step_review_card.dart';
import 'test_helpers.dart';

void main() {
  group('Phase 14.8: Agent Models & JSON Parsing', () {
    test('AgentObjectiveModel validates prompts and provides suggestions', () {
      const emptyModel = AgentObjectiveModel(objective: '');
      expect(emptyModel.isValid, false);
      expect(emptyModel.validationError, isNotNull);

      const validModel = AgentObjectiveModel(objective: 'Update my OpenProject worklog');
      expect(validModel.isValid, true);
      expect(validModel.validationError, isNull);
      expect(AgentObjectiveModel.suggestions.isNotEmpty, true);
    });

    test('ActionConfirmationModel parses fingerprint, status and expiry', () {
      final json = {
        'id': 'conf_123',
        'status': 'PENDING',
        'summary': 'Update OpenProject worklog with 2 hours on task 1. [fp:a1b2c3d4e5f60718]',
        'expires_at': DateTime.now().toUtc().add(const Duration(minutes: 15)).toIso8601String(),
      };

      final conf = ActionConfirmationModel.fromJson(json);
      expect(conf.id, 'conf_123');
      expect(conf.isPending, true);
      expect(conf.isConfirmed, false);
      expect(conf.isExpired, false);
      expect(conf.fingerprint, 'a1b2c3d4e5f60718');
      expect(conf.displaySummary, 'Update OpenProject worklog with 2 hours on task 1.');

      final expiredJson = {
        'id': 'conf_exp',
        'status': 'PENDING',
        'summary': 'Expired action',
        'expires_at': DateTime.now().toUtc().subtract(const Duration(minutes: 5)).toIso8601String(),
      };
      final expiredConf = ActionConfirmationModel.fromJson(expiredJson);
      expect(expiredConf.isExpired, true);
      expect(expiredConf.isPending, false);
    });

    test('AgentStepModel parses risk level, safe parameters and target resource', () {
      final json = {
        'id': 'step_1',
        'plan_id': 'plan_99',
        'step_order': 1,
        'tool_name': 'openproject_update_worklog',
        'action_type': 'UPDATE_WORKLOG',
        'parameters': {
          'task_id': '402',
          'hours': 2.5,
          'secret_token': 'SUPER_SECRET_LEAK_TEST',
          'comment': 'Logged via TESS',
        },
        'risk_level': 'MEDIUM',
        'status': 'PENDING',
        'confirmation': {
          'id': 'conf_1',
          'status': 'PENDING',
          'summary': 'Worklog update [fp:1122334455667788]',
        },
      };

      final step = AgentStepModel.fromJson(json);
      expect(step.id, 'step_1');
      expect(step.stepOrder, 1);
      expect(step.requiresConfirmation, true);
      expect(step.isConfirmed, false);
      expect(step.isPendingConfirmation, true);
      expect(step.targetResource, 'Task #402');
      expect(step.actionDisplayName, 'UPDATE WORKLOG');

      // Epistemic safety: sensitive keys must not be exposed in safeParameters
      final safe = step.safeParameters;
      expect(safe.containsKey('task_id'), true);
      expect(safe.containsKey('hours'), true);
      expect(safe.containsKey('secret_token'), false);
    });

    test('AgentPlanModel calculates execution readiness and pending confirmations', () {
      final json = {
        'id': 'plan_001',
        'user_id': 'usr_1',
        'objective': 'Update worklog and review documents',
        'status': 'READY',
        'created_at': '2026-11-17T12:00:00Z',
        'steps': [
          {
            'id': 's1',
            'plan_id': 'plan_001',
            'step_order': 1,
            'tool_name': 'file_read',
            'action_type': 'FILE_READ',
            'parameters': {'file_path': 'report.txt'},
            'risk_level': 'LOW',
            'status': 'PENDING',
          },
          {
            'id': 's2',
            'plan_id': 'plan_001',
            'step_order': 2,
            'tool_name': 'openproject_update_worklog',
            'action_type': 'UPDATE_WORKLOG',
            'parameters': {'task_id': '10', 'hours': 1.0},
            'risk_level': 'MEDIUM',
            'status': 'PENDING',
            'confirmation': {
              'id': 'c2',
              'status': 'PENDING',
              'summary': 'Update task 10',
            },
          },
        ],
      };

      final plan = AgentPlanModel.fromJson(json);
      expect(plan.id, 'plan_001');
      expect(plan.totalSteps, 2);
      expect(plan.hasPendingConfirmation, true);
      expect(plan.pendingConfirmationCount, 1);
      // Not executable until high/medium risk steps are confirmed
      expect(plan.isExecutable, false);

      // Now simulate confirmed step
      final confirmedJson = Map<String, dynamic>.from(json);
      (confirmedJson['steps'] as List)[1]['confirmation']['status'] = 'CONFIRMED';
      final confirmedPlan = AgentPlanModel.fromJson(confirmedJson);
      expect(confirmedPlan.hasPendingConfirmation, false);
      expect(confirmedPlan.allConfirmedOrLowRisk, true);
      expect(confirmedPlan.isExecutable, true);
    });

    test('AgentExecutionResultModel parses success and failure', () {
      final successResult = AgentExecutionResultModel.fromJson({
        'status': 'success',
        'results': [{'task_id': '1', 'logged': true}],
      });
      expect(successResult.isSuccess, true);
      expect(successResult.results.length, 1);

      final failResult = AgentExecutionResultModel.failure('PermissionError: Step requires confirmation');
      expect(failResult.isSuccess, false);
      expect(failResult.error, contains('requires confirmation'));
    });
  });

  group('Phase 14.8: AgentService Mocked Unit Tests', () {
    test('createObjective, getPlans, and getPlan execute proper endpoints', () async {
      final fakeAuth = FakeAuthService(initialAuthenticated: true);

      final mockHttp = MockClient((request) async {
        if (request.url.path == '/api/v1/agent/objectives' && request.method == 'POST') {
          final body = jsonDecode(request.body);
          return http.Response(
            jsonEncode({
              'id': 'p1',
              'user_id': 'u1',
              'objective': body['objective'],
              'status': 'READY',
              'steps': [],
            }),
            200,
          );
        } else if (request.url.path == '/api/v1/agent/plans' && request.method == 'GET') {
          return http.Response(
            jsonEncode([
              {
                'id': 'p1',
                'user_id': 'u1',
                'objective': 'Test plan',
                'status': 'READY',
                'steps': [],
              }
            ]),
            200,
          );
        } else if (request.url.path == '/api/v1/agent/plans/p1' && request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'id': 'p1',
              'user_id': 'u1',
              'objective': 'Test plan detail',
              'status': 'READY',
              'steps': [],
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final service = AgentService(
        apiClient: ApiClient(authService: fakeAuth, httpClient: mockHttp),
        authService: fakeAuth,
      );

      final created = await service.createObjective('Update my OpenProject worklog');
      expect(created.id, 'p1');
      expect(created.status, 'READY');

      final plans = await service.getPlans();
      expect(plans.length, 1);

      final single = await service.getPlan('p1');
      expect(single.objective, 'Test plan detail');
    });

    test('confirmPlan, cancelPlan, and executePlan execute expected HTTP calls', () async {
      final fakeAuth = FakeAuthService(initialAuthenticated: true);
      bool confirmCalled = false;
      bool cancelCalled = false;
      bool executeCalled = false;

      final mockHttp = MockClient((request) async {
        if (request.url.path == '/api/v1/agent/plans/p1/confirm' && request.method == 'POST') {
          confirmCalled = true;
          return http.Response(jsonEncode({'status': 'success', 'confirmed_count': 1}), 200);
        }
        if (request.url.path == '/api/v1/agent/plans/p1/cancel' && request.method == 'POST') {
          cancelCalled = true;
          return http.Response(jsonEncode({'status': 'cancelled', 'cancelled_count': 1}), 200);
        }
        if (request.url.path == '/api/v1/agent/plans/p1/execute' && request.method == 'POST') {
          executeCalled = true;
          return http.Response(jsonEncode({'status': 'success', 'results': [{'ok': true}]}), 200);
        }
        return http.Response('Not Found', 404);
      });

      final service = AgentService(
        apiClient: ApiClient(authService: fakeAuth, httpClient: mockHttp),
        authService: fakeAuth,
      );

      final confRes = await service.confirmPlan('p1');
      expect(confirmCalled, true);
      expect(confRes['confirmed_count'], 1);

      final cancelRes = await service.cancelPlan('p1');
      expect(cancelCalled, true);
      expect(cancelRes['status'], 'cancelled');

      final execRes = await service.executePlan('p1');
      expect(executeCalled, true);
      expect(execRes.isSuccess, true);
    });

    test('AgentService handles 401 Unauthorized by throwing ApiException', () async {
      final fakeAuth = FakeAuthService(initialAuthenticated: false);
      final mockHttp = MockClient((request) async {
        return http.Response('{"detail": "Unauthorized session token"}', 401);
      });

      final service = AgentService(
        apiClient: ApiClient(authService: fakeAuth, httpClient: mockHttp),
        authService: fakeAuth,
      );

      expect(() => service.getPlans(), throwsA(isA<ApiException>()));
    });
  });

  group('Phase 14.8: AgentScreen UI & Interaction Tests', () {
    testWidgets('Renders objective composer, submits prompt, and displays generated steps', (tester) async {
      final fakeAuth = FakeAuthService(initialAuthenticated: true);

      final mockHttp = MockClient((request) async {
        if (request.url.path == '/api/v1/agent/plans' && request.method == 'GET') {
          return http.Response(jsonEncode([]), 200);
        }
        if (request.url.path == '/api/v1/agent/objectives' && request.method == 'POST') {
          return http.Response(
            jsonEncode({
              'id': 'plan_demo',
              'user_id': 'u1',
              'objective': 'Update my OpenProject worklog: 2 hours on task 1',
              'status': 'READY',
              'steps': [
                {
                  'id': 'st_1',
                  'plan_id': 'plan_demo',
                  'step_order': 1,
                  'tool_name': 'openproject_update_worklog',
                  'action_type': 'UPDATE_WORKLOG',
                  'parameters': {'task_id': '1', 'hours': 2.0},
                  'risk_level': 'MEDIUM',
                  'status': 'PENDING',
                  'confirmation': {
                    'id': 'cf_1',
                    'status': 'PENDING',
                    'summary': 'Update OpenProject worklog with 2.0 hours on task 1 [fp:abcdef1234567890]',
                  },
                }
              ],
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final service = AgentService(
        apiClient: ApiClient(authService: fakeAuth, httpClient: mockHttp),
        authService: fakeAuth,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AgentScreen(
            agentService: service,
            initialObjective: 'Update my OpenProject worklog: 2 hours on task 1',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('AGENT OBJECTIVE COMPOSER'), findsOneWidget);
      expect(find.byType(ObjectiveComposer), findsOneWidget);

      // Tap generate action plan
      await tester.tap(find.text('Generate Action Plan'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify generated plan and step appear
      expect(find.text('Update my OpenProject worklog: 2 hours on task 1'), findsAtLeastNWidgets(2));
      expect(find.byType(StepReviewCard), findsOneWidget);
      expect(find.text('UPDATE WORKLOG'), findsOneWidget);
      expect(find.text('MEDIUM RISK'), findsOneWidget);
      expect(find.text('AUTHORIZATION REQUIRED'), findsOneWidget);
      expect(find.text('Approve & Confirm'), findsOneWidget);
    });

    testWidgets('Approval workflow, confirmation execution, and cancel plan handling', (tester) async {
      final fakeAuth = FakeAuthService(initialAuthenticated: true);
      bool wasConfirmed = false;

      final testPlanData = {
        'id': 'plan_conf_test',
        'user_id': 'u1',
        'objective': 'Update worklog',
        'status': 'READY',
        'steps': [
          {
            'id': 's1',
            'plan_id': 'plan_conf_test',
            'step_order': 1,
            'tool_name': 'openproject_update_worklog',
            'action_type': 'UPDATE_WORKLOG',
            'parameters': {'task_id': '1', 'hours': 2.0},
            'risk_level': 'MEDIUM',
            'status': 'PENDING',
            'confirmation': {
              'id': 'cf_1',
              'status': 'PENDING',
              'summary': 'Worklog confirmation [fp:11223344]',
            },
          }
        ],
      };

      final mockHttp = MockClient((request) async {
        if (request.url.path == '/api/v1/agent/plans' && request.method == 'GET') {
          return http.Response(jsonEncode([testPlanData]), 200);
        }
        if (request.url.path == '/api/v1/agent/plans/plan_conf_test/confirm' && request.method == 'POST') {
          wasConfirmed = true;
          return http.Response(jsonEncode({'status': 'success', 'confirmed_count': 1}), 200);
        }
        if (request.url.path == '/api/v1/agent/plans/plan_conf_test' && request.method == 'GET') {
          final copy = Map<String, dynamic>.from(testPlanData);
          if (wasConfirmed) {
            (copy['steps'] as List)[0]['confirmation']['status'] = 'CONFIRMED';
          }
          return http.Response(jsonEncode(copy), 200);
        }
        return http.Response('Not Found', 404);
      });

      final service = AgentService(
        apiClient: ApiClient(authService: fakeAuth, httpClient: mockHttp),
        authService: fakeAuth,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AgentScreen(agentService: service),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Approve & Confirm'), findsOneWidget);

      // Scroll to button and tap to open confirmation bottom sheet
      await tester.ensureVisible(find.text('Approve & Confirm'));
      await tester.tap(find.text('Approve & Confirm'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Check confirmation sheet contents
      expect(find.text('SECURITY AUTHORIZATION REQUIRED'), findsOneWidget);
      expect(find.text('Approve Actions'), findsOneWidget);

      // Confirm
      await tester.tap(find.text('Approve Actions'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(wasConfirmed, true);
      // Execution button should now be available
      expect(find.text('Execute Approved Plan'), findsOneWidget);
    });

    testWidgets('Execute approved plan calls backend and displays success notification', (tester) async {
      final fakeAuth = FakeAuthService(initialAuthenticated: true);
      bool wasExecuted = false;

      final testPlanData = {
        'id': 'plan_exec_test',
        'user_id': 'u1',
        'objective': 'Prepare meeting briefing',
        'status': 'READY',
        'steps': [
          {
            'id': 's1',
            'plan_id': 'plan_exec_test',
            'step_order': 1,
            'tool_name': 'calendar_list_events',
            'action_type': 'CALENDAR_LIST',
            'parameters': {'days_ahead': 2},
            'risk_level': 'LOW',
            'status': 'PENDING',
          }
        ],
      };

      final mockHttp = MockClient((request) async {
        if (request.url.path == '/api/v1/agent/plans' && request.method == 'GET') {
          return http.Response(jsonEncode([testPlanData]), 200);
        }
        if (request.url.path == '/api/v1/agent/plans/plan_exec_test/execute' && request.method == 'POST') {
          wasExecuted = true;
          return http.Response(
            jsonEncode({
              'status': 'success',
              'results': [{'events_count': 3}],
            }),
            200,
          );
        }
        if (request.url.path == '/api/v1/agent/plans/plan_exec_test' && request.method == 'GET') {
          final copy = Map<String, dynamic>.from(testPlanData);
          if (wasExecuted) {
            copy['status'] = 'SUCCESS';
            (copy['steps'] as List)[0]['status'] = 'SUCCESS';
            (copy['steps'] as List)[0]['result'] = {'events_count': 3};
          }
          return http.Response(jsonEncode(copy), 200);
        }
        return http.Response('Not Found', 404);
      });

      final service = AgentService(
        apiClient: ApiClient(authService: fakeAuth, httpClient: mockHttp),
        authService: fakeAuth,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AgentScreen(agentService: service),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Execute Approved Plan'), findsOneWidget);

      await tester.ensureVisible(find.text('Execute Approved Plan'));
      await tester.tap(find.text('Execute Approved Plan'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(wasExecuted, true);
      expect(find.text('Plan completed successfully. Replay protection active: Tokens invalidated.'), findsOneWidget);
    });

    testWidgets('Cancel plan cancels pending authorizations and updates status', (tester) async {
      final fakeAuth = FakeAuthService(initialAuthenticated: true);
      bool wasCancelled = false;

      final testPlanData = {
        'id': 'plan_cancel_test',
        'user_id': 'u1',
        'objective': 'Browse github repo',
        'status': 'READY',
        'steps': [
          {
            'id': 's1',
            'plan_id': 'plan_cancel_test',
            'step_order': 1,
            'tool_name': 'browser_navigate',
            'action_type': 'BROWSER_NAVIGATE',
            'parameters': {'url': 'https://github.com'},
            'risk_level': 'LOW',
            'status': 'PENDING',
          }
        ],
      };

      final mockHttp = MockClient((request) async {
        if (request.url.path == '/api/v1/agent/plans' && request.method == 'GET') {
          return http.Response(jsonEncode([testPlanData]), 200);
        }
        if (request.url.path == '/api/v1/agent/plans/plan_cancel_test/cancel' && request.method == 'POST') {
          wasCancelled = true;
          return http.Response(jsonEncode({'status': 'cancelled', 'cancelled_count': 0}), 200);
        }
        if (request.url.path == '/api/v1/agent/plans/plan_cancel_test' && request.method == 'GET') {
          final copy = Map<String, dynamic>.from(testPlanData);
          if (wasCancelled) {
            copy['status'] = 'CANCELLED';
          }
          return http.Response(jsonEncode(copy), 200);
        }
        return http.Response('Not Found', 404);
      });

      final service = AgentService(
        apiClient: ApiClient(authService: fakeAuth, httpClient: mockHttp),
        authService: fakeAuth,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AgentScreen(agentService: service),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Cancel Plan'), findsOneWidget);

      await tester.ensureVisible(find.text('Cancel Plan'));
      await tester.tap(find.text('Cancel Plan'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(wasCancelled, true);
      expect(find.text('Plan was cancelled by user. No further actions permitted.'), findsOneWidget);
    });

    testWidgets('Displays error banner and allows retry when API encounters network failure', (tester) async {
      final fakeAuth = FakeAuthService(initialAuthenticated: true);

      final mockHttp = MockClient((request) async {
        return http.Response('{"detail": "Agent backend service offline"}', 503);
      });

      final service = AgentService(
        apiClient: ApiClient(authService: fakeAuth, httpClient: mockHttp),
        authService: fakeAuth,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AgentScreen(agentService: service),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Agent backend service offline'), findsOneWidget);
    });
  });
}
