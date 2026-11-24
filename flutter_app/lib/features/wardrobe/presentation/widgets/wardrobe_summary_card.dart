import 'package:flutter/material.dart';
import '../../../../shared/widgets/tess_card.dart';
import '../theme/wardrobe_theme.dart';

/// Telemetry metric card summarizing Wardrobe status.
class WardrobeSummaryCard extends StatelessWidget {
  final int totalCount;
  final int cleanCount;
  final int inLaundryCount;
  final int unassignedCount;
  final VoidCallback? onExplore;

  const WardrobeSummaryCard({
    super.key,
    required this.totalCount,
    required this.cleanCount,
    required this.inLaundryCount,
    required this.unassignedCount,
    this.onExplore,
  });

  @override
  Widget build(BuildContext context) {
    return TessCard(
      backgroundColor: WardrobeTheme.spatialSurface,
      borderColor: WardrobeTheme.borderViolet,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 16,
                    color: WardrobeTheme.softViolet,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'WARDROBE TELEMETRY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: WardrobeTheme.textMuted,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              if (onExplore != null)
                GestureDetector(
                  onTap: onExplore,
                  child: Text(
                    'Explore All →',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: WardrobeTheme.electricCyan,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  label: 'TOTAL',
                  value: totalCount.toString(),
                  color: WardrobeTheme.electricViolet,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  label: 'CLEAN',
                  value: cleanCount.toString(),
                  color: WardrobeTheme.statusSuccess,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  label: 'IN LAUNDRY',
                  value: inLaundryCount.toString(),
                  color: WardrobeTheme.electricCyan,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  label: 'UNSET',
                  value: unassignedCount.toString(),
                  color: WardrobeTheme.statusWarning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: WardrobeTheme.textMuted,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}
