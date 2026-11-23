import '../../../../core/network/api_client.dart';
import '../../domain/entities/calendar_intelligence.dart';
import '../models/actual_wear_model.dart';
import '../models/outfit_calendar_model.dart';
import '../models/outfit_plan_model.dart';
import '../models/weather_model.dart';

class CalendarApiService {
  final ApiClient _apiClient;

  CalendarApiService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// GET /api/v1/wardrobe/calendar/day/{date}
  Future<CalendarDayDetailModel> getDayDetail(String date) async {
    final response = await _apiClient.get('/api/v1/wardrobe/calendar/day/$date');
    return CalendarDayDetailModel.fromJson(response as Map<String, dynamic>);
  }

  /// GET /api/v1/wardrobe/calendar/week?start_date={startDate}
  Future<List<CalendarDayDetailModel>> getWeekView(String startDate) async {
    final response = await _apiClient.get('/api/v1/wardrobe/calendar/week?start_date=$startDate');
    final data = response as Map<String, dynamic>;
    final days = data['days'] as List<dynamic>? ?? [];
    return days.map((d) => CalendarDayDetailModel.fromJson(d as Map<String, dynamic>)).toList();
  }

  /// GET /api/v1/wardrobe/calendar/month?year={year}&month={month}
  Future<List<CalendarDayDetailModel>> getMonthView(int year, int month) async {
    final response = await _apiClient.get('/api/v1/wardrobe/calendar/month?year=$year&month=$month');
    final data = response as Map<String, dynamic>;
    final days = data['days'] as List<dynamic>? ?? [];
    return days.map((d) => CalendarDayDetailModel.fromJson(d as Map<String, dynamic>)).toList();
  }

  /// POST /api/v1/wardrobe/calendar/plans
  Future<OutfitPlanModel> createPlan(Map<String, dynamic> body) async {
    final response = await _apiClient.post('/api/v1/wardrobe/calendar/plans', body: body);
    return OutfitPlanModel.fromJson(response as Map<String, dynamic>);
  }

  /// PUT /api/v1/wardrobe/calendar/plans/{planId}
  Future<OutfitPlanModel> updatePlan(String planId, Map<String, dynamic> body) async {
    final response = await _apiClient.put('/api/v1/wardrobe/calendar/plans/$planId', body: body);
    return OutfitPlanModel.fromJson(response as Map<String, dynamic>);
  }

  /// DELETE /api/v1/wardrobe/calendar/plans/{planId}
  Future<void> deletePlan(String planId) async {
    await _apiClient.delete('/api/v1/wardrobe/calendar/plans/$planId');
  }

  /// POST /api/v1/wardrobe/calendar/wear
  Future<ActualWearModel> recordActualWear(Map<String, dynamic> body) async {
    final response = await _apiClient.post('/api/v1/wardrobe/calendar/wear', body: body);
    return ActualWearModel.fromJson(response as Map<String, dynamic>);
  }

  /// GET /api/v1/wardrobe/calendar/history?limit={limit}
  Future<List<ActualWearModel>> getOutfitHistory({int limit = 50}) async {
    final response = await _apiClient.get('/api/v1/wardrobe/calendar/history?limit=$limit');
    final list = response as List<dynamic>? ?? [];
    return list.map((w) => ActualWearModel.fromJson(w as Map<String, dynamic>)).toList();
  }

  /// GET /api/v1/wardrobe/calendar/plans/upcoming?limit={limit}
  Future<List<OutfitPlanModel>> getUpcomingPlans({int limit = 10}) async {
    final response = await _apiClient.get('/api/v1/wardrobe/calendar/plans/upcoming?limit=$limit');
    final list = response as List<dynamic>? ?? [];
    return list.map((p) => OutfitPlanModel.fromJson(p as Map<String, dynamic>)).toList();
  }

  /// GET /api/v1/wardrobe/calendar/intelligence/repetition
  Future<RepetitionCheck> checkRepetition({
    required String outfitId,
    required String date,
    int windowDays = 14,
  }) async {
    final response = await _apiClient.get(
      '/api/v1/wardrobe/calendar/intelligence/repetition?outfit_id=$outfitId&date=$date&window_days=$windowDays',
    );
    final json = response as Map<String, dynamic>;
    return RepetitionCheck(
      isRepeated: json['is_repeated'] as bool? ?? false,
      message: json['message'] as String?,
      lastWornDate: json['last_worn_date'] as String?,
      lastPlannedOrWornDate: json['last_planned_or_worn_date'] as String?,
      daysSince: json['days_since'] as int?,
      repetitionCount: json['repetition_count'] as int? ?? 0,
    );
  }

  /// GET /api/v1/wardrobe/calendar/intelligence/recently-worn
  Future<List<RecentlyWornGarment>> getRecentlyWorn({int limit = 10}) async {
    final response = await _apiClient.get('/api/v1/wardrobe/calendar/intelligence/recently-worn?limit=$limit');
    final list = response as List<dynamic>? ?? [];
    return list.map((j) {
      final json = j as Map<String, dynamic>;
      return RecentlyWornGarment(
        garmentId: json['garment_id'] as String? ?? '',
        garmentName: json['garment_name'] as String? ?? '',
        mainCategory: json['main_category'] as String? ?? '',
        primaryColor: json['primary_color'] as String? ?? '',
        thumbnailRef: json['thumbnail_ref'] as String?,
        lastWornDate: json['last_worn_date'] != null
            ? DateTime.tryParse(json['last_worn_date'].toString())
            : null,
        wearCount: json['wear_count'] as int? ?? 0,
      );
    }).toList();
  }

  /// GET /api/v1/wardrobe/calendar/intelligence/unused
  Future<List<UnusedGarment>> getUnusedGarments({int daysThreshold = 30}) async {
    final response = await _apiClient.get('/api/v1/wardrobe/calendar/intelligence/unused?days_threshold=$daysThreshold');
    final list = response as List<dynamic>? ?? [];
    return list.map((j) {
      final json = j as Map<String, dynamic>;
      return UnusedGarment(
        garmentId: json['garment_id'] as String? ?? '',
        garmentName: json['garment_name'] as String? ?? '',
        mainCategory: json['main_category'] as String? ?? '',
        primaryColor: json['primary_color'] as String? ?? '',
        thumbnailRef: json['thumbnail_ref'] as String?,
        lastWornDate: json['last_worn_date'] != null
            ? DateTime.tryParse(json['last_worn_date'].toString())
            : null,
        wearCount: json['wear_count'] as int? ?? 0,
        statusCategory: json['status_category'] as String? ?? 'NEVER_WORN',
      );
    }).toList();
  }

  /// GET /api/v1/wardrobe/weather/{date}
  Future<WeatherModel> getWeather(
    String date, {
    String location = 'Current Location',
    double? lat,
    double? lon,
  }) async {
    final latParam = lat != null ? '&lat=$lat' : '';
    final lonParam = lon != null ? '&lon=$lon' : '';
    final response = await _apiClient.get('/api/v1/wardrobe/weather/$date?location=$location$latParam$lonParam');
    return WeatherModel.fromJson(response as Map<String, dynamic>);
  }
}

