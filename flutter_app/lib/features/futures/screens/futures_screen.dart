import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../home/widgets/mascot_widget.dart';
import '../../interventions/screens/interventions_screen.dart';
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mascotState = _resolvedMascotState;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FUTURE SIMULATION ENGINE',
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            Text(
              'Predictive intelligence & scenarios',
              style: TextStyle(
                fontSize: 11.0,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bolt_rounded, color: AppColors.accentWarning),
            tooltip: 'Proactive Interventions',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const InterventionsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.tessTeal),
            tooltip: 'Recalculate Projections',
            onPressed: _loadPredictions,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPredictions,
        color: AppColors.tessTeal,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 40.0),
          children: [
            // Mascot Telemetry Card
            _buildMascotHeader(mascotState, isDark),
            const SizedBox(height: AppSpacing.sm),

            // Tab Bar
            _buildTabBar(isDark),
            const SizedBox(height: AppSpacing.md),

            // Error banner if any
            if (_errorMessage != null) _buildErrorBanner(),

            // Active Tab Content
            _buildActiveTabContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildMascotHeader(MascotState state, bool isDark) {
    Color accent = AppColors.tessTeal;
    if (state == MascotState.attention || state == MascotState.error) accent = AppColors.accentDanger;
    if (state == MascotState.happy) accent = AppColors.accentSuccess;
    if (state == MascotState.thinking) accent = AppColors.vibrantMint;

    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8.0),
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
      child: Row(
        children: [
          MascotWidget(
            state: state,
            size: 42.0,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'COMPANION FORECAST STATUS',
                  style: TextStyle(
                    fontSize: 10.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
                const SizedBox(height: 3.0),
                Text(
                  _mascotStatusText,
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isDark) {
    final chipBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
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
                fontSize: 12.0,
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
          child: CircularProgressIndicator(color: AppColors.tessTeal),
        ),
      );
    }

    if (_predictions.isEmpty) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              const Icon(Icons.shield_outlined, color: AppColors.tessTeal, size: 40.0),
              const SizedBox(height: 12.0),
              Text(
                'Trajectories Nominal',
                style: TextStyle(
                  fontSize: 15.0,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 6.0),
              Text(
                'No critical future risks or anomalies currently projected across your work packages.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  fontSize: 13.0,
                ),
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
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: AppColors.accentDanger.withOpacity(0.1),
        borderRadius: AppRadius.sm,
        border: Border.all(color: AppColors.accentDanger.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.accentDanger, size: 18.0),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              _errorMessage ?? 'Prediction calculation error',
              style: const TextStyle(color: AppColors.accentDanger, fontSize: 12.0),
            ),
          ),
          TextButton(
            onPressed: _loadPredictions,
            child: const Text('Retry', style: TextStyle(color: AppColors.accentDanger)),
          ),
        ],
      ),
    );
  }
}
