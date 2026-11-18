import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/multiple_futures_model.dart';
import '../models/simulation_model.dart';
import '../services/future_service.dart';

/// Multiple Future Selves comparative viewer: CURRENT vs IMPROVED vs ALTERNATIVE
class MultipleFuturesView extends StatefulWidget {
  final FutureService futureService;

  const MultipleFuturesView({super.key, required this.futureService});

  @override
  State<MultipleFuturesView> createState() => _MultipleFuturesViewState();
}

class _MultipleFuturesViewState extends State<MultipleFuturesView> {
  MultipleFuturesModel? _scenarios;
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedTab = 0; // 0: CURRENT, 1: IMPROVED, 2: ALTERNATIVE

  @override
  void initState() {
    super.initState();
    _loadScenarios();
  }

  Future<void> _loadScenarios() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await widget.futureService.getMultipleScenarios(horizon: '30d');
      if (mounted) {
        setState(() {
          _scenarios = res;
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
    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(48.0),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.tessTeal),
        ),
      );
    }

    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Container(
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
                'Multiple Futures Anomaly',
                style: TextStyle(color: AppColors.accentDanger, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4.0),
              Text(
                _errorMessage!,
                style: TextStyle(color: textSecondary, fontSize: 12.0),
              ),
              const SizedBox(height: 8.0),
              TextButton(
                onPressed: _loadScenarios,
                child: const Text('Retry Scenarios', style: TextStyle(color: AppColors.tessTeal)),
              ),
            ],
          ),
        ),
      );
    }

    if (_scenarios == null) return const SizedBox.shrink();

    final scenarios = _scenarios!;
    final FutureScenarioModel activeScenario;
    final Color activeColor;

    switch (_selectedTab) {
      case 1:
        activeScenario = scenarios.improvedTrajectory;
        activeColor = AppColors.accentSuccess;
        break;
      case 2:
        activeScenario = scenarios.alternativeTrajectory;
        activeColor = AppColors.tessTeal;
        break;
      default:
        activeScenario = scenarios.currentTrajectory;
        activeColor = AppColors.accentWarning;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Segmented Comparative Selector
          Container(
            padding: const EdgeInsets.all(4.0),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: AppRadius.pill,
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                _buildSegmentButton('CURRENT', 0, AppColors.accentWarning, isDark),
                _buildSegmentButton('IMPROVED', 1, AppColors.accentSuccess, isDark),
                _buildSegmentButton('ALTERNATIVE', 2, AppColors.tessTeal, isDark),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Active Scenario Card
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: AppRadius.card,
              border: Border.all(
                color: activeColor.withOpacity(0.4),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.03),
                  blurRadius: 10.0,
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                      decoration: BoxDecoration(
                        color: activeColor.withOpacity(0.12),
                        borderRadius: AppRadius.xs,
                        border: Border.all(color: activeColor.withOpacity(0.35)),
                      ),
                      child: Text(
                        activeScenario.trajectoryType,
                        style: TextStyle(
                          color: activeColor,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    Text(
                      '${activeScenario.probabilityPercentage.toInt()}% Probability',
                      style: TextStyle(
                        color: activeColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  activeScenario.title,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6.0),
                Text(
                  activeScenario.summary,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 13.5,
                    height: 1.4,
                  ),
                ),
                if (activeScenario.events.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'PROJECTED MILESTONE TIMELINE:',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...activeScenario.events.map(
                    (ev) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6.0,
                              vertical: 2.0,
                            ),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSecondary,
                              borderRadius: AppRadius.xs,
                              border: Border.all(color: borderColor),
                            ),
                            child: Text(
                              ev.relativeTime,
                              style: TextStyle(
                                color: activeColor,
                                fontSize: 10.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ev.title,
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (ev.description.isNotEmpty)
                                  Text(
                                    ev.description,
                                    style: TextStyle(
                                      color: textMuted,
                                      fontSize: 11.5,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
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

  Widget _buildSegmentButton(String label, int index, Color color, bool isDark) {
    final isSelected = _selectedTab == index;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = index),
        borderRadius: AppRadius.pill,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
            borderRadius: AppRadius.pill,
            border: isSelected ? Border.all(color: color.withOpacity(0.5)) : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.0,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected
                  ? color
                  : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
