import 'package:flutter/material.dart';
import '../../domain/entities/wardrobe_insights.dart';
import '../theme/wardrobe_theme.dart';

class ColourDistributionChart extends StatelessWidget {
  final List<ColourDistribution> distribution;

  const ColourDistributionChart({
    super.key,
    required this.distribution,
  });

  Color _resolveColorGroup(String group) {
    switch (group) {
      case 'Black':
        return Colors.black;
      case 'White':
        return Colors.white;
      case 'Blue':
        return const Color(0xFF2563EB);
      case 'Grey':
        return const Color(0xFF94A3B8);
      case 'Brown / Beige':
        return const Color(0xFFD97706);
      case 'Green':
        return const Color(0xFF10B981);
      case 'Red / Pink':
        return const Color(0xFFF43F5E);
      case 'Yellow / Orange':
        return const Color(0xFFF59E0B);
      case 'Purple':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF06B6D4);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (distribution.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: WardrobeTheme.spatialSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WardrobeTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'COLOUR PALETTE DISTRIBUTION',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: WardrobeTheme.textSecondary,
                ),
              ),
              Text(
                'Top: ${distribution.first.colorGroup}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: WardrobeTheme.electricCyan,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Horizontal multi-color segment bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: Row(
                children: distribution.map((item) {
                  return Expanded(
                    flex: (item.percentage * 10).toInt().clamp(1, 1000),
                    child: Container(
                      color: _resolveColorGroup(item.colorGroup),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: distribution.map((item) {
              final color = _resolveColorGroup(item.colorGroup);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: WardrobeTheme.elevatedSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: WardrobeTheme.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24, width: 0.5),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${item.colorGroup} (${item.percentage}%)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: WardrobeTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

