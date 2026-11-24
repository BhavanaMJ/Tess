import 'package:flutter/material.dart';
import '../../domain/entities/weather_context.dart';
import '../theme/wardrobe_theme.dart';

class WeatherContextCard extends StatelessWidget {
  final WeatherContext? weather;
  final VoidCallback? onTap;

  const WeatherContextCard({
    super.key,
    this.weather,
    this.onTap,
  });

  IconData _getWeatherIcon(String code) {
    switch (code.toUpperCase()) {
      case 'CLEAR':
      case 'MAINLY_CLEAR':
        return Icons.wb_sunny_rounded;
      case 'PARTLY_CLOUDY':
        return Icons.cloud_queue_rounded;
      case 'OVERCAST':
        return Icons.cloud_rounded;
      case 'RAIN':
      case 'RAIN_SHOWERS':
      case 'HEAVY_RAIN':
      case 'DRIZZLE':
        return Icons.grain_rounded;
      case 'THUNDERSTORM':
        return Icons.flash_on_rounded;
      case 'SNOW':
        return Icons.ac_unit_rounded;
      case 'FOG':
        return Icons.blur_on_rounded;
      default:
        return Icons.thermostat_rounded;
    }
  }

  Color _getWeatherColor(String code) {
    if (code.contains('RAIN') || code.contains('DRIZZLE')) {
      return WardrobeTheme.electricCyan;
    }
    if (code.contains('CLEAR')) {
      return WardrobeTheme.statusWarning;
    }
    return WardrobeTheme.softViolet;
  }

  @override
  Widget build(BuildContext context) {
    if (weather == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: WardrobeTheme.spatialSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: WardrobeTheme.border),
        ),
        child: Row(
          children: [
            Icon(
              Icons.cloud_sync_rounded,
              color: WardrobeTheme.softViolet,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'Loading weather context...',
              style: TextStyle(color: WardrobeTheme.textMuted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    final w = weather!;
    final isAvailable = w.isForecastAvailable;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WardrobeTheme.spatialSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAvailable ? WardrobeTheme.borderViolet : WardrobeTheme.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isAvailable
                      ? _getWeatherColor(w.conditionCode).withOpacity(0.15)
                      : WardrobeTheme.railBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isAvailable ? _getWeatherIcon(w.conditionCode) : Icons.cloud_off_rounded,
                  color: isAvailable
                      ? _getWeatherColor(w.conditionCode)
                      : WardrobeTheme.textMuted,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          isAvailable ? w.conditionText : 'Weather Forecast Unavailable',
                          style: TextStyle(
                            color: WardrobeTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        if (isAvailable && w.isRainExpected) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: WardrobeTheme.electricCyan.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.umbrella_rounded, size: 10, color: WardrobeTheme.electricCyan),
                                const SizedBox(width: 4),
                                Text(
                                  '${w.rainProbability}%',
                                  style: TextStyle(
                                    color: WardrobeTheme.electricCyan,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isAvailable ? '${w.temperatureDisplay} • ${w.location}' : w.date,
                      style: TextStyle(
                        color: WardrobeTheme.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (isAvailable && w.feelsLikeC != null)
                Text(
                  'Feels ${w.feelsLikeC!.toStringAsFixed(0)}°',
                  style: TextStyle(
                    color: WardrobeTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: WardrobeTheme.railBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 14,
                  color: WardrobeTheme.softViolet,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    w.stylingSuggestion,
                    style: TextStyle(
                      color: WardrobeTheme.textSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
