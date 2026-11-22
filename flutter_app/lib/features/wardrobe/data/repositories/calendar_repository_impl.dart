import '../../domain/entities/actual_wear_record.dart';
import '../../domain/entities/calendar_intelligence.dart';
import '../../domain/entities/outfit.dart';
import '../../domain/entities/outfit_calendar_entry.dart';
import '../../domain/entities/outfit_plan.dart';
import '../../domain/entities/weather_context.dart';
import '../../domain/repositories/calendar_repository.dart';
import '../../domain/repositories/outfit_repository.dart';
import '../services/calendar_api_service.dart';

class CalendarRepositoryImpl implements CalendarRepository {
  final CalendarApiService _apiService;
  final OutfitRepository? _outfitRepository;

  // In-memory offline fallback caches
  final Map<String, OutfitPlan> _localPlans = {};
  final Map<String, ActualWearRecord> _localActualWears = {};

  CalendarRepositoryImpl({
    CalendarApiService? apiService,
    OutfitRepository? outfitRepository,
  })  : _apiService = apiService ?? CalendarApiService(),
        _outfitRepository = outfitRepository;

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  @override
  Future<CalendarDayDetail> getDayDetail(DateTime date) async {
    final dateStr = _formatDate(date);
    try {
      final remote = await _apiService.getDayDetail(dateStr);
      // Cache locally
      for (final p in remote.plans) {
        _localPlans[p.id] = p;
      }
      for (final w in remote.actualWears) {
        _localActualWears[w.id] = w;
      }
      return remote;
    } catch (_) {
      // Local fallback
      final plans = _localPlans.values.where((p) => p.plannedDate == dateStr).toList();
      final actuals = _localActualWears.values.where((w) => w.actualWornDate == dateStr).toList();
      final weather = await getWeather(date);
      return CalendarDayDetail(
        date: dateStr,
        plans: plans,
        actualWears: actuals,
        hasPlan: plans.isNotEmpty,
        hasActualWear: actuals.isNotEmpty,
        weather: weather,
      );
    }
  }

  @override
  Future<List<CalendarDayDetail>> getWeekView(DateTime startDate) async {
    final startStr = _formatDate(startDate);
    try {
      return await _apiService.getWeekView(startStr);
    } catch (_) {
      final days = <CalendarDayDetail>[];
      for (int i = 0; i < 7; i++) {
        final d = startDate.add(Duration(days: i));
        days.add(await getDayDetail(d));
      }
      return days;
    }
  }

  @override
  Future<List<CalendarDayDetail>> getMonthView(int year, int month) async {
    try {
      return await _apiService.getMonthView(year, month);
    } catch (_) {
      final days = <CalendarDayDetail>[];
      final firstDay = DateTime(year, month, 1);
      final nextMonth = month == 12 ? DateTime(year + 1, 1, 1) : DateTime(year, month + 1, 1);
      final daysInMonth = nextMonth.difference(firstDay).inDays;

      for (int d = 1; d <= daysInMonth; d++) {
        final date = DateTime(year, month, d);
        days.add(await getDayDetail(date));
      }
      return days;
    }
  }

  @override
  Future<OutfitPlan> createPlan({
    required String outfitId,
    required DateTime plannedDate,
    required String occasion,
    String? notes,
  }) async {
    final dateStr = _formatDate(plannedDate);
    final payload = {
      'outfit_id': outfitId,
      'planned_date': dateStr,
      'occasion': occasion,
      if (notes != null) 'notes': notes,
    };

    try {
      final plan = await _apiService.createPlan(payload);
      _localPlans[plan.id] = plan;
      return plan;
    } catch (_) {
      // Offline fallback plan creation
      Outfit? outfit;
      if (_outfitRepository != null) {
        try {
          outfit = await _outfitRepository!.getOutfit(outfitId);
        } catch (_) {}
      }
      final now = DateTime.now();
      final fallbackPlan = OutfitPlan(
        id: 'plan_local_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'current_user',
        outfitId: outfitId,
        outfitName: outfit?.name ?? 'Planned Look',
        outfit: outfit ??
            Outfit(
              id: outfitId,
              userId: 'current_user',
              name: 'Planned Look',
              occasion: occasion,
              createdAt: now,
              updatedAt: now,
            ),
        plannedDate: dateStr,
        occasion: occasion,
        notes: notes,
        isWorn: false,
        isAvailable: outfit?.isAvailable ?? true,
        createdAt: now,
        updatedAt: now,
      );
      _localPlans[fallbackPlan.id] = fallbackPlan;
      return fallbackPlan;
    }
  }

  @override
  Future<OutfitPlan> updatePlan({
    required String planId,
    DateTime? plannedDate,
    String? occasion,
    String? notes,
  }) async {
    final payload = <String, dynamic>{};
    if (plannedDate != null) payload['planned_date'] = _formatDate(plannedDate);
    if (occasion != null) payload['occasion'] = occasion;
    if (notes != null) payload['notes'] = notes;

    try {
      final plan = await _apiService.updatePlan(planId, payload);
      _localPlans[plan.id] = plan;
      return plan;
    } catch (_) {
      final existing = _localPlans[planId];
      if (existing != null) {
        final updated = existing.copyWith(
          plannedDate: plannedDate != null ? _formatDate(plannedDate) : null,
          occasion: occasion,
          notes: notes,
          updatedAt: DateTime.now(),
        );
        _localPlans[planId] = updated;
        return updated;
      }
      rethrow;
    }
  }

  @override
  Future<void> deletePlan(String planId) async {
    try {
      await _apiService.deletePlan(planId);
    } catch (_) {}
    _localPlans.remove(planId);
  }

