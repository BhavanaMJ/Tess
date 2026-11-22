import 'package:flutter/material.dart';
import '../controllers/calendar_controller.dart';
import '../theme/wardrobe_theme.dart';
import '../widgets/actual_outfit_card.dart';
import '../widgets/planned_outfit_card.dart';
import '../widgets/weather_context_card.dart';
import 'actual_wear_screen.dart';
import 'outfit_plan_screen.dart';

class CalendarDayScreen extends StatelessWidget {
  final CalendarController controller;
  final DateTime date;

  const CalendarDayScreen({
    super.key,
    required this.controller,
    required this.date,
  });

  String _formatDate(DateTime dt) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final detail = controller.selectedDayDetail;
    final plans = detail?.plans ?? [];
    final actuals = detail?.actualWears ?? [];
    final weather = controller.currentWeather;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Date
          Row(
            children: [
              Text(
                _formatDate(date),
                style: const TextStyle(
                  color: WardrobeTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (detail?.isToday ?? false)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: WardrobeTheme.electricViolet.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: WardrobeTheme.electricViolet),
                  ),
                  child: const Text(
                    'TODAY',
                    style: TextStyle(
                      color: WardrobeTheme.softViolet,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Weather Card
          WeatherContextCard(weather: weather),
          const SizedBox(height: 20),

          // Section 1: Planned Look
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Planned Look',
                style: TextStyle(
                  color: WardrobeTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (plans.isEmpty)
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OutfitPlanScreen(
                          controller: controller,
                          initialDate: date,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_rounded, size: 16, color: WardrobeTheme.softViolet),
                  label: const Text(
                    'Plan Outfit',
                    style: TextStyle(color: WardrobeTheme.softViolet, fontSize: 13),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          if (plans.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: WardrobeTheme.spatialSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: WardrobeTheme.border),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 32,
                    color: WardrobeTheme.textMuted,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'No outfit planned for this date',
                    style: TextStyle(
                      color: WardrobeTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OutfitPlanScreen(
                            controller: controller,
                            initialDate: date,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Add Plan'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: WardrobeTheme.softViolet,
                      side: const BorderSide(color: WardrobeTheme.borderViolet),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ...plans.map(
              (p) => PlannedOutfitCard(
                plan: p,
                onConfirmWorn: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ActualWearScreen(
                        controller: controller,
                        plan: p,
                        date: date,
                      ),
                    ),
                  );
                },
                onDelete: () => controller.deletePlan(p.id),
              ),
            ),

          const SizedBox(height: 24),

          // Section 2: Actually Worn Look
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Actually Worn',
                style: TextStyle(
                  color: WardrobeTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (actuals.isEmpty)
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ActualWearScreen(
                          controller: controller,
                          date: date,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_rounded, size: 16, color: WardrobeTheme.electricCyan),
                  label: const Text(
                    'Record Wear',
                    style: TextStyle(color: WardrobeTheme.electricCyan, fontSize: 13),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          if (actuals.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: WardrobeTheme.spatialSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: WardrobeTheme.border),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 32,
                    color: WardrobeTheme.textMuted,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No wear confirmed yet for this date',
                    style: TextStyle(
                      color: WardrobeTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          else
            ...actuals.map((w) => ActualOutfitCard(wear: w)),
        ],
      ),
    );
  }
}
