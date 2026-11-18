import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tess/core/theme/app_colors.dart';
import 'package:tess/core/theme/app_theme.dart';
import 'package:tess/core/theme/theme_controller.dart';
import 'package:tess/shared/mascot/tess_mascot.dart';
import 'package:tess/shared/mascot/tess_mascot_controller.dart';
import 'package:tess/shared/mascot/tess_mascot_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 15: Theme Architecture & Persistence Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('ThemeController initializes with Light theme as default', () async {
      final controller = ThemeController.instance;
      await controller.init();

      expect(controller.themeMode, ThemeMode.light);
      expect(controller.isDarkModeActive(false), false);
      expect(controller.isDarkModeActive(true), false);
    });

    test('ThemeController switches to Dark theme and persists preference', () async {
      final controller = ThemeController.instance;
      await controller.init();

      await controller.setThemeMode(ThemeMode.dark);
      expect(controller.themeMode, ThemeMode.dark);
      expect(controller.isDarkModeActive(false), true);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(ThemeController.themePreferenceKey), 'dark');
    });

    test('ThemeController switches to System theme and follows platform brightness', () async {
      final controller = ThemeController.instance;
      await controller.init();

      await controller.setThemeMode(ThemeMode.system);
      expect(controller.themeMode, ThemeMode.system);
      expect(controller.isDarkModeActive(true), true);
      expect(controller.isDarkModeActive(false), false);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(ThemeController.themePreferenceKey), 'system');
    });

    test('AppTheme.lightTheme defines verified Phase 15 design system tokens', () {
      final theme = AppTheme.lightTheme;

      expect(theme.brightness, Brightness.light);
      expect(theme.scaffoldBackgroundColor, AppColors.lightBackground);
      expect(theme.cardColor, AppColors.lightSurface);
      expect(theme.colorScheme.primary, AppColors.tessTeal);
      expect(theme.colorScheme.surface, AppColors.lightSurface);
      expect(theme.useMaterial3, true);
    });

    test('AppTheme.darkTheme defines verified Phase 15 design system tokens', () {
      final theme = AppTheme.darkTheme;

      expect(theme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, AppColors.darkBackground);
      expect(theme.cardColor, AppColors.darkSurface);
      expect(theme.colorScheme.primary, AppColors.vibrantMint);
      expect(theme.colorScheme.surface, AppColors.darkSurface);
      expect(theme.useMaterial3, true);
    });
  });

  group('Phase 15: Expressive Mascot Specification Tests', () {
    test('TessMascotState has exactly 9 defined states with cognitive statuses', () {
      expect(TessMascotState.values.length, 9);

      for (final state in TessMascotState.values) {
        expect(state.displayName.isNotEmpty, true);
        expect(state.cognitiveStatus.isNotEmpty, true);
      }

      expect(TessMascotState.idle.displayName, 'Idle');
      expect(TessMascotState.thinking.displayName, 'Thinking');
      expect(TessMascotState.happy.displayName, 'Happy');
      expect(TessMascotState.attention.displayName, 'Attention');
      expect(TessMascotState.planning.displayName, 'Planning');
      expect(TessMascotState.confirming.displayName, 'Confirming');
      expect(TessMascotState.acting.displayName, 'Acting');
      expect(TessMascotState.success.displayName, 'Success');
      expect(TessMascotState.error.displayName, 'Error');
    });

    test('TessMascotController manages state transitions and auto-revert', () async {
      final controller = TessMascotController();
      expect(controller.state, TessMascotState.idle);

      controller.setState(TessMascotState.thinking);
      expect(controller.state, TessMascotState.thinking);

      controller.express(TessMascotState.happy, duration: const Duration(milliseconds: 50));
      expect(controller.state, TessMascotState.happy);

      await Future.delayed(const Duration(milliseconds: 70));
      expect(controller.state, TessMascotState.thinking);

      controller.dispose();
    });

    testWidgets('TessMascot renders in hero mode with cognitive status pill', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TessMascot(
              state: TessMascotState.idle,
              showStatusPill: true,
              size: 120.0,
            ),
          ),
        ),
      );

      expect(find.byType(TessMascot), findsOneWidget);
      expect(find.text('IDLE'), findsOneWidget);
    });

    testWidgets('TessMascot renders in compact mode without pill', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TessMascot.compact(
              state: TessMascotState.thinking,
              size: 40.0,
            ),
          ),
        ),
      );

      expect(find.byType(TessMascot), findsOneWidget);
      expect(find.text('REASONING // SYNTHESIZING'), findsNothing);
    });
  });
}
