import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Horizon Selector Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              const Text(
                'FORECAST HORIZON:',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11.0,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 12.0),
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
                      fontFamily: 'monospace',
                      fontSize: 11.0,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                    selectedColor: AppColors.violet,
                    backgroundColor: AppColors.bgSurface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      side: BorderSide(
                        color: isSelected ? AppColors.violet : AppColors.border,
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
              child: CircularProgressIndicator(color: AppColors.cyan),
            ),
          )
        else if (_errorMessage != null)
          _buildErrorCard()
        else if (_forecast != null)
          _buildForecastContent(_forecast!),
      ],
    );
  }

  Widget _buildForecastContent(LongTermForecastModel forecast) {
    final burnoutColor = forecast.isHighBurnoutRisk ? AppColors.danger : AppColors.success;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Metrics Matrix
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetricTile(
                      'PROJECTED BACKLOG',
                      '${forecast.projectedBacklog} items',
                      AppColors.cyan,
                    ),
                    Container(width: 1.0, height: 36.0, color: AppColors.border),
                    _buildMetricTile(
                      'COMPLETION FORECAST',
                      '${forecast.completionForecast} items',
                      AppColors.violetLight,
                    ),
                    Container(width: 1.0, height: 36.0, color: AppColors.border),
                    _buildMetricTile(
                      'BURNOUT RISK',
                      '${forecast.burnoutRiskPercentage.toInt()}%',
                      burnoutColor,
                    ),
                  ],
                ),
                if (forecast.uncertaintyRange.isNotEmpty) ...[
                  const SizedBox(height: 16.0),
                  const Divider(color: AppColors.border, height: 1.0),
                  const SizedBox(height: 12.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'UNCERTAINTY RANGE:',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10.0,
                          color: AppColors.textMuted,
                        ),
                      ),
                      Text(
                        'Min: ${forecast.uncertaintyRange['min']?.toInt() ?? 0}  •  Max: ${forecast.uncertaintyRange['max']?.toInt() ?? 0}',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11.0,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12.0),

          // Explanation Card
          Container(
            padding: const EdgeInsets.all(14.0),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: AppColors.border),
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
                        fontFamily: 'monospace',
                        fontSize: 11.0,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: AppColors.cyan,
                      ),
                    ),
                    Text(
                      'CONFIDENCE: ${forecast.confidence}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10.0,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                Text(
                  forecast.explanation.isNotEmpty
                      ? forecast.explanation
                      : 'Projections are derived from recent task velocity and historical patterns.',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13.0,
                    height: 1.4,
                  ),
                ),
                if (forecast.assumptions.isNotEmpty) ...[
                  const SizedBox(height: 12.0),
                  const Text(
                    'CORE ASSUMPTIONS:',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10.0,
                      color: AppColors.textMuted,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  ...forecast.assumptions.map(
                    (a) => Padding(
                      padding: const EdgeInsets.only(bottom: 2.0),
                      child: Text(
                        '• $a',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11.5,
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

  Widget _buildMetricTile(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 9.0,
            fontFamily: 'monospace',
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorCard() {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: AppColors.danger.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Forecast Generation Anomaly',
            style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4.0),
          Text(
            _errorMessage ?? 'Unable to compute forecast model',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.0),
          ),
          const SizedBox(height: 8.0),
          TextButton(
            onPressed: _loadForecast,
            child: const Text('Retry Computation', style: TextStyle(color: AppColors.cyan)),
          ),
        ],
      ),
    );
  }
}