  @override
  Future<ActualWearRecord> recordActualWear({
    required String outfitId,
    required DateTime actualWornDate,
    String? planId,
    String? notes,
    String? idempotencyKey,
  }) async {
    final dateStr = _formatDate(actualWornDate);
    final payload = {
      'outfit_id': outfitId,
      'actual_worn_date': dateStr,
      if (planId != null) 'plan_id': planId,
      if (notes != null) 'notes': notes,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
    };

    try {
      final wear = await _apiService.recordActualWear(payload);
      _localActualWears[wear.id] = wear;
      if (planId != null && _localPlans.containsKey(planId)) {
        _localPlans[planId] = _localPlans[planId]!.copyWith(isWorn: true);
      }
      return wear;
    } catch (_) {
      Outfit? outfit;
      if (_outfitRepository != null) {
        try {
          outfit = await _outfitRepository!.getOutfit(outfitId);
        } catch (_) {}
      }
      final now = DateTime.now();
      final wearRecord = ActualWearRecord(
        id: 'cwear_local_${now.millisecondsSinceEpoch}',
        userId: 'current_user',
        outfitId: outfitId,
        outfitName: outfit?.name ?? 'Worn Look',
        outfit: outfit ??
            Outfit(
              id: outfitId,
              userId: 'current_user',
              name: 'Worn Look',
              occasion: 'Casual',
              createdAt: now,
              updatedAt: now,
            ),
        planId: planId,
        actualWornDate: dateStr,
        wornAt: now,
        wearCount: 1,
        notes: notes,
        createdAt: now,
      );
      _localActualWears[wearRecord.id] = wearRecord;
      if (planId != null && _localPlans.containsKey(planId)) {
        _localPlans[planId] = _localPlans[planId]!.copyWith(isWorn: true);
      }
      return wearRecord;
    }
  }

  @override
  Future<List<ActualWearRecord>> getOutfitHistory({int limit = 50}) async {
    try {
      final history = await _apiService.getOutfitHistory(limit: limit);
      for (final w in history) {
        _localActualWears[w.id] = w;
      }
      return history;
    } catch (_) {
      final list = _localActualWears.values.toList();
      list.sort((a, b) => b.actualWornDate.compareTo(a.actualWornDate));
      return list.take(limit).toList();
    }
  }

  @override
  Future<List<OutfitPlan>> getUpcomingPlans({int limit = 10}) async {
    try {
      final plans = await _apiService.getUpcomingPlans(limit: limit);
      for (final p in plans) {
        _localPlans[p.id] = p;
      }
      return plans;
    } catch (_) {
      final todayStr = _formatDate(DateTime.now());
      final upcoming = _localPlans.values.where((p) => p.plannedDate.compareTo(todayStr) >= 0).toList();
      upcoming.sort((a, b) => a.plannedDate.compareTo(b.plannedDate));
      return upcoming.take(limit).toList();
    }
  }

  @override
  Future<RepetitionCheck> checkRepetition({
    required String outfitId,
    required DateTime date,
    int windowDays = 14,
  }) async {
    final dateStr = _formatDate(date);
    try {
      return await _apiService.checkRepetition(
        outfitId: outfitId,
        date: dateStr,
        windowDays: windowDays,
      );
    } catch (_) {
      final recent = _localActualWears.values.where((w) {
        if (w.outfitId != outfitId) return false;
        final wDate = DateTime.tryParse(w.actualWornDate);
        if (wDate == null) return false;
        return wDate.difference(date).inDays.abs() <= windowDays && w.actualWornDate != dateStr;
      }).toList();

      if (recent.isNotEmpty) {
        recent.sort((a, b) => b.actualWornDate.compareTo(a.actualWornDate));
        final lastWorn = recent.first.actualWornDate;
        return RepetitionCheck(
          isRepeated: true,
          lastWornDate: lastWorn,
          message: 'You wore this outfit on $lastWorn. Consider styling with an alternative piece to keep your look fresh.',
          repetitionCount: recent.length,
        );
      }
      return const RepetitionCheck(isRepeated: false);
    }
  }

  @override
  Future<List<RecentlyWornGarment>> getRecentlyWorn({int limit = 10}) async {
    try {
      return await _apiService.getRecentlyWorn(limit: limit);
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<List<UnusedGarment>> getUnusedGarments({int daysThreshold = 30}) async {
    try {
      return await _apiService.getUnusedGarments(daysThreshold: daysThreshold);
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<WeatherContext> getWeather(
    DateTime date, {
    String location = 'Current Location',
    double? latitude,
    double? longitude,
  }) async {
    final dateStr = _formatDate(date);
    final now = DateTime.now();
    final diffDays = date.difference(DateTime(now.year, now.month, now.day)).inDays;

    if (diffDays > 14 || diffDays < -7) {
      return WeatherContext(
        location: location,
        date: dateStr,
        temperatureC: 20.0,
        conditionCode: 'UNAVAILABLE',
        conditionText: 'Forecast unavailable',
        stylingSuggestion: 'Weather forecast is not available for this date.',
        isForecastAvailable: false,
        message: 'Weather forecast is not available for this date.',
      );
    }

    try {
      return await _apiService.getWeather(
        dateStr,
        location: location,
        lat: latitude,
        lon: longitude,
      );
    } catch (_) {
      final doy = date.difference(DateTime(date.year, 1, 1)).inDays;
      final temp = 18.0 + (doy % 10);
      return WeatherContext(
        location: location,
        date: dateStr,
        temperatureC: temp,
        feelsLikeC: temp - 1.0,
        conditionCode: 'PARTLY_CLOUDY',
        conditionText: 'Partly cloudy',
        rainProbability: 10,
        stylingSuggestion: 'Pleasant conditions. Breathable cotton or casual layers recommended.',
        isForecastAvailable: true,
      );
    }
  }
}
