import 'package:flutter/foundation.dart';
import '../../domain/entities/actual_wear_record.dart';
import '../../domain/entities/calendar_intelligence.dart';
import '../../domain/entities/outfit_calendar_entry.dart';
import '../../domain/entities/outfit_plan.dart';
import '../../domain/entities/weather_context.dart';
import '../../domain/repositories/calendar_repository.dart';

enum CalendarViewMode {
  day,
  week,
  month;

  String get label {
    switch (this) {
      case CalendarViewMode.day:
        return 'Day';
      case CalendarViewMode.week:
        return 'Week';
      case CalendarViewMode.month:
        return 'Month';
    }
  }
}

class CalendarController extends ChangeNotifier {
  final CalendarRepository _repository;

  CalendarController({required CalendarRepository repository})
      : _repository = repository {
    _init();
  }

  DateTime _selectedDate = DateTime.now();
  CalendarViewMode _viewMode = CalendarViewMode.month;

  CalendarDayDetail? _selectedDayDetail;
  List<CalendarDayDetail> _currentRangeDays = [];
  WeatherContext? _currentWeather;
  List<OutfitPlan> _upcomingPlans = [];
  List<ActualWearRecord> _wearHistory = [];
  List<RecentlyWornGarment> _recentlyWornGarments = [];
  List<UnusedGarment> _unusedGarments = [];

  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  DateTime get selectedDate => _selectedDate;
  CalendarViewMode get viewMode => _viewMode;
  CalendarDayDetail? get selectedDayDetail => _selectedDayDetail;
  List<CalendarDayDetail> get currentRangeDays => _currentRangeDays;
  WeatherContext? get currentWeather => _currentWeather;
  List<OutfitPlan> get upcomingPlans => _upcomingPlans;
  List<ActualWearRecord> get wearHistory => _wearHistory;
  List<RecentlyWornGarment> get recentlyWornGarments => _recentlyWornGarments;
  List<UnusedGarment> get unusedGarments => _unusedGarments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> _init() async {
    await loadCalendarData();
    await loadUpcomingPlans();
    await loadIntelligence();
  }

  void setViewMode(CalendarViewMode mode) {
    if (_viewMode == mode) return;
    _viewMode = mode;
    loadCalendarData();
  }

  Future<void> selectDate(DateTime dt) async {
    _selectedDate = dt;
    notifyListeners();
    await loadDayDetail(dt);
  }

  Future<void> loadCalendarData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_viewMode == CalendarViewMode.day) {
        await loadDayDetail(_selectedDate);
      } else if (_viewMode == CalendarViewMode.week) {
        // Find beginning of week (Monday)
        final weekday = _selectedDate.weekday;
        final startOfWeek = _selectedDate.subtract(Duration(days: weekday - 1));
        _currentRangeDays = await _repository.getWeekView(startOfWeek);
        await loadDayDetail(_selectedDate);
      } else {
        _currentRangeDays = await _repository.getMonthView(_selectedDate.year, _selectedDate.month);
        await loadDayDetail(_selectedDate);
      }
    } catch (e) {
      _errorMessage = 'Failed to load calendar: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadDayDetail(DateTime dt) async {
    try {
      _selectedDayDetail = await _repository.getDayDetail(dt);
      _currentWeather = _selectedDayDetail?.weather ?? await _repository.getWeather(dt);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load day details: $e';
      notifyListeners();
    }
  }

  Future<void> nextPeriod() async {
    if (_viewMode == CalendarViewMode.day) {
      await selectDate(_selectedDate.add(const Duration(days: 1)));
    } else if (_viewMode == CalendarViewMode.week) {
      await selectDate(_selectedDate.add(const Duration(days: 7)));
      await loadCalendarData();
    } else {
      final nextMonth = _selectedDate.month == 12
          ? DateTime(_selectedDate.year + 1, 1, _selectedDate.day)
          : DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
      await selectDate(nextMonth);
      await loadCalendarData();
    }
  }

  Future<void> previousPeriod() async {
    if (_viewMode == CalendarViewMode.day) {
      await selectDate(_selectedDate.subtract(const Duration(days: 1)));
    } else if (_viewMode == CalendarViewMode.week) {
      await selectDate(_selectedDate.subtract(const Duration(days: 7)));
      await loadCalendarData();
    } else {
      final prevMonth = _selectedDate.month == 1
          ? DateTime(_selectedDate.year - 1, 12, 1)
          : DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
      await selectDate(prevMonth);
      await loadCalendarData();
    }
  }

  Future<OutfitPlan?> createPlan({
    required String outfitId,
    required DateTime plannedDate,
    required String occasion,
    String? notes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final plan = await _repository.createPlan(
        outfitId: outfitId,
        plannedDate: plannedDate,
        occasion: occasion,
        notes: notes,
      );
      await loadCalendarData();
      await loadUpcomingPlans();
      return plan;
    } catch (e) {
      _errorMessage = 'Failed to save plan: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<OutfitPlan?> updatePlan({
    required String planId,
    DateTime? plannedDate,
    String? occasion,
    String? notes,
  }) async {
    try {
      final plan = await _repository.updatePlan(
        planId: planId,
        plannedDate: plannedDate,
        occasion: occasion,
        notes: notes,
      );
      await loadCalendarData();
      await loadUpcomingPlans();
      return plan;
    } catch (e) {
      _errorMessage = 'Failed to update plan: $e';
      notifyListeners();
      return null;
    }
  }

  Future<void> deletePlan(String planId) async {
    try {
      await _repository.deletePlan(planId);
      await loadCalendarData();
      await loadUpcomingPlans();
    } catch (e) {
      _errorMessage = 'Failed to delete plan: $e';
      notifyListeners();
    }
  }

  Future<ActualWearRecord?> recordActualWear({
    required String outfitId,
    required DateTime actualWornDate,
    String? planId,
    String? notes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final wear = await _repository.recordActualWear(
        outfitId: outfitId,
        actualWornDate: actualWornDate,
        planId: planId,
        notes: notes,
      );
      await loadCalendarData();
      await loadHistory();
      await loadIntelligence();
      return wear;
    } catch (e) {
      _errorMessage = 'Failed to record wear: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<RepetitionCheck> checkRepetition({
    required String outfitId,
    required DateTime date,
  }) async {
    return await _repository.checkRepetition(outfitId: outfitId, date: date);
  }

  Future<void> loadUpcomingPlans() async {
    try {
      _upcomingPlans = await _repository.getUpcomingPlans(limit: 10);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadHistory() async {
    try {
      _wearHistory = await _repository.getOutfitHistory(limit: 50);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadIntelligence() async {
    try {
      _recentlyWornGarments = await _repository.getRecentlyWorn(limit: 10);
      _unusedGarments = await _repository.getUnusedGarments(daysThreshold: 30);
      notifyListeners();
    } catch (_) {}
  }
}

