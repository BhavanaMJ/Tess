import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/simulation_model.dart';
import '../services/future_service.dart';

/// Counterfactual "What-If" Simulation Explorer
class CounterfactualSimulator extends StatefulWidget {
  final FutureService futureService;

  const CounterfactualSimulator({super.key, required this.futureService});

  @override
  State<CounterfactualSimulator> createState() => _CounterfactualSimulatorState();
}

class _CounterfactualSimulatorState extends State<CounterfactualSimulator> {
  String _selectedHorizon = '24h';
  SimulationResponseModel? _simulation;
  bool _isSimulating = false;
  String? _errorMessage;

  final List<String> _horizons = ['24h', '48h', '72h'];

  @override
  void initState() {
    super.initState();
    _runSimulation();
  }

  Future<void> _runSimulation() async {
    setState(() {
      _isSimulating = true;
      _errorMessage = null;
    });

    try {
      final res = await widget.futureService.simulateFuture(_selectedHorizon);
      if (mounted) {
        setState(() {
          _simulation = res;
          _isSimulating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isSimulating = false;
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Horizon Control
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'COUNTERFACTUAL HORIZON:',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: textMuted,
                ),
              ),
              Row(
                children: _horizons.map((h) {
                  final isSelected = _selectedHorizon == h;
                  return Padding(
                    padding: const EdgeInsets.only(left: 6.0),
                    child: InkWell(
                      onTap: () {
                        if (_selectedHorizon != h) {
                          setState(() => _selectedHorizon = h);
                          _runSimulation();
                        }
                      },
                      borderRadius: AppRadius.pill,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.tessTeal : chipBg,
                          borderRadius: AppRadius.pill,
                          border: Border.all(
                            color: isSelected ? AppColors.tessTeal : borderColor,
                          ),
                        ),
                        child: Text(
                          h.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11.0,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          if (_isSimulating)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.tessTeal),
              ),
            )
          else if (_errorMessage != null)
            _buildErrorState(isDark)
          else if (_simulation != null)
            _buildSimulationContent(_simulation!, isDark),
        ],
      ),
    );
  }

  Widget _buildSimulationContent(SimulationResponseModel sim, bool isDark) {
    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Scenario Overview
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
                  Text(
                    sim.scenario.title,
                    style: TextStyle(
                      color: textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15.0,
                    ),
                  ),
                  Text(
                    'CONF: ${sim.scenario.confidence}',
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.tessTeal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6.0),
              Text(
                sim.scenario.summary,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 13.0,
                  height: 1.4,
                ),
              ),
              if (sim.scenario.events.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Divider(color: borderColor, height: 1.0),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'EVENT CHAIN (SIMULATION):',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6.0),
                ...sim.scenario.events.map(
                  (ev) => Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '[${ev.relativeTime}] ',
                          style: const TextStyle(
                            color: AppColors.vibrantMint,
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${ev.title}: ${ev.description}',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 12.0,
                            ),
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

        // Counterfactual Path (Alternative Action)
        if (sim.alternative != null) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.tessTeal.withOpacity(0.08),
              borderRadius: AppRadius.card,
              border: Border.all(color: AppColors.tessTeal.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.alt_route_rounded, color: AppColors.tessTeal, size: 18.0),
                    SizedBox(width: AppSpacing.xs),
                    Text(
                      'COUNTERFACTUAL LEVER (ONE CHANGE)',
                      style: TextStyle(
                        fontSize: 11.0,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: AppColors.tessTeal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  sim.alternative!.action,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  'Assumption: ${sim.alternative!.assumption}',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 12.0,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  'Expected Effect: ${sim.alternative!.expectedEffect}',
                  style: const TextStyle(
                    color: AppColors.accentSuccess,
                    fontSize: 12.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.accentDanger.withOpacity(0.1),
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.accentDanger.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Simulation Computation Error', style: TextStyle(color: AppColors.accentDanger, fontSize: 12.0, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4.0),
          Text(_errorMessage!, style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, fontSize: 11.0)),
          TextButton(
            onPressed: _runSimulation,
            child: const Text('Retry Simulation', style: TextStyle(color: AppColors.tessTeal)),
          ),
        ],
      ),
    );
  }
}
