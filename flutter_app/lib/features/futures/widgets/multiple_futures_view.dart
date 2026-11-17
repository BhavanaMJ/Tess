import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
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
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(48.0),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.cyan),
        ),
      );
    }

    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
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
                'Multiple Futures Anomaly',
                style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4.0),
              Text(
                _errorMessage!,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.0),
              ),
              const SizedBox(height: 8.0),
              TextButton(
                onPressed: _loadScenarios,
                child: const Text('Retry Scenarios', style: TextStyle(color: AppColors.cyan)),
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
        activeColor = AppColors.success;
        break;
      case 2:
        activeScenario = scenarios.alternativeTrajectory;
        activeColor = AppColors.cyan;
        break;
      default:
        activeScenario = scenarios.currentTrajectory;
        activeColor = AppColors.warning;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Segmented Comparative Selector
          Container(
            padding: const EdgeInsets.all(4.0),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                _buildSegmentButton('CURRENT', 0, AppColors.warning),
                _buildSegmentButton('IMPROVED', 1, AppColors.success),
                _buildSegmentButton('ALTERNATIVE', 2, AppColors.cyan),
              ],
            ),
          ),
          const SizedBox(height: 12.0),

          // Active Scenario Card
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: activeColor.withOpacity(0.4),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: activeColor.withOpacity(0.05),
                  blurRadius: 12.0,
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
                        color: activeColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6.0),
                        border: Border.all(color: activeColor.withOpacity(0.5)),
                      ),
                      child: Text(
                        activeScenario.trajectoryType,
                        style: TextStyle(
                          color: activeColor,
                          fontSize: 10.0,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    Text(
                      '${activeScenario.probabilityPercentage.toInt()}% Probability',
                      style: TextStyle(
                        color: activeColor,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 12.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10.0),
                Text(
                  activeScenario.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6.0),
                Text(
                  activeScenario.summary,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13.0,
                    height: 1.4,
                  ),
                ),
                if (activeScenario.events.isNotEmpty) ...[
                  const SizedBox(height: 16.0),
                  const Text(
                    'PROJECTED MILESTONE TIMELINE:',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10.0,
                      color: AppColors.textMuted,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8.0),
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
                              color: AppColors.bgSecondary,
                              borderRadius: BorderRadius.circular(4.0),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              ev.relativeTime,
                              style: TextStyle(
                                color: activeColor,
                                fontSize: 9.5,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ev.title,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (ev.description.isNotEmpty)
                                  Text(
                                    ev.description,
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 11.0,
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

  Widget _buildSegmentButton(String label, int index, Color color) {
    final isSelected = _selectedTab == index;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = index),
        borderRadius: BorderRadius.circular(8.0),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(8.0),
            border: isSelected ? Border.all(color: color.withOpacity(0.5)) : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11.0,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? color : AppColors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ),
    );
  }
}

