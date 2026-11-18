import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
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
              const Text('Effectiveness Metrics Error', style: TextStyle(color: AppColors.accentDanger, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4.0),
              Text(_errorMessage!, style: TextStyle(color: textSecondary, fontSize: 12.0)),
              TextButton(
                onPressed: _loadEffectiveness,
                child: const Text('Retry', style: TextStyle(color: AppColors.tessTeal)),
              ),
            ],
          ),
        ),
      );
    }

    if (_effectiveness == null) return const SizedBox.shrink();

    final eff = _effectiveness!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Conversion Metrics Matrix
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatTile(
                  'TOTAL TRIGGERED',
                  '${eff.totalInterventions}',
                  AppColors.tessTeal,
                  textMuted,
                ),
                Container(width: 1.0, height: 36.0, color: borderColor),
                _buildStatTile(
                  'ACCEPTANCE RATE',
                  '${eff.acceptanceRatePercentage.toInt()}%',
                  AppColors.accentSuccess,
                  textMuted,
                ),
                Container(width: 1.0, height: 36.0, color: borderColor),
                _buildStatTile(
                  'CONVERSION RATE',
                  '${eff.actionConversionRatePercentage.toInt()}%',
                  AppColors.vibrantMint,
                  textMuted,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Action counts breakdown
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: AppRadius.card,
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniBadge('Accepted', eff.acceptedCount, AppColors.accentSuccess, textSecondary),
                _buildMiniBadge('Completed', eff.actionsCompletedCount, AppColors.tessTeal, textSecondary),
                _buildMiniBadge('Dismissed', eff.dismissedCount, textMuted, textSecondary),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Insights & Learnings
          if (eff.insights.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: AppRadius.card,
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'EMPIRICAL EFFECTIVENESS OBSERVATIONS',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: AppColors.tessTeal,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...eff.insights.map(
                    (insight) => Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(color: AppColors.tessTeal, fontSize: 13.0)),
                          Expanded(
                            child: Text(
                              insight,
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 12.5,
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

  Widget _buildStatTile(String label, String value, Color color, Color mutedColor) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          label,
          style: TextStyle(
            color: mutedColor,
            fontSize: 8.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniBadge(String label, int count, Color dotColor, Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8.0,
          height: 8.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: dotColor,
          ),
        ),
        const SizedBox(width: 6.0),
        Text(
          '$label: $count',
          style: TextStyle(
            color: textColor,
            fontSize: 12.0,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
