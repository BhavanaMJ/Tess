import '../entities/outfit_calendar_entry.dart';
import '../entities/outfit_plan.dart';
import '../entities/actual_wear_record.dart';
import '../entities/calendar_intelligence.dart';
import '../entities/weather_context.dart';

abstract class CalendarRepository {
  Future<CalendarDayDetail> getDayDetail(DateTime date);

  Future<List<CalendarDayDetail>> getWeekView(DateTime startDate);

  Future<List<CalendarDayDetail>> getMonthView(int year, int month);

  Future<OutfitPlan> createPlan({
    required String outfitId,
    required DateTime plannedDate,
    required String occasion,
    String? notes,
  });

  Future<OutfitPlan> updatePlan({
    required String planId,
    DateTime? plannedDate,
    String? occasion,
    String? notes,
  });

  Future<void> deletePlan(String planId);

  Future<ActualWearRecord> recordActualWear({
    required String outfitId,
    required DateTime actualWornDate,
    String? planId,
    String? notes,
    String? idempotencyKey,
  });

  Future<List<ActualWearRecord>> getOutfitHistory({int limit = 50});

  Future<List<OutfitPlan>> getUpcomingPlans({int limit = 10});

  Future<RepetitionCheck> checkRepetition({
    required String outfitId,
    required DateTime date,
    int windowDays = 14,
  });

  Future<List<RecentlyWornGarment>> getRecentlyWorn({int limit = 10});

  Future<List<UnusedGarment>> getUnusedGarments({int daysThreshold = 30});

  Future<WeatherContext> getWeather(
    DateTime date, {
    String location = 'Current Location',
    double? latitude,
    double? longitude,
  });
}

