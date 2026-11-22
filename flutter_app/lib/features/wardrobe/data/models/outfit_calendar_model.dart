import '../../domain/entities/outfit_calendar_entry.dart';
import 'outfit_plan_model.dart';
import 'actual_wear_model.dart';
import 'weather_model.dart';

class CalendarDayDetailModel extends CalendarDayDetail {
  const CalendarDayDetailModel({
    required super.date,
    super.plans = const [],
    super.actualWears = const [],
    super.hasPlan = false,
    super.hasActualWear = false,
    super.weather,
  });

  factory CalendarDayDetailModel.fromJson(Map<String, dynamic> json) {
    return CalendarDayDetailModel(
      date: json['date'] as String? ?? '',
      plans: (json['plans'] as List<dynamic>?)
              ?.map((p) => OutfitPlanModel.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      actualWears: (json['actual_wears'] as List<dynamic>?)
              ?.map((w) => ActualWearModel.fromJson(w as Map<String, dynamic>))
              .toList() ??
          [],
      hasPlan: json['has_plan'] as bool? ?? false,
      hasActualWear: json['has_actual_wear'] as bool? ?? false,
      weather: json['weather'] != null
          ? WeatherModel.fromJson(json['weather'] as Map<String, dynamic>)
          : null,
    );
  }
}
