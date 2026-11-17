import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../home/widgets/mascot_widget.dart';
import '../models/future_prediction_model.dart';
import '../services/future_service.dart';
import '../widgets/accuracy_metrics_view.dart';
import '../widgets/counterfactual_simulator.dart';
import '../widgets/forecast_view.dart';
import '../widgets/multiple_futures_view.dart';
import '../widgets/trajectory_card.dart';

/// FuturesScreen: Personal Future Simulator
/// Seamlessly integrates:
/// - Current Trajectory & Active Predictions
/// - Long-Term Forecasting (30d, 90d, 365d)
/// - Multiple Futures (Current, Improved, Alternative)
/// - Counterfactual Simulations
/// - Empirical Prediction Accuracy & Brier Calibration
class FuturesScreen extends StatefulWidget {
  final FutureService? futureService;

  const FuturesScreen({super.key, this.futureService});

  @override
  State<FuturesScreen> createState() => _FuturesScreenState();
}

class _FuturesScreenState extends State<FuturesScreen> {
  late final FutureService _futureService;
  List<FuturePredictionModel> _predictions = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedTab = 0; // 0: Trajectory, 1: Forecast, 2: Multiple Selves, 3: What If?, 4: Accuracy

  final List<String> _tabs = [
    'TRAJECTORY',
    'FORECAST',
    'MULTIPLE SELVES',
    'WHAT IF?',
    'ACCURACY',
  ];

  @override
  void initState() {
    super.initState();
    _futureService = widget.futureService ?? FutureService();
    _loadPredictions();
  }

  Future<void> _loadPredictions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await _futureService.getPredictions();
      if (!mounted) return;

      setState(() {
        _predictions = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  MascotState get _resolvedMascotState {
    if (_isLoading) return MascotState.thinking;
    if (_errorMessage != null) return MascotState.error;
    if (_predictions.any((p) => p.isRisk)) return MascotState.attention;
    if (_predictions.any((p) => p.isPositive)) return MascotState.happy;
    return MascotState.idle;
  }

  String get _mascotStatusText {
    switch (_resolvedMascotState) {
      case MascotState.thinking:
        return 'RECALCULATING CONVERGENCE VECTORS...';
      case MascotState.attention:
        return 'CRITICAL CONVERGENCE RISKS DETECTED';
      case MascotState.happy:
        return 'OPTIMAL TRAJECTORY IDENTIFIED';
      case MascotState.error:
        return 'SIMULATION SENSOR ERROR';
      default:
        return 'TRAJECTORIES SYNCHRONIZED // NOMINAL';
    }
  }

  @override
  Widget build(BuildContext context) {
    final mascotState = _resolvedMascotState;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FUTURE SIMULATION ENGINE',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: AppColors.cyan,
              ),
            ),
            Text(
              'Predictive Intelligence // Probabilistic Simulator',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10.0,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.cyan),
            tooltip: 'Recalculate Projections',
            onPressed: _loadPredictions,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPredictions,
        color: AppColors.cyan,
        backgroundColor: AppColors.bgSecondary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 40.0),
          children: [
            // Mascot Emotional Telemetry Card
            _buildMascotHeader(mascotState),
            const SizedBox(height: 12.0),

            // Tab Bar
            _buildTabBar(),
            const SizedBox(height: 14.0),

            // Error banner if any
            if (_errorMessage != null) _buildErrorBanner(),

            // Active Tab Content
            _buildActiveTabContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildMascotHeader(MascotState state) {
    Color color = AppColors.cyan;
    if (state == MascotState.attention || state == MascotState.error) color = AppColors.danger;
    if (state == MascotState.happy) color = AppColors.success;
    if (state == MascotState.thinking) color = AppColors.violetLight;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: color.withOpacity(0.35), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 10.0,
          ),
        ],
      ),
      child: Row(
        children: [
          MascotWidget(
            state: state,
            size: 44.0,
          ),
          const SizedBox(width: 14.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SIMULATION ENGINE STATUS',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 3.0),
                Text(
                  _mascotStatusText,
                  style: TextStyle(
                    color: color,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    fontSize: 11.5,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: _tabs.asMap().entries.map((entry) {
          final idx = entry.key;
          final title = entry.value;
          final isSelected = _selectedTab == idx;

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(title),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _selectedTab = idx);
              },
              labelStyle: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10.5,
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
        }).toList(),
      ),
    );
  }

  Widget _buildActiveTabContent() {
    switch (_selectedTab) {
      case 1:
        return ForecastView(futureService: _futureService);
      case 2:
        return MultipleFuturesView(futureService: _futureService);
      case 3:
        return CounterfactualSimulator(futureService: _futureService);
      case 4:
        return AccuracyMetricsView(futureService: _futureService);
      default:
        return _buildTrajectoryContent();
    }
  }

  Widget _buildTrajectoryContent() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(48.0),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.cyan),
        ),
      );
    }

    if (_predictions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(Icons.shield_outlined, color: AppColors.cyan, size: 40.0),
              SizedBox(height: 12.0),
              Text(
                'Trajectories Nominal',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14.0,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 6.0),
              Text(
                'No critical future risks or anomalies currently projected across your work packages.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _predictions.map((p) => TrajectoryCard(prediction: p)).toList(),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: AppColors.danger.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 18.0),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              _errorMessage ?? 'Prediction calculation error',
              style: const TextStyle(color: AppColors.danger, fontSize: 11.5),
            ),
          ),
          TextButton(
            onPressed: _loadPredictions,
            child: const Text('Retry', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}
