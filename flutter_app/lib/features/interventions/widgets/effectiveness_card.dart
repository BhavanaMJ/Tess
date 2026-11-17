import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/intervention_effectiveness_model.dart';
import '../services/intervention_service.dart';

/// Historical Intervention Effectiveness and Action Conversion Telemetry View
class EffectivenessCard extends StatefulWidget {
  final InterventionService interventionService;

  const EffectivenessCard({super.key, required this.interventionService});

  @override
  State<EffectivenessCard> createState() => _EffectivenessCardState();
}

class _EffectivenessCardState extends State<EffectivenessCard> {
  InterventionEffectivenessModel? _effectiveness;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEffectiveness();
  }

  Future<void> _loadEffectiveness() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await widget.interventionService.getEffectiveness();
      if (mounted) {
        setState(() {
          _effectiveness = res;
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
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: AppColors.danger.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: AppColors.danger.withOpacity(0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Effectiveness Metrics Error', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4.0),
              Text(_errorMessage!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5)),
              TextButton(
                onPressed: _loadEffectiveness,
                child: const Text('Retry', style: TextStyle(color: AppColors.cyan)),
              ),
            ],
          ),
        ),
      );
    }

    if (_effectiveness == null) return const SizedBox.shrink();

    final eff = _effectiveness!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Conversion Metrics Matrix
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatTile(
                  'TOTAL TRIGGERED',
                  '${eff.totalInterventions}',
                  AppColors.cyan,
                ),
                Container(width: 1.0, height: 36.0, color: AppColors.border),
                _buildStatTile(
                  'ACCEPTANCE RATE',
                  '${eff.acceptanceRatePercentage.toInt()}%',
                  AppColors.success,
                ),
                Container(width: 1.0, height: 36.0, color: AppColors.border),
                _buildStatTile(
                  'CONVERSION RATE',
                  '${eff.actionConversionRatePercentage.toInt()}%',
                  AppColors.violetLight,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12.0),

          // Action counts breakdown
          Container(
            padding: const EdgeInsets.all(14.0),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniBadge('Accepted', eff.acceptedCount, AppColors.success),
                _buildMiniBadge('Completed', eff.actionsCompletedCount, AppColors.cyan),
                _buildMiniBadge('Dismissed', eff.dismissedCount, AppColors.textMuted),
              ],
            ),
          ),
          const SizedBox(height: 12.0),

          // Insights & Learnings
          if (eff.insights.isNotEmpty) ...[
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
                  const Text(
                    'EMPIRICAL EFFECTIVENESS OBSERVATIONS:',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: AppColors.cyan,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  ...eff.insights.map(
                    (insight) => Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(color: AppColors.cyan, fontSize: 12.0)),
                          Expanded(
                            child: Text(
                              insight,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12.0,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatTile(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 8.5,
            fontFamily: 'monospace',
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniBadge(String label, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8.0,
          height: 8.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 6.0),
        Text(
          '$label: $count',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}
