class WeatherContext {
  final String location;
  final String date;
  final double temperatureC;
  final double? feelsLikeC;
  final String conditionCode;
  final String conditionText;
  final int rainProbability;
  final double? windKph;
  final int? humidity;
  final String stylingSuggestion;
  final bool isForecastAvailable;
  final String? message;

  const WeatherContext({
    required this.location,
    required this.date,
    required this.temperatureC,
    this.feelsLikeC,
    required this.conditionCode,
    required this.conditionText,
    this.rainProbability = 0,
    this.windKph,
    this.humidity,
    required this.stylingSuggestion,
    this.isForecastAvailable = true,
    this.message,
  });

  bool get isRainExpected => rainProbability >= 40 || conditionCode.contains('RAIN');

  String get temperatureDisplay => '${temperatureC.toStringAsFixed(1)}°C';
}

