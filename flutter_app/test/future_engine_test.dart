import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tess/core/network/api_client.dart';
import 'package:tess/features/futures/models/accuracy_model.dart';
import 'package:tess/features/futures/models/behavioral_model.dart';
import 'package:tess/features/futures/models/forecast_model.dart';
import 'package:tess/features/futures/models/future_prediction_model.dart';
import 'package:tess/features/futures/models/multiple_futures_model.dart';
import 'package:tess/features/futures/screens/futures_screen.dart';
import 'package:tess/features/futures/services/future_service.dart';
import 'test_helpers.dart';

void main() {
  group('Phase 14.6: Future Engine Models & JSON Parsing', () {
    test('FuturePredictionModel parses RISK and normalizes raw 0.85 probability to 85%', () {
      final json = {
        'id': 'pred_101',
        'user_id': 'usr_1',
        'prediction_type': 'RISK',
        'title': 'Context Switch Imminent',
        'description': 'Overdue work packages conflict with focus blocks.',
        'probability': 0.85,
        'confidence': 'HIGH',
        'time_horizon': '24h',
        'evidence': ['2 overdue tickets', '3 meetings'],
        'reasoning': 'High cognitive load during afternoon sprint.',
        'status': 'ACTIVE',
      };

      final model = FuturePredictionModel.fromJson(json);
      expect(model.id, 'pred_101');
      expect(model.isRisk, true);
      expect(model.isPositive, false);
      expect(model.probabilityPercentage, 85.0);
      expect(model.formattedProbability, '85% Probability');
      expect(model.confidence, 'HIGH');
      expect(model.timeHorizon, '24h');
      expect(model.evidence.length, 2);
    });

    test('LongTermForecastModel parses backlog, completion and burnout risk score', () {
      final json = {
        'id': 'fc_30',
        'horizon': '30d',
        'projected_backlog': 14,
        'completion_forecast': 28,
        'burnout_risk_score': 0.72, // 72% -> isHighBurnoutRisk = true
        'probability': 0.80,
        'confidence': 'HIGH',
        'uncertainty_range': {'min': 10, 'max': 18},
        'assumptions': ['Stable velocity', 'No scope creep'],
        'explanation': 'Backlog is projected to stabilize if velocity persists.',
      };

      final model = LongTermForecastModel.fromJson(json);
      expect(model.horizon, '30d');
      expect(model.projectedBacklog, 14);
      expect(model.completionForecast, 28);
      expect(model.burnoutRiskPercentage, 72.0);
      expect(model.isHighBurnoutRisk, true);
      expect(model.uncertaintyRange['min'], 10.0);
      expect(model.assumptions.length, 2);
    });

    test('MultipleFuturesModel parses CURRENT, IMPROVED, and ALTERNATIVE scenarios', () {
      final json = {
        'horizon': '30d',
        'current_trajectory': {
          'id': 's_curr',
          'trajectory_type': 'CURRENT',
          'title': 'Status Quo',
          'summary': 'Continuity of current trajectory',
          'probability': 0.65,
          'confidence': 'MEDIUM',
          'events': [
            {
              'id': 'e1',
              'sequence': 1,
              'relative_time': '+7d',
              'title': 'Sprint review',
              'description': 'Velocity check',
              'confidence': 'HIGH',
            }
          ]
        },
        'improved_trajectory': {
          'id': 's_imp',
          'trajectory_type': 'IMPROVED',
          'title': 'Accelerated Delivery',
          'summary': 'Focus blocks adopted',
          'probability': 0.85,
          'confidence': 'HIGH',
          'events': []
        },
        'alternative_trajectory': {
          'id': 's_alt',
          'trajectory_type': 'ALTERNATIVE',
          'title': 'Scope Realignment',
          'summary': 'De-scoped non-critical items',
          'probability': 0.50,
          'confidence': 'LOW',
          'events': []
        }
      };

      final model = MultipleFuturesModel.fromJson(json);
      expect(model.currentTrajectory.trajectoryType, 'CURRENT');
      expect(model.currentTrajectory.events.length, 1);
      expect(model.improvedTrajectory.trajectoryType, 'IMPROVED');
      expect(model.improvedTrajectory.probabilityPercentage, 85.0);
      expect(model.alternativeTrajectory.trajectoryType, 'ALTERNATIVE');
    });

    test('AccuracyMetricsModel calculates sample size sufficiency threshold (N >= 5)', () {
      final insufficientJson = {
        'total_evaluated': 3,
        'overall_accuracy': 0.67,
        'brier_calibration_score': 0.22,
        'recent_evaluations': [],
      };
      final insufficientModel = AccuracyMetricsModel.fromJson(insufficientJson);
      expect(insufficientModel.totalEvaluated, 3);
      expect(insufficientModel.hasSufficientSampleSize, false);

      final sufficientJson = {
        'total_evaluated': 12,
        'overall_accuracy': 0.833,
        'brier_calibration_score': 0.14,
        'recent_evaluations': [
          {
            'id': 'ev_1',
            'prediction_id': 'p1',
            'horizon': '24h',
            'predicted_outcome': 'Task completed on time',
            'actual_outcome': 'Completed 14:00',
            'status': 'CONFIRMED',
          }
        ],
      };
      final sufficientModel = AccuracyMetricsModel.fromJson(sufficientJson);
      expect(sufficientModel.totalEvaluated, 12);
      expect(sufficientModel.hasSufficientSampleSize, true);
      expect(sufficientModel.accuracyPercentage, 83.0);
      expect(sufficientModel.recentEvaluations.first.isConfirmed, true);
    });

    test('BehavioralAnalysisModel parses data quality ratings', () {
      final json = {
        'data_quality': 'GOOD',
        'insights': [
          {
            'category': 'DEEP_WORK',
            'headline': 'Morning Peak Velocity',
            'observation': 'User completes 70% of tasks between 09:00 - 12:00',
            'data_quality': 'GOOD',
            'window_days': 30,
          }
        ]
      };

      final model = BehavioralAnalysisModel.fromJson(json);
      expect(model.isDataSufficient, true);
      expect(model.insights.first.category, 'DEEP_WORK');
    });
  });

  group('Phase 14.6: FutureService Mocked Unit Tests', () {
    test('getPredictions, simulateFuture, and getForecast execute proper HTTP endpoints', () async {
      final fakeAuth = FakeAuthService(initialAuthenticated: true);

      final mockHttp = MockClient((request) async {
        if (request.url.path == '/api/v1/future/predictions') {
          return http.Response(
            jsonEncode([
              {
                'id': 'pred_1',
                'prediction_type': 'POSITIVE',
                'title': 'High Velocity Sprint',
                'probability': 0.90,
                'confidence': 'HIGH',
                'time_horizon': '7d',
              }
            ]),
            200,
          );
        } else if (request.url.path == '/api/v1/future/simulate' && request.method == 'POST') {
          final body = jsonDecode(request.body);
          expect(body['horizon'], '24h');
          return http.Response(
            jsonEncode({
              'scenario': {
                'id': 'scen_1',
                'trajectory_type': 'CURRENT',
                'title': '24h Projection',
                'summary': 'Nominal progression',
                'probability': 0.75,
                'confidence': 'HIGH',
                'events': [],
              },
              'alternative': {
                'id': 'cf_1',
                'action': 'Prioritize backlog ticket #42',
                'assumption': 'Task unblocks teammate',
                'expected_effect': 'Prevents 2h idle wait',
              }
            }),
            200,
          );
        } else if (request.url.path == '/api/v1/future/forecast' && request.method == 'POST') {
          final body = jsonDecode(request.body);
          expect(body['horizon'], '90d');
          return http.Response(
            jsonEncode({
              'id': 'fc_90',
              'horizon': '90d',
              'projected_backlog': 5,
              'completion_forecast': 45,
              'burnout_risk_score': 0.25,
              'probability': 0.85,
              'confidence': 'HIGH',
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final service = FutureService(
        apiClient: ApiClient(authService: fakeAuth, httpClient: mockHttp),
        authService: fakeAuth,
      );

      final preds = await service.getPredictions();
      expect(preds.length, 1);
      expect(preds.first.isPositive, true);

      final sim = await service.simulateFuture('24h');
      expect(sim.scenario.title, '24h Projection');
      expect(sim.alternative?.action, contains('#42'));

      final fc = await service.getForecast('90d');
      expect(fc.horizon, '90d');
      expect(fc.isHighBurnoutRisk, false);
    });

    test('FutureService handles 401 Unauthorized by throwing ApiException', () async {
      final fakeAuth = FakeAuthService(initialAuthenticated: true);
      final mockHttp = MockClient((request) async {
        return http.Response(jsonEncode({'detail': 'Not authenticated'}), 401);
      });

      final service = FutureService(
        apiClient: ApiClient(authService: fakeAuth, httpClient: mockHttp),
        authService: fakeAuth,
      );

      expect(
        () => service.getPredictions(),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('Phase 14.6: FuturesScreen UI & Interaction Tests', () {
    testWidgets('Renders predictions, transitions Mascot to ATTENTION on RISK, and toggles tabs', (tester) async {
      final fakeAuth = FakeAuthService(initialAuthenticated: true);

      final mockHttp = MockClient((request) async {
        if (request.url.path == '/api/v1/future/predictions') {
          return http.Response(
            jsonEncode([
              {
                'id': 'p_risk',
                'prediction_type': 'RISK',
                'title': 'Cognitive Overload Warning',
                'description': '3 back-to-back deadlines detected.',
                'probability': 0.88,
                'confidence': 'HIGH',
                'time_horizon': '24h',
                'evidence': ['Overdue work package', 'Meeting conflict'],
                'reasoning': 'Calendar pressure exceeds focus limit.',
              }
            ]),
            200,
          );
        } else if (request.url.path == '/api/v1/future/forecast') {
          return http.Response(
            jsonEncode({
              'id': 'fc_30',
              'horizon': '30d',
              'projected_backlog': 12,
              'completion_forecast': 24,
              'burnout_risk_score': 0.70,
              'probability': 0.80,
              'confidence': 'HIGH',
              'explanation': 'Forecast indicates steady completion rate.',
            }),
            200,
          );
        } else if (request.url.path == '/api/v1/future/accuracy') {
          return http.Response(
            jsonEncode({
              'total_evaluated': 2, // Sample size < 5 triggers honesty disclaimer
              'overall_accuracy': 0.50,
              'brier_calibration_score': 0.25,
              'recent_evaluations': [],
            }),
            200,
          );
        }
        return http.Response(jsonEncode({}), 200);
      });

      final futureService = FutureService(
        apiClient: ApiClient(authService: fakeAuth, httpClient: mockHttp),
        authService: fakeAuth,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: FuturesScreen(futureService: futureService),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 1. Verify Header & Mascot ATTENTION State (due to RISK prediction)
      expect(find.text('FUTURE SIMULATION ENGINE'), findsOneWidget);
      expect(find.text('CRITICAL CONVERGENCE RISKS DETECTED'), findsOneWidget);

      // 2. Verify Trajectory Card & Probability
      expect(find.text('Cognitive Overload Warning'), findsOneWidget);
      expect(find.text('88% Probability'), findsOneWidget);

      // 3. Switch to FORECAST Tab
      await tester.tap(find.text('FORECAST'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('PROJECTED BACKLOG'), findsOneWidget);
      expect(find.text('12 items'), findsOneWidget);
      expect(find.text('70%'), findsOneWidget); // Burnout risk

      // 4. Switch to ACCURACY Tab and verify Honest Sample Size Disclaimer
      await tester.tap(find.text('ACCURACY'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('BRIER SCORE'), findsOneWidget);
      expect(find.textContaining('Calibration Sample Size Note'), findsOneWidget);
    });

    testWidgets('Renders empty state when no predictions are active', (tester) async {
      final fakeAuth = FakeAuthService(initialAuthenticated: true);

      final mockHttp = MockClient((request) async {
        return http.Response(jsonEncode([]), 200);
      });

      final futureService = FutureService(
        apiClient: ApiClient(authService: fakeAuth, httpClient: mockHttp),
        authService: fakeAuth,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: FuturesScreen(futureService: futureService),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Trajectories Nominal'), findsOneWidget);
      expect(find.text('TRAJECTORIES SYNCHRONIZED // NOMINAL'), findsOneWidget);
    });

    testWidgets('Displays error banner and retry button on API failure', (tester) async {
      final fakeAuth = FakeAuthService(initialAuthenticated: true);
      bool shouldFail = true;

      final mockHttp = MockClient((request) async {
        if (shouldFail) {
          return http.Response(jsonEncode({'detail': 'Sensor node offline'}), 503);
        }
        return http.Response(jsonEncode([]), 200);
      });

      final futureService = FutureService(
        apiClient: ApiClient(authService: fakeAuth, httpClient: mockHttp),
        authService: fakeAuth,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: FuturesScreen(futureService: futureService),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('SIMULATION SENSOR ERROR'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // Fix backend state and tap retry
      shouldFail = false;
      await tester.tap(find.text('Retry'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Trajectories Nominal'), findsOneWidget);
    });
  });
}
