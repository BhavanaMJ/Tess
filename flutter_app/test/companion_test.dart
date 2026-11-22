import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tess/shared/companion/tess_companion.dart';
import 'package:tess/shared/companion/tess_companion_controller.dart';
import 'package:tess/shared/companion/tess_companion_preview_screen.dart';
import 'package:tess/shared/companion/tess_emotion.dart';
import 'package:tess/shared/mascot/tess_mascot_state.dart';

void main() {
  group('Phase 15: TessEmotion Model & Conversions', () {
    test('All 9 canonical emotions exist with non-empty metadata', () {
      expect(TessEmotion.values.length, 9);
      for (final emotion in TessEmotion.values) {
        expect(emotion.label, isNotEmpty);
        expect(emotion.auraColor, isNotNull);
        expect(emotion.breathDurationMs, greaterThan(0));
      }
    });

    test('Two-way conversion between TessEmotion and TessMascotState', () {
      for (final emotion in TessEmotion.values) {
        final mascotState = emotion.toTessMascotState();
        expect(mascotState.toTessEmotion(), emotion);
      }
    });
  });

  group('Phase 15: TessCompanionController', () {
    test('Initializes with idle and transitions emotion', () {
      final controller = TessCompanionController();
      expect(controller.emotion, TessEmotion.idle);

      controller.setEmotion(TessEmotion.thinking);
      expect(controller.emotion, TessEmotion.thinking);

      controller.resetToIdle();
      expect(controller.emotion, TessEmotion.idle);
      controller.dispose();
    });

    testWidgets('Temporary expression auto-reverts to idle after duration', (tester) async {
      final controller = TessCompanionController();
      controller.express(TessEmotion.happy, duration: const Duration(milliseconds: 500));
      expect(controller.emotion, TessEmotion.happy);

      // Advance time past duration
      await tester.pump(const Duration(milliseconds: 600));
      expect(controller.emotion, TessEmotion.idle);
      controller.dispose();
    });
  });

  group('Phase 15: TessCompanion Widget UI Tests', () {
    testWidgets('Renders TessCompanion and triggers onTap', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TessCompanion(
                emotion: TessEmotion.happy,
                size: 100.0,
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      // Verify widget exists
      expect(find.byType(TessCompanion), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);

      // Tap on companion
      await tester.tap(find.byType(TessCompanion));
      await tester.pump();
      expect(tapped, true);

      // Pump to drain periodic timer
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('Renders Hero and Compact size variants', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TessCompanion.hero(emotion: TessEmotion.attention),
                TessCompanion.compact(emotion: TessEmotion.idle),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(TessCompanion), findsNWidgets(2));
      await tester.pump(const Duration(seconds: 4));
    });
  });

  group('Phase 15: TessCompanionPreviewScreen UI Tests', () {
    testWidgets('Renders expression lab and switches emotions via chips', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TessCompanionPreviewScreen(),
        ),
      );

      // Verify title and initial emotion badge
      expect(find.text('Companion Expression Lab'), findsOneWidget);
      expect(find.text('IDLE'), findsOneWidget);

      // Verify chips for all 9 emotions exist
      for (final emotion in TessEmotion.values) {
        expect(find.widgetWithText(ChoiceChip, emotion.name), findsOneWidget);
      }

      // Tap 'happy' chip
      await tester.tap(find.widgetWithText(ChoiceChip, 'happy'));
      await tester.pump();

      // Badge should update to HAPPY
      expect(find.text('HAPPY'), findsOneWidget);

      // Tap 'Thinking (3s)' transient button
      await tester.tap(find.text('Thinking (3s)'));
      await tester.pump();
      expect(find.text('THINKING'), findsOneWidget);

      // Wait 3.5 seconds for revert back to idle
      await tester.pump(const Duration(milliseconds: 3500));
      expect(find.text('IDLE'), findsOneWidget);

      // Drain periodic timers
      await tester.pump(const Duration(seconds: 4));
    });
  });
}
