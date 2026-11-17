import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tess/app/app.dart';
import 'test_helpers.dart';

void main() {
  testWidgets('TESS Flutter App shell smoke test & navigation', (WidgetTester tester) async {
    final fakeAuth = FakeAuthService(initialAuthenticated: true);

    // Build the TESS app with authenticated session and trigger a frame.
    await tester.pumpWidget(TessApp(authService: fakeAuth));

    // Verify that the AppBar branding title 'TESS' is present.
    expect(find.text('TESS'), findsOneWidget);
    expect(find.text('FLUTTER OS'), findsOneWidget);

    // Verify that navigation tab bar exists and contains primary destinations
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('Futures'), findsWidgets);
    expect(find.text('Tasks'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    // Tap on the Chat tab
    await tester.tap(find.text('Chat'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('TESS COGNITIVE CHAT'), findsOneWidget);

    // Tap on the Tasks tab
    await tester.tap(find.text('Tasks'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('AGENT TASK MATRIX'), findsOneWidget);

    // Drain pending asynchronous timer from FuturesScreen simulation
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('Module 7: Task Creation Form & Navigation Flow', (WidgetTester tester) async {
    final fakeAuth = FakeAuthService(initialAuthenticated: true);
    await tester.pumpWidget(TessApp(authService: fakeAuth));

    // Navigate to Tasks screen
    await tester.tap(find.text('Tasks'));
    await tester.pump(const Duration(milliseconds: 300));

    // Tap Floating Action Button to open CreateTaskScreen
    final fabFinder = find.byType(FloatingActionButton);
    expect(fabFinder, findsOneWidget);
    await tester.tap(fabFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify CreateTaskScreen is presented
    expect(find.text('DISPATCH NEW OBJECTIVE'), findsOneWidget);
    expect(find.text('OBJECTIVE TITLE'), findsOneWidget);

    // Test form validation: submit empty form
    final submitButton = find.text('Commit Objective to Timeline');
    await tester.tap(submitButton);
    await tester.pump();

    // Expect validation errors
    expect(find.text('Please enter an objective title'), findsOneWidget);

    // Enter valid objective text
    final textFields = find.byType(TextFormField);
    await tester.enterText(textFields.first, 'Construct Neural Memory Pipeline');
    await tester.enterText(textFields.last, 'ARCHITECTURE // COGNITIVE');
    await tester.pump();

    // Submit validated form
    await tester.tap(submitButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify returned to Tasks screen and new objective is rendered
    expect(find.text('AGENT TASK MATRIX'), findsOneWidget);
    expect(find.text('Construct Neural Memory Pipeline'), findsOneWidget);

    // Drain pending asynchronous timers
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('AuthGate displays LoginScreen when unauthenticated', (WidgetTester tester) async {
    final fakeAuth = FakeAuthService(initialAuthenticated: false);
    await tester.pumpWidget(TessApp(authService: fakeAuth));
    await tester.pump();

    // Verify login screen is displayed automatically by AuthGate
    expect(find.text('TESS OS // ACCESS'), findsOneWidget);
    expect(find.text('Initialize Connection'), findsOneWidget);
  });
}
