import 'package:flutter/material.dart';
import '../../domain/entities/insights_period.dart';
import '../theme/wardrobe_theme.dart';

class PeriodSelector extends StatelessWidget {
  final AnalyticsPeriod selectedPeriod;
  final ValueChanged<AnalyticsPeriod> onPeriodSelected;

  const PeriodSelector({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodSelected,
  });

  @override
  Widget build(BuildContext context) {
    const periods = [
      AnalyticsPeriod.days7,
      AnalyticsPeriod.days30,
      AnalyticsPeriod.days90,
      AnalyticsPeriod.months6,
      AnalyticsPeriod.months12,
      AnalyticsPeriod.allTime,
    ];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: periods.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final p = periods[index];
          final isSelected = p == selectedPeriod;

          return InkWell(
            onTap: () => onPeriodSelected(p),
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? WardrobeTheme.electricCyan.withOpacity(0.18)
                    : WardrobeTheme.spatialSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? WardrobeTheme.electricCyan
                      : WardrobeTheme.border,
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              child: Center(
                child: Text(
                  p.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? WardrobeTheme.electricCyan
                        : WardrobeTheme.textSecondary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

