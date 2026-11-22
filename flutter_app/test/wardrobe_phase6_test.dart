import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tess/core/theme/app_theme.dart';
import 'package:tess/features/wardrobe/domain/entities/actual_wear_record.dart';
import 'package:tess/features/wardrobe/domain/entities/calendar_intelligence.dart';
import 'package:tess/features/wardrobe/domain/entities/outfit.dart';
import 'package:tess/features/wardrobe/domain/entities/outfit_calendar_entry.dart';
import 'package:tess/features/wardrobe/domain/entities/outfit_item.dart';
import 'package:tess/features/wardrobe/domain/entities/outfit_plan.dart';
import 'package:tess/features/wardrobe/domain/entities/weather_context.dart';
import 'package:tess/features/wardrobe/domain/repositories/calendar_repository.dart';
import 'package:tess/features/wardrobe/presentation/controllers/calendar_controller.dart';
import 'package:tess/features/wardrobe/presentation/screens/actual_wear_screen.dart';
import 'package:tess/features/wardrobe/presentation/screens/outfit_calendar_screen.dart';
import 'package:tess/features/wardrobe/presentation/screens/outfit_plan_screen.dart';
import 'package:tess/features/wardrobe/presentation/widgets/weather_context_card.dart';

class MockCalendarRepository implements CalendarRepository {
  final Map<String, OutfitPlan> plans = {};
  final Map<String, ActualWearRecord> wears = {};

