import 'outfit_plan.dart';
import 'actual_wear_record.dart';
import 'weather_context.dart';

class CalendarDayDetail {
  final String date; // YYYY-MM-DD
  final List<OutfitPlan> plans;
  final List<ActualWearRecord> actualWears;
  final bool hasPlan;
  final bool hasActualWear;
  final WeatherContext? weather;

  const CalendarDayDetail({
    required this.date,
    this.plans = const [],
    this.actualWears = const [],
    this.hasPlan = false,
    this.hasActualWear = false,
    this.weather,
  });

  bool get isToday {
    final now = DateTime.now();
    final dStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return date == dStr;
  }
}
