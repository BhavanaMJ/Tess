import '../../domain/entities/weather_context.dart';

class WeatherModel extends WeatherContext {
  const WeatherModel({
    required super.location,
    required super.date,
    required super.temperatureC,
    super.feelsLikeC,
    required super.conditionCode,
    required super.conditionText,
    super.rainProbability = 0,
    super.windKph,
    super.humidity,
    required super.stylingSuggestion,
    super.isForecastAvailable = true,
    super.message,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      location: json['location'] as String? ?? 'Current Location',
      date: json['date'] as String? ?? '',
      temperatureC: (json['temperature_c'] as num?)?.toDouble() ?? 20.0,
      feelsLikeC: (json['feels_like_c'] as num?)?.toDouble(),
      conditionCode: json['condition_code'] as String? ?? 'CLEAR',
      conditionText: json['condition_text'] as String? ?? 'Clear sky',
      rainProbability: json['rain_probability'] as int? ?? 0,
      windKph: (json['wind_kph'] as num?)?.toDouble(),
      humidity: json['humidity'] as int?,
      stylingSuggestion: json['styling_suggestion'] as String? ?? 'Mild weather.',
      isForecastAvailable: json['is_forecast_available'] as bool? ?? true,
      message: json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'location': location,
      'date': date,
      'temperature_c': temperatureC,
      'feels_like_c': feelsLikeC,
      'condition_code': conditionCode,
      'condition_text': conditionText,
      'rain_probability': rainProbability,
      'wind_kph': windKph,
      'humidity': humidity,
      'styling_suggestion': stylingSuggestion,
      'is_forecast_available': isForecastAvailable,
      'message': message,
    };
  }
}

