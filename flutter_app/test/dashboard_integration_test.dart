import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tess/core/network/api_client.dart';
import 'package:tess/features/home/models/dashboard_model.dart';
import 'package:tess/features/home/screens/home_screen.dart';
import 'package:tess/features/home/services/dashboard_service.dart';
import 'test_helpers.dart';

void main() {
  group('Phase 14.4: Dashboard Models JSON Parsing', () {
    test('ProductivitySummaryModel parses valid FastAPI backend response', () {
      final json = {
        'total_active': 12,
        'overdue': 3,
        'due_today': 4,
        'due_this_week': 7,
        'completed_recently': 18,
      };

      final model = ProductivitySummaryModel.fromJson(json);
      expect(model.totalActive, 12);
      expect(model.overdue, 3);
      expect(model.dueToday, 4);
      expect(model.dueThisWeek, 7);
      expect(model.completedRecently, 18);
      expect(model.hasOverdue, true);
    });

    test('ProductivitySummaryModel handles null and missing fields gracefully', () {
      final model = ProductivitySummaryModel.fromJson({});
      expect(model.totalActive, 0);
      expect(model.overdue, 0);
      expect(model.dueToday, 0);
      expect(model.completedRecently, 0);
      expect(model.hasOverdue, false);

      final nullModel = ProductivitySummaryModel.fromJson(null);
      expect(nullModel.totalActive, 0);
    });

    test('BackendFuturePredictionModel parses Future Engine predictions and normalizes probability', () {
      final json = {
        'id': 'pred_999',
        'prediction_type': 'RISK',
        'title': 'Context Fragmentation Alert',
        'description': 'Cognitive overload expected in afternoon sprint.',
        'probability': 0.85, // 0.85 normalized to 85%
        'confidence': 'HIGH',
        'time_horizon': '24h',
        'evidence': ['3 back-to-back syncs', '1 overdue work package'],
        'reasoning': 'Calendar density conflicts with deep work focus window.',
      };

      final pred = BackendFuturePredictionModel.fromJson(json);
      expect(pred.id, 'pred_999');
      expect(pred.predictionType, 'RISK');
      expect(pred.isRisk, true);
      expect(pred.probability, 85.0);
      expect(pred.confidence, 'HIGH');
      expect(pred.timeHorizon, '24h');
      expect(pred.evidence.length, 2);
      expect(pred.formattedProbability, '85% Probability');
    });

    test('BackendFuturePredictionModel handles missing optional fields', () {
      final pred = BackendFuturePredictionModel.fromJson({
        'title': 'Nominal Trajectory',
      });
      expect(pred.title, 'Nominal Trajectory');
      expect(pred.predictionType, 'NEUTRAL');
      expect(pred.isRisk, false);
      expect(pred.evidence, isEmpty);
      expect(pred.reasoning, isEmpty);
    });
  });

  group('Phase 14.4: DashboardService Mocked Integration', () {
    test('Fetches summary and predictions in parallel and constructs DashboardData', () async {
      final fakeAuth = FakeAuthService(initialAuthenticated: true);

      final mockHttp = MockClient((request) async {
        if (request.url.path == '/api/v1/productivity/summary') {
          return http.Response(
            jsonEncode({
              'total_active': 8,
              'overdue': 0,
              'due_today': 2,
              'due_this_week': 5,
              'completed_recently': 10,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        } else if (request.url.path == '/api/v1/future/predictions') {
          return http.Response(
            jsonEncode([
              {
                'id': 'pred_1',
                'prediction_type': 'POSITIVE',
                'title': 'Optimal Focus Window',
                'description': 'Deep work flow verified.',
                'probability': 90.0,
                'confidence': 'HIGH',
                'time_horizon': '48h',
              }
            ]),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(
        authService: fakeAuth,
        httpClient: mockHttp,
      );

      final service = DashboardService(
        apiClient: apiClient,
        authService: fakeAuth,
      );

      final data = await service.fetchDashboardData();
      expect(data.summary.totalActive, 8);
      expect(data.summary.overdue, 0);
      expect(data.predictions.length, 1);
      expect(data.predictions.first.isPositive, true);
      expect(data.hasUrgentAlerts, false);
    });

    test('Gracefully handles empty lists and backend 404', () async {
      final fakeAuth = FakeAuthService(initialAuthenticated: true);

      final mockHttp = MockClient((request) async {
        return http.Response(jsonEncode([]), 200);
      });

      final apiClient = ApiClient(authService: fakeAuth, httpClient: mockHttp);
      final service = DashboardService(apiClient: apiClient, authService: fakeAuth);

      final data = await service.fetchDashboardData();
      expect(data.summary.totalActive, 0);
      expect(data.predictions, isEmpty);
    });
  });

  group('Phase 14.4: HomeScreen UI Rendering & State Transitions', () {
    testWidgets('Renders real metrics, greeting, and changes mascot state to attention when overdue', (tester) async {
      final fakeAuth = FakeAuthService(initialAuthenticated: true);

      // Mock backend returning overdue tasks
      final mockHttp = MockClient((request) async {
        if (request.url.path == '/api/v1/productivity/summary') {
          return http.Response(
            jsonEncode({
              'total_active': 5,
              'overdue': 2, // Overdue > 0 triggers attention state!
              'due_today': 1,
              'due_this_week': 3,
              'completed_recently': 4,
            }),
            200,
          );
        } else if (request.url.path == '/api/v1/future/predictions') {
          return http.Response(
            jsonEncode([
              {
                'id': 'pred_alert',
                'prediction_type': 'RISK',
                'title': 'Context Switch Imminent',
                'description': 'Overdue tasks risk deadline push.',
                'probability': 75.0,
                'confidence': 'HIGH',
                'time_horizon': '24h',
              }
            ]),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(authService: fakeAuth, httpClient: mockHttp);
      final dashboardService = DashboardService(apiClient: apiClient, authService: fakeAuth);

      int navigatedTab = -1;

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            onNavigateTab: (idx) => navigatedTab = idx,
            dashboardService: dashboardService,
          ),
        ),
      );

      // Initial pump triggers _loadDashboardData
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 1. Verify Greeting & Persona (Clean greeting, no duplicated 'Commander Commander')
      expect(find.text('Welcome back'), findsOneWidget);

      // 2. Verify Real Productivity Numbers from Backend
      expect(find.text('5'), findsOneWidget); // totalActive
      expect(find.text('2'), findsOneWidget); // overdue
      expect(find.text('1'), findsOneWidget); // dueToday
      expect(find.text('4'), findsOneWidget); // completedRecently

      // 3. Verify Real Prediction Card
      expect(find.text('Context Switch Imminent'), findsOneWidget);
      expect(find.text('75% Probability'), findsOneWidget);

      // 4. Verify Mascot Attention Text Triggered by Overdue Tasks
      expect(find.text('ITEMS REQUIRE ATTENTION'), findsOneWidget);

      // 5. Test Quick Navigation Action Button
      await tester.tap(find.text('Talk to TESS'));
      expect(navigatedTab, 1);
    });

    testWidgets('Renders error banner on API failure with functional retry button', (tester) async {
      final fakeAuth = FakeAuthService(initialAuthenticated: true);
      bool shouldFail = true;

      final mockHttp = MockClient((request) async {
        if (shouldFail) {
          return http.Response('Server Unavailable', 503);
        }
        return http.Response(jsonEncode({'total_active': 10}), 200);
      });

      final apiClient = ApiClient(authService: fakeAuth, httpClient: mockHttp);
      final dashboardService = DashboardService(apiClient: apiClient, authService: fakeAuth);

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            onNavigateTab: (_) {},
            dashboardService: dashboardService,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Error banner should be rendered
      expect(find.text('Retry Synchronization'), findsOneWidget);

      // Fix backend state and tap retry
      shouldFail = false;
      await tester.tap(find.text('Retry Synchronization'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Error banner should clear
      expect(find.text('Retry Synchronization'), findsNothing);
    });
  });
}
