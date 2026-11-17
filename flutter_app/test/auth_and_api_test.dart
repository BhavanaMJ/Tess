import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tess/core/network/api_client.dart';
import 'package:tess/features/auth/screens/login_screen.dart';
import 'package:tess/features/auth/screens/signup_screen.dart';
import 'test_helpers.dart';

void main() {
  group('Module 4 & 7: ApiClient Mocked Unit Tests', () {
    test('Constructs GET request with Bearer authorization header from AuthService', () async {
      final fakeAuth = FakeAuthService(initialAuthenticated: true);
      String? capturedAuthHeader;

      final mockHttp = MockClient((request) async {
        capturedAuthHeader = request.headers['Authorization'];
        expect(request.url.path, '/api/v1/devices');
        return http.Response(jsonEncode([{'device_id': 'dev_1'}]), 200, headers: {
          'content-type': 'application/json',
        });
      });

      final client = ApiClient(
        authService: fakeAuth,
        httpClient: mockHttp,
      );

      final data = await client.get('/api/v1/devices');
      expect(capturedAuthHeader, 'Bearer mock_jwt_access_token_xyz123');
      expect(data, isList);
      expect((data as List).length, 1);
    });

    test('Omits Authorization header when requiresAuth is false', () async {
      final fakeAuth = FakeAuthService(initialAuthenticated: true);
      String? capturedAuthHeader;

      final mockHttp = MockClient((request) async {
        capturedAuthHeader = request.headers['Authorization'];
        return http.Response(jsonEncode({'status': 'ok'}), 200);
      });

      final client = ApiClient(
        authService: fakeAuth,
        httpClient: mockHttp,
      );

      final isHealthy = await client.checkHealth();
      expect(isHealthy, true);
      expect(capturedAuthHeader, isNull);
    });

    test('Handles 401 Unauthorized by throwing informative ApiException', () async {
      final fakeAuth = FakeAuthService(initialAuthenticated: true);

      final mockHttp = MockClient((request) async {
        return http.Response(
          jsonEncode({'detail': 'Could not validate credentials'}),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = ApiClient(
        authService: fakeAuth,
        httpClient: mockHttp,
      );

      expect(
        client.get('/api/v1/conversations'),
        throwsA(predicate((e) =>
            e is ApiException &&
            e.statusCode == 401 &&
            e.message.contains('Unauthorized'))),
      );
    });

    test('Parses 500 Internal Server Error detail message', () async {
      final fakeAuth = FakeAuthService();

      final mockHttp = MockClient((request) async {
        return http.Response(
          jsonEncode({'detail': 'Database connection pool exhausted'}),
          500,
        );
      });

      final client = ApiClient(
        authService: fakeAuth,
        httpClient: mockHttp,
      );

      expect(
        client.get('/api/v1/future'),
        throwsA(predicate((e) =>
            e is ApiException &&
            e.statusCode == 500 &&
            e.message.contains('Database connection pool exhausted'))),
      );
    });
  });

  group('Module 2 & 6: Login & Signup Screen UI Tests', () {
    testWidgets('LoginScreen validates empty and malformed email', (tester) async {
      final fakeAuth = FakeAuthService();

      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(authService: fakeAuth),
        ),
      );

      // Verify login UI elements
      expect(find.text('TESS OS // ACCESS'), findsOneWidget);
      expect(find.text('Initialize Connection'), findsOneWidget);

      // Submit empty form
      await tester.tap(find.text('Initialize Connection'));
      await tester.pump();

      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);

      // Enter invalid email
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.first, 'notanemail');
      await tester.enterText(textFields.last, 'secret123');
      await tester.tap(find.text('Initialize Connection'));
      await tester.pump();

      expect(find.text('Enter a valid email address'), findsOneWidget);
    });

    testWidgets('LoginScreen displays error message banner when credentials fail', (tester) async {
      final fakeAuth = FakeAuthService()..throwOnSignIn = true;

      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(authService: fakeAuth),
        ),
      );

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.first, 'commander@tess.ai');
      await tester.enterText(textFields.last, 'wrongpassword');
      await tester.tap(find.text('Initialize Connection'));
      await tester.pump();

      expect(find.text('Invalid email or password. Please verify credentials.'), findsOneWidget);
    });

    testWidgets('SignupScreen validates minimum password length and matching passwords', (tester) async {
      final fakeAuth = FakeAuthService();

      await tester.pumpWidget(
        MaterialApp(
          home: SignupScreen(authService: fakeAuth),
        ),
      );

      expect(find.text('REGISTER PERSONA'), findsOneWidget);

      final textFields = find.byType(TextFormField);
      // textFields: 0: Callsign, 1: Email, 2: Password, 3: ConfirmPassword
      await tester.enterText(textFields.at(1), 'neo@tess.ai');
      await tester.enterText(textFields.at(2), '123'); // < 6 chars
      await tester.enterText(textFields.at(3), '123456');

      await tester.tap(find.text('Establish Identity'));
      await tester.pump();

      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('Toggles password visibility when eye icon is clicked', (tester) async {
      final fakeAuth = FakeAuthService();

      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(authService: fakeAuth),
        ),
      );

      // Initial state is obscured, showing visibility_off icon
      final toggleFinder = find.byIcon(Icons.visibility_off);
      expect(toggleFinder, findsOneWidget);

      // Tap toggle to reveal password
      await tester.tap(toggleFinder);
      await tester.pump();

      // Now unobscured, showing visibility icon
      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });
  });
}
