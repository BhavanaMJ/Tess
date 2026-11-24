import 'package:flutter/material.dart';
import '../../domain/entities/wardrobe_insights.dart';
import '../theme/wardrobe_theme.dart';

class CategoryDistributionChart extends StatelessWidget {
  final List<CategoryDistribution> distribution;

  const CategoryDistributionChart({
    super.key,
    required this.distribution,
  });

  @override
  Widget build(BuildContext context) {
    if (distribution.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: WardrobeTheme.spatialSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: WardrobeTheme.border),
        ),
        child: Center(
          child: Text(
            'No category data available',
            style: TextStyle(color: WardrobeTheme.textMuted, fontSize: 13),
          ),
        ),
      );
    }

    final topCategories = distribution.take(6).toList();

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
                'CATEGORY COMPOSITION',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: WardrobeTheme.textSecondary,
                ),
              ),
              Text(
                '${distribution.length} Categories',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: WardrobeTheme.electricViolet,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...topCategories.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.category,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: WardrobeTheme.textPrimary,
                        ),
                      ),
                      Text(
                        '${item.count} items (${item.percentageOfWardrobe}%)',
                        style: TextStyle(
                          fontSize: 12,
                          color: WardrobeTheme.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: (item.percentageOfWardrobe / 100.0).clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: Colors.white.withOpacity(0.06),
                      valueColor: AlwaysStoppedAnimation<Color>(WardrobeTheme.electricViolet),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

