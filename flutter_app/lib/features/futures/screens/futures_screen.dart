import 'package:flutter/material.dart';
import '../../../core/models/prediction_model.dart';
import '../../../core/services/simulation_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/tess_card.dart';
import '../../../shared/widgets/tess_button.dart';
import '../widgets/future_branch_card.dart';

/// FuturesScreen demonstrates Module 4: Asynchronous Programming in Flutter:
/// - FutureBuilder<List<Prediction>> for managing asynchronous UI rendering
/// - Explicit handling of Loading, Error, and Success states
/// - Refreshing and triggering Futures on user action
class FuturesScreen extends StatefulWidget {
  const FuturesScreen({super.key});

  @override
  State<FuturesScreen> createState() => _FuturesScreenState();
}

class _FuturesScreenState extends State<FuturesScreen> {
  final SimulationService _simulationService = SimulationService();
  late Future<List<Prediction>> _predictionsFuture;

  @override
  void initState() {
    super.initState();
    // Initialize the asynchronous Future when the widget is mounted
    _loadPredictions();
  }

  void _loadPredictions() {
    setState(() {
      _predictionsFuture = _simulationService.fetchPredictions();
    });
  }

  void _toggleSimulatedError() {
    setState(() {
      SimulationService.shouldSimulateError = !SimulationService.shouldSimulateError;
      _loadPredictions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'FUTURE SIMULATION ENGINE',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.cyan),
            tooltip: 'Recalculate Projections',
            onPressed: _loadPredictions,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Engine Status Card
            TessCard(
              gradient: LinearGradient(
                colors: [
                  AppColors.bgElevated,
                  AppColors.violet.withValues(alpha: 0.15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderColor: AppColors.violet.withValues(alpha: 0.4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.psychology, color: AppColors.violetLight, size: 22),
                      const SizedBox(width: 8),
                      const Text(
                        'Simulation Horizon: 72 Hours',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                        ),
                        child: const Text(
                          'CONVERGING',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'TESS computes projected timelines based on your current focus trajectory, ongoing tasks, and scheduled meetings.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section Header
            Row(
              children: [
                const Icon(Icons.fork_right_rounded, color: AppColors.cyan, size: 18),
                const SizedBox(width: 6),
                const Text(
                  'BRANCHED TRAJECTORIES',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: AppColors.textPrimary,
                    fontFamily: 'monospace',
                  ),
                ),
                const Spacer(),
                // Debug toggle button to demonstrate error handling in FutureBuilder
                InkWell(
                  onTap: _toggleSimulatedError,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: SimulationService.shouldSimulateError
                          ? AppColors.danger.withValues(alpha: 0.2)
                          : AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: SimulationService.shouldSimulateError
                            ? AppColors.danger
                            : AppColors.border,
                      ),
                    ),
                    child: Text(
                      SimulationService.shouldSimulateError ? 'Simulating Error' : 'Normal Mode',
                      style: TextStyle(
                        fontSize: 10,
                        color: SimulationService.shouldSimulateError
                            ? AppColors.danger
                            : AppColors.textMuted,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // FutureBuilder: Asynchronously resolves _predictionsFuture
            FutureBuilder<List<Prediction>>(
              future: _predictionsFuture,
              builder: (context, snapshot) {
                // 1. Loading State
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 40.0),
                    child: const Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.cyan),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Synthesizing quantum trajectories...',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // 2. Error State
                if (snapshot.hasError) {
                  return TessCard(
                    borderColor: AppColors.danger.withValues(alpha: 0.5),
                    child: Column(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: AppColors.danger, size: 36),
                        const SizedBox(height: 12),
                        const Text(
                          'Simulation Computation Failed',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          snapshot.error.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TessButton(
                          label: 'Retry Computation',
                          icon: Icons.refresh,
                          variant: TessButtonVariant.cyan,
                          onPressed: _loadPredictions,
                        ),
                      ],
                    ),
                  );
                }

                // 3. Success State with Data
                final predictions = snapshot.data ?? [];
                if (predictions.isEmpty) {
                  return const Center(
                    child: Text('No projections available.'),
                  );
                }

                return Column(
                  children: predictions.map((prediction) {
                    BranchTrajectory trajectory;
                    switch (prediction.trajectory) {
                      case TrajectoryType.optimal:
                        trajectory = BranchTrajectory.positive;
                      case TrajectoryType.risk:
                        trajectory = BranchTrajectory.warning;
                      case TrajectoryType.nominal:
                        trajectory = BranchTrajectory.neutral;
                    }

                    return FutureBranchCard(
                      title: prediction.title,
                      description: prediction.description,
                      probability: prediction.formattedProbability,
                      projectedOutcome: prediction.projectedOutcome,
                      trajectory: trajectory,
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
