import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Horizon Control
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'COUNTERFACTUAL HORIZON:',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: AppColors.textMuted,
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
                      borderRadius: BorderRadius.circular(6.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.violet : AppColors.bgSurface,
                          borderRadius: BorderRadius.circular(6.0),
                          border: Border.all(
                            color: isSelected ? AppColors.violet : AppColors.border,
                          ),
                        ),
                        child: Text(
                          h.toUpperCase(),
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10.0,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 12.0),

          if (_isSimulating)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.cyan),
              ),
            )
          else if (_errorMessage != null)
            _buildErrorState()
          else if (_simulation != null)
            _buildSimulationContent(_simulation!),
        ],
      ),
    );
  }

  Widget _buildSimulationContent(SimulationResponseModel sim) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Scenario Overview
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
                  Text(
                    sim.scenario.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.0,
                    ),
                  ),
                  Text(
                    'CONF: ${sim.scenario.confidence}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10.0,
                      color: AppColors.cyan,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6.0),
              Text(
                sim.scenario.summary,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
              if (sim.scenario.events.isNotEmpty) ...[
                const SizedBox(height: 12.0),
                const Divider(color: AppColors.border, height: 1.0),
                const SizedBox(height: 10.0),
                const Text(
                  'EVENT CHAIN (SIMULATION):',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10.0,
                    color: AppColors.textMuted,
                    letterSpacing: 1.0,
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
                            color: AppColors.violetLight,
                            fontFamily: 'monospace',
                            fontSize: 11.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${ev.title}: ${ev.description}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11.5,
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
          const SizedBox(height: 12.0),
          Container(
            padding: const EdgeInsets.all(14.0),
            decoration: BoxDecoration(
              color: AppColors.cyan.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: AppColors.cyan.withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.alt_route_rounded, color: AppColors.cyan, size: 16.0),
                    SizedBox(width: 8.0),
                    Text(
                      'COUNTERFACTUAL LEVER (ONE CHANGE)',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: AppColors.cyan,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                Text(
                  sim.alternative!.action,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  'Assumption: ${sim.alternative!.assumption}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  'Expected Effect: ${sim.alternative!.expectedEffect}',
                  style: const TextStyle(
                    color: AppColors.success,
                    fontSize: 11.5,
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

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: AppColors.danger.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Simulation Computation Error', style: TextStyle(color: AppColors.danger, fontSize: 12.0, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4.0),
          Text(_errorMessage!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.0)),
          TextButton(
            onPressed: _runSimulation,
            child: const Text('Retry Simulation', style: TextStyle(color: AppColors.cyan)),
          ),
        ],
      ),
    );
  }
}