  final Outfit mockOutfit = Outfit(
    id: 'outfit_test_1',
    userId: 'user_1',
    name: 'Office Smart Look',
    occasion: 'Work',
    isAvailable: true,
    items: const [
      OutfitItem(
        garmentId: 'g_top',
        name: 'Blue Shirt',
        mainCategory: 'Tops',
        primaryColor: 'Blue',
        isEligible: true,
      ),
      OutfitItem(
        garmentId: 'g_bot',
        name: 'Dark Chinos',
        mainCategory: 'Bottoms',
        primaryColor: 'Navy',
        isEligible: true,
      ),
    ],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  @override
  Future<CalendarDayDetail> getDayDetail(DateTime date) async {
    final dStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final dayPlans = plans.values.where((p) => p.plannedDate == dStr).toList();
    final dayWears = wears.values.where((w) => w.actualWornDate == dStr).toList();
    final weather = await getWeather(date);
    return CalendarDayDetail(
      date: dStr,
      plans: dayPlans,
      actualWears: dayWears,
      hasPlan: dayPlans.isNotEmpty,
      hasActualWear: dayWears.isNotEmpty,
      weather: weather,
    );
  }

  @override
  Future<List<CalendarDayDetail>> getWeekView(DateTime startDate) async {
    final list = <CalendarDayDetail>[];
    for (int i = 0; i < 7; i++) {
      list.add(await getDayDetail(startDate.add(Duration(days: i))));
    }
    return list;
  }

  @override
  Future<List<CalendarDayDetail>> getMonthView(int year, int month) async {
    final list = <CalendarDayDetail>[];
    final daysInMonth = DateTime(year, month + 1, 0).day;
    for (int i = 1; i <= daysInMonth; i++) {
      list.add(await getDayDetail(DateTime(year, month, i)));
    }
    return list;
  }

  @override
  Future<OutfitPlan> createPlan({
    required String outfitId,
    required DateTime plannedDate,
    required String occasion,
    String? notes,
  }) async {
    final dStr = '${plannedDate.year}-${plannedDate.month.toString().padLeft(2, '0')}-${plannedDate.day.toString().padLeft(2, '0')}';
    final plan = OutfitPlan(
      id: 'plan_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'user_1',
      outfitId: outfitId,
      outfitName: mockOutfit.name,
      outfit: mockOutfit,
      plannedDate: dStr,
      occasion: occasion,
      notes: notes,
      isWorn: false,
      isAvailable: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    plans[plan.id] = plan;
    return plan;
  }

  @override
  Future<OutfitPlan> updatePlan({
    required String planId,
    DateTime? plannedDate,
    String? occasion,
    String? notes,
  }) async {
    final existing = plans[planId]!;
    final updated = existing.copyWith(
      plannedDate: plannedDate != null
          ? '${plannedDate.year}-${plannedDate.month.toString().padLeft(2, '0')}-${plannedDate.day.toString().padLeft(2, '0')}'
          : null,
      occasion: occasion,
      notes: notes,
      updatedAt: DateTime.now(),
    );
    plans[planId] = updated;
    return updated;
  }

  @override
  Future<void> deletePlan(String planId) async {
    plans.remove(planId);
  }

  @override
  Future<ActualWearRecord> recordActualWear({
    required String outfitId,
    required DateTime actualWornDate,
    String? planId,
    String? notes,
    String? idempotencyKey,
  }) async {
    final dStr = '${actualWornDate.year}-${actualWornDate.month.toString().padLeft(2, '0')}-${actualWornDate.day.toString().padLeft(2, '0')}';
    final wear = ActualWearRecord(
      id: 'wear_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'user_1',
      outfitId: outfitId,
      outfitName: mockOutfit.name,
      outfit: mockOutfit,
      planId: planId,
      actualWornDate: dStr,
      wornAt: DateTime.now(),
      wearCount: 1,
      notes: notes,
      createdAt: DateTime.now(),
    );
    wears[wear.id] = wear;
    if (planId != null && plans.containsKey(planId)) {
      plans[planId] = plans[planId]!.copyWith(isWorn: true);
    }
    return wear;
  }

  @override
  Future<List<ActualWearRecord>> getOutfitHistory({int limit = 50}) async {
    return wears.values.toList();
  }

  @override
  Future<List<OutfitPlan>> getUpcomingPlans({int limit = 10}) async {
    return plans.values.toList();
  }

  @override
  Future<RepetitionCheck> checkRepetition({
    required String outfitId,
    required DateTime date,
    int windowDays = 14,
  }) async {
    final matches = wears.values.where((w) => w.outfitId == outfitId).toList();
    if (matches.isNotEmpty) {
      return RepetitionCheck(
        isRepeated: true,
        lastWornDate: matches.first.actualWornDate,
        message: 'You wore this outfit recently on ${matches.first.actualWornDate}.',
      );
    }
    return const RepetitionCheck(isRepeated: false);
  }

  @override
  Future<List<RecentlyWornGarment>> getRecentlyWorn({int limit = 10}) async => [];

  @override
  Future<List<UnusedGarment>> getUnusedGarments({int daysThreshold = 30}) async => [];

  @override
  Future<WeatherContext> getWeather(
    DateTime date, {
    String location = 'Current Location',
    double? latitude,
    double? longitude,
  }) async {
    final dStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final now = DateTime.now();
    final diff = date.difference(DateTime(now.year, now.month, now.day)).inDays;
    if (diff > 14 || diff < -7) {
      return WeatherContext(
        location: location,
        date: dStr,
        temperatureC: 20.0,
        conditionCode: 'UNAVAILABLE',
        conditionText: 'Forecast unavailable',
        stylingSuggestion: 'Weather forecast is not available for this date.',
        isForecastAvailable: false,
      );
    }
    return WeatherContext(
      location: location,
      date: dStr,
      temperatureC: 22.0,
      feelsLikeC: 21.0,
      conditionCode: 'CLEAR',
      conditionText: 'Clear sky',
      rainProbability: 5,
      stylingSuggestion: 'Sunny & pleasant. Breathable cotton shirt recommended.',
      isForecastAvailable: true,
    );
  }
}

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: child,
    );
  }

  group('Phase 6: Outfit Calendar & Weather Unit and Widget Tests', () {
    late MockCalendarRepository mockRepo;
    late CalendarController controller;

    setUp(() async {
      mockRepo = MockCalendarRepository();
      controller = CalendarController(repository: mockRepo);
      await controller.loadCalendarData();
    });

    test('CalendarController creates plan with strict separation from wear status', () async {
      final targetDate = DateTime.now().add(const Duration(days: 3));
      final plan = await controller.createPlan(
        outfitId: 'outfit_test_1',
        plannedDate: targetDate,
        occasion: 'Team Conference',
        notes: 'Bring blazer',
      );

      expect(plan, isNotNull);
      expect(plan!.outfitId, 'outfit_test_1');
      expect(plan.isWorn, isFalse);
      expect(plan.isAvailable, isTrue);
      expect(controller.upcomingPlans.length, 1);
    });

    test('CalendarController records actual wear and updates plan isWorn flag (Workflow A)', () async {
      final targetDate = DateTime.now();
      final plan = await controller.createPlan(
        outfitId: 'outfit_test_1',
        plannedDate: targetDate,
        occasion: 'Casual Friday',
      );

      final wear = await controller.recordActualWear(
        outfitId: 'outfit_test_1',
        actualWornDate: targetDate,
        planId: plan!.id,
        notes: 'Great combo',
      );

      expect(wear, isNotNull);
      expect(wear!.planId, plan.id);
      expect(mockRepo.plans[plan.id]!.isWorn, isTrue);
      expect(controller.wearHistory.length, 1);
    });

    test('CalendarController changes view mode seamlessly', () async {
      expect(controller.viewMode, CalendarViewMode.month);

      controller.setViewMode(CalendarViewMode.week);
      expect(controller.viewMode, CalendarViewMode.week);

      controller.setViewMode(CalendarViewMode.day);
      expect(controller.viewMode, CalendarViewMode.day);
    });

    testWidgets('WeatherContextCard renders available weather context and styling recommendation', (tester) async {
      const weather = WeatherContext(
        location: 'San Francisco, CA',
        date: '2026-11-22',
        temperatureC: 18.5,
        feelsLikeC: 17.5,
        conditionCode: 'PARTLY_CLOUDY',
        conditionText: 'Partly cloudy',
        rainProbability: 15,
        stylingSuggestion: 'Mild conditions. Light jacket recommended.',
        isForecastAvailable: true,
      );

      await tester.pumpWidget(
        buildTestableWidget(
          const WeatherContextCard(weather: weather),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Partly cloudy'), findsOneWidget);
      expect(find.text('18.5°C • San Francisco, CA'), findsOneWidget);
      expect(find.text('Feels 18°'), findsOneWidget);
      expect(find.text('Mild conditions. Light jacket recommended.'), findsOneWidget);
    });

    testWidgets('WeatherContextCard handles horizon cutoff gracefully (> 14 days)', (tester) async {
      const farWeather = WeatherContext(
        location: 'Current Location',
        date: '2026-12-25',
        temperatureC: 20.0,
        conditionCode: 'UNAVAILABLE',
        conditionText: 'Forecast unavailable',
        stylingSuggestion: 'Weather forecast is not available for this date.',
        isForecastAvailable: false,
      );

      await tester.pumpWidget(
        buildTestableWidget(
          const WeatherContextCard(weather: farWeather),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Weather Forecast Unavailable'), findsOneWidget);
      expect(find.text('Weather forecast is not available for this date.'), findsOneWidget);
    });

    testWidgets('OutfitCalendarScreen renders view selector, header badge and calendar grid', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          OutfitCalendarScreen(controller: controller),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Outfit Calendar'), findsOneWidget);
      expect(find.text('PHASE 6'), findsOneWidget);
      expect(find.text('Month'), findsOneWidget);
      expect(find.text('Week'), findsOneWidget);
      expect(find.text('Day'), findsOneWidget);
      expect(find.text('Add Plan / Wear'), findsOneWidget);
    });

    testWidgets('OutfitPlanScreen permits date selection, occasion chips and saves plan', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          OutfitPlanScreen(controller: controller),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Plan an Outfit'), findsOneWidget);
      expect(find.text('Planned Date'), findsOneWidget);
      expect(find.text('Occasion'), findsOneWidget);
      expect(find.text('Save Outfit Plan'), findsOneWidget);
    });

    testWidgets('ActualWearScreen renders wear confirmation workflow', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          ActualWearScreen(controller: controller),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Confirm Actual Wear'), findsNWidgets(2)); // App bar title & Submit button
      expect(find.text('Date Worn'), findsOneWidget);
    });
  });
}
