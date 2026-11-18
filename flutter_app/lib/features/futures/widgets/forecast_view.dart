import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/forecast_model.dart';
import '../services/future_service.dart';

/// Long-Term Forecasting View (30d, 90d, 365d) with backlog and burnout risk telemetry
class ForecastView extends StatefulWidget {
  final FutureService futureService;

  const ForecastView({super.key, required this.futureService});

  @override
  State<ForecastView> createState() => _ForecastViewState();
}

class _ForecastViewState extends State<ForecastView> {
  String _selectedHorizon = '30d';
  LongTermForecastModel? _forecast;
  bool _isLoading = true;
  String? _errorMessage;

  final List<String> _horizons = ['30d', '90d', '365d'];

  @override
  void initState() {
    super.initState();
    _loadForecast();
  }

  Future<void> _loadForecast() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await widget.futureService.getForecast(_selectedHorizon);
      if (mounted) {
        setState(() {
          _forecast = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final chipBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Horizon Selector Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8.0),
          child: Row(
            children: [
              Text(
                'FORECAST HORIZON:',
                style: TextStyle(
                  fontSize: 11.0,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: textMuted,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              ..._horizons.map((h) {
                final isSelected = _selectedHorizon == h;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(h.toUpperCase()),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected && _selectedHorizon != h) {
                        setState(() => _selectedHorizon = h);
                        _loadForecast();
                      }
                    },
                    labelStyle: TextStyle(
                      fontSize: 11.0,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                    ),
                    selectedColor: AppColors.tessTeal,
                    backgroundColor: chipBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.pill,
                      side: BorderSide(
                        color: isSelected ? AppColors.tessTeal : borderColor,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),

        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(48.0),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.tessTeal),
            ),
          )
        else if (_errorMessage != null)
          _buildErrorCard(isDark)
        else if (_forecast != null)
          _buildForecastContent(_forecast!, isDark),
      ],
    );
  }

  Widget _buildForecastContent(LongTermForecastModel forecast, bool isDark) {
    final burnoutColor = forecast.isHighBurnoutRisk ? AppColors.accentDanger : AppColors.accentSuccess;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Metrics Matrix
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: AppRadius.card,
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.03),
                  blurRadius: 8.0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetricTile(
                      'PROJECTED BACKLOG',
                      '${forecast.projectedBacklog} items',
                      AppColors.tessTeal,
                      textMuted,
                    ),
                    Container(width: 1.0, height: 36.0, color: borderColor),
                    _buildMetricTile(
                      'COMPLETION FORECAST',
                      '${forecast.completionForecast} items',
                      AppColors.vibrantMint,
                      textMuted,
                    ),
                    Container(width: 1.0, height: 36.0, color: borderColor),
                    _buildMetricTile(
                      'BURNOUT RISK',
                      '${forecast.burnoutRiskPercentage.toInt()}%',
                      burnoutColor,
                      textMuted,
                    ),
                  ],
                ),
                if (forecast.uncertaintyRange.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Divider(color: borderColor, height: 1.0),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'UNCERTAINTY RANGE:',
                        style: TextStyle(
                          fontSize: 10.0,
                          fontWeight: FontWeight.bold,
                          color: textMuted,
                        ),
                      ),
                      Text(
                        'Min: ${forecast.uncertaintyRange['min']?.toInt() ?? 0}  •  Max: ${forecast.uncertaintyRange['max']?.toInt() ?? 0}',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Explanation Card
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: AppRadius.card,
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.03),
                  blurRadius: 8.0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'EXPLAINABLE PROJECTION',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: AppColors.tessTeal,
                      ),
                    ),
                    Text(
                      'CONFIDENCE: ${forecast.confidence}',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: textMuted,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  forecast.explanation.isNotEmpty
                      ? forecast.explanation
                      : 'Projections are derived from recent task velocity and historical patterns.',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 13.5,
                    height: 1.4,
                  ),
                ),
                if (forecast.assumptions.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'CORE ASSUMPTIONS:',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  ...forecast.assumptions.map(
                    (a) => Padding(
                      padding: const EdgeInsets.only(bottom: 2.0),
                      child: Text(
                        '• $a',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 12.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, Color color, Color mutedColor) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          label,
          style: TextStyle(
            color: mutedColor,
            fontSize: 9.0,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorCard(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.accentDanger.withOpacity(0.1),
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.accentDanger.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Forecast Generation Anomaly',
            style: TextStyle(color: AppColors.accentDanger, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4.0),
          Text(
            _errorMessage ?? 'Unable to compute forecast model',
            style: TextStyle(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 8.0),
          TextButton(
            onPressed: _loadForecast,
            child: const Text('Retry Computation', style: TextStyle(color: AppColors.tessTeal)),
          ),
        ],
      ),
    );
  }
}
