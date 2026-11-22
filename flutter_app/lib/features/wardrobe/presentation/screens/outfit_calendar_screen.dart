import 'package:flutter/material.dart';
import '../../domain/entities/outfit_calendar_entry.dart';
import '../controllers/calendar_controller.dart';
import '../controllers/outfit_controller.dart';
import '../theme/wardrobe_theme.dart';
import '../widgets/calendar_day_cell.dart';
import '../widgets/weather_context_card.dart';
import '../widgets/planned_outfit_card.dart';
import '../widgets/actual_outfit_card.dart';
import 'calendar_day_screen.dart';
import 'outfit_plan_screen.dart';
import 'actual_wear_screen.dart';
import 'outfit_history_screen.dart';

class OutfitCalendarScreen extends StatefulWidget {
  final CalendarController controller;
  final OutfitController? outfitController;

  const OutfitCalendarScreen({
    super.key,
    required this.controller,
    this.outfitController,
  });

  @override
  State<OutfitCalendarScreen> createState() => _OutfitCalendarScreenState();
}

class _OutfitCalendarScreenState extends State<OutfitCalendarScreen> {
  final List<String> _weekdays = const ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  String _formatMonthYear(DateTime dt) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }

  void _showActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: WardrobeTheme.spatialSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: WardrobeTheme.electricViolet.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.add_rounded, color: WardrobeTheme.softViolet),
                  ),
                  title: const Text(
                    'Plan an Outfit',
                    style: TextStyle(color: WardrobeTheme.textPrimary, fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Schedule a look for this date without modifying laundry state',
                    style: TextStyle(color: WardrobeTheme.textMuted, fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OutfitPlanScreen(
                          controller: widget.controller,
                          initialDate: widget.controller.selectedDate,
                          outfitController: widget.outfitController,
                        ),
                      ),
                    );
                  },
                ),
                const Divider(color: WardrobeTheme.border),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: WardrobeTheme.electricCyan.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.check_rounded, color: WardrobeTheme.electricCyan),
                  ),
                  title: const Text(
                    'Record What I Wore',
                    style: TextStyle(color: WardrobeTheme.textPrimary, fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Confirm wear, transition garments to Worn, increment wear counts',
                    style: TextStyle(color: WardrobeTheme.textMuted, fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ActualWearScreen(
                          controller: widget.controller,
                          plan: widget.controller.selectedDayDetail?.plans.firstOrNull,
                          date: widget.controller.selectedDate,
                          outfitController: widget.outfitController,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final ctrl = widget.controller;
        final selectedDate = ctrl.selectedDate;

        return Scaffold(
          backgroundColor: WardrobeTheme.voidBg,
          appBar: AppBar(
            backgroundColor: WardrobeTheme.voidBg,
            elevation: 0,
            title: const Row(
              children: [
                Text(
                  'Outfit Calendar',
                  style: TextStyle(
                    color: WardrobeTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'PHASE 6',
                  style: TextStyle(
                    color: WardrobeTheme.softViolet,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.history_rounded, color: WardrobeTheme.softViolet),
                tooltip: 'Wear History',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OutfitHistoryScreen(controller: ctrl),
                    ),
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // 1. Navigation & View Selector Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: WardrobeTheme.deepVoidBg,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, color: WardrobeTheme.textSecondary),
                      onPressed: ctrl.previousPeriod,
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => ctrl.selectDate(DateTime.now()),
                        child: Text(
                          _formatMonthYear(selectedDate),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: WardrobeTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded, color: WardrobeTheme.textSecondary),
                      onPressed: ctrl.nextPeriod,
                    ),
                    const SizedBox(width: 8),
                    // View Mode Segmented Controls
                    Container(
                      decoration: BoxDecoration(
                        color: WardrobeTheme.spatialSurface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: CalendarViewMode.values.map((mode) {
                          final isCurrent = ctrl.viewMode == mode;
                          return GestureDetector(
                            onTap: () => ctrl.setViewMode(mode),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isCurrent ? WardrobeTheme.electricViolet : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                mode.label,
                                style: TextStyle(
                                  color: isCurrent ? Colors.white : WardrobeTheme.textMuted,
                                  fontSize: 11,
                                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. View Content
              Expanded(
                child: ctrl.isLoading && ctrl.currentRangeDays.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(color: WardrobeTheme.electricViolet),
                      )
                    : _buildViewContent(ctrl),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showActionSheet(context),
            backgroundColor: WardrobeTheme.electricViolet,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text('Add Plan / Wear', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }

  Widget _buildViewContent(CalendarController ctrl) {
    switch (ctrl.viewMode) {
      case CalendarViewMode.day:
        return CalendarDayScreen(controller: ctrl, date: ctrl.selectedDate);
      case CalendarViewMode.week:
        return _buildWeekView(ctrl);
      case CalendarViewMode.month:
        return _buildMonthView(ctrl);
    }
  }

  Widget _buildWeekView(CalendarController ctrl) {
    final days = ctrl.currentRangeDays;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: days.length,
      itemBuilder: (context, idx) {
        final day = days[idx];
        final dt = DateTime.tryParse(day.date) ?? ctrl.selectedDate.add(Duration(days: idx));
        final isSelected = dt.year == ctrl.selectedDate.year &&
            dt.month == ctrl.selectedDate.month &&
            dt.day == ctrl.selectedDate.day;

        return GestureDetector(
          onTap: () => ctrl.selectDate(dt),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: WardrobeTheme.spatialSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? WardrobeTheme.electricViolet : WardrobeTheme.border,
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _weekdays[dt.weekday - 1],
                      style: const TextStyle(
                        color: WardrobeTheme.softViolet,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${dt.month}/${dt.day}',
                      style: const TextStyle(
                        color: WardrobeTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (day.isToday) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: WardrobeTheme.electricViolet,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('TODAY', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ],
                    const Spacer(),
                    if (day.weather != null && day.weather!.isForecastAvailable) ...[
                      Text(
                        day.weather!.temperatureDisplay,
                        style: const TextStyle(color: WardrobeTheme.textSecondary, fontSize: 12),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        day.weather!.isRainExpected ? Icons.grain_rounded : Icons.wb_sunny_rounded,
                        size: 14,
                        color: day.weather!.isRainExpected ? WardrobeTheme.electricCyan : WardrobeTheme.statusWarning,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                if (day.plans.isNotEmpty)
                  ...day.plans.map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.bookmark_rounded, size: 12, color: WardrobeTheme.softViolet),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Planned: ${p.outfitName} (${p.occasion})',
                              style: const TextStyle(color: WardrobeTheme.textSecondary, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (day.actualWears.isNotEmpty)
                  ...day.actualWears.map(
                    (w) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 12, color: WardrobeTheme.electricCyan),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Wore: ${w.outfitName}',
                              style: const TextStyle(color: WardrobeTheme.electricCyan, fontSize: 12, fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (day.plans.isEmpty && day.actualWears.isEmpty)
                  const Text('No outfit planned or worn', style: TextStyle(color: WardrobeTheme.textMuted, fontSize: 11)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMonthView(CalendarController ctrl) {
    final year = ctrl.selectedDate.year;
    final month = ctrl.selectedDate.month;
    final firstDayOfMonth = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final startingWeekday = firstDayOfMonth.weekday; // 1 = Mon, 7 = Sun

    final dayMap = <String, CalendarDayDetail>{};
    for (final d in ctrl.currentRangeDays) {
      dayMap[d.date] = d;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Weekday Labels
          Row(
            children: _weekdays.map((w) {
              return Expanded(
                child: Center(
                  child: Text(
                    w,
                    style: const TextStyle(
                      color: WardrobeTheme.textMuted,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          // Calendar Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.0,
            ),
            itemCount: 42, // 6 weeks * 7 days
            itemBuilder: (context, index) {
              final dayOffset = index - (startingWeekday - 1);
              if (dayOffset < 0 || dayOffset >= daysInMonth) {
                // Days outside current month
                return const SizedBox();
              }

              final dayNum = dayOffset + 1;
              final cellDate = DateTime(year, month, dayNum);
              final isSelected = cellDate.year == ctrl.selectedDate.year &&
                  cellDate.month == ctrl.selectedDate.month &&
                  cellDate.day == ctrl.selectedDate.day;

              final dateStr = '$year-${month.toString().padLeft(2, '0')}-${dayNum.toString().padLeft(2, '0')}';
              final detail = dayMap[dateStr];

              return CalendarDayCell(
                date: cellDate,
                isSelected: isSelected,
                isCurrentMonth: true,
                detail: detail,
                onSelect: (dt) => ctrl.selectDate(dt),
              );
            },
          ),
          const SizedBox(height: 16),

          // Selected Day Detail Panel
          const Divider(color: WardrobeTheme.border),
          const SizedBox(height: 8),

          // Weather Context Card for selected day
          WeatherContextCard(weather: ctrl.currentWeather),
          const SizedBox(height: 16),

          // Selected Day Plans / Actuals
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${ctrl.selectedDate.month}/${ctrl.selectedDate.day} Details',
                style: const TextStyle(
                  color: WardrobeTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => ctrl.setViewMode(CalendarViewMode.day),
                child: const Text('Open Day View', style: TextStyle(color: WardrobeTheme.softViolet, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (ctrl.selectedDayDetail?.plans.isEmpty ?? true)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No outfit planned for this date.',
                style: TextStyle(color: WardrobeTheme.textMuted, fontSize: 13),
              ),
            )
          else
            ...ctrl.selectedDayDetail!.plans.map(
              (p) => PlannedOutfitCard(
                plan: p,
                onConfirmWorn: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ActualWearScreen(
                        controller: ctrl,
                        plan: p,
                        date: ctrl.selectedDate,
                        outfitController: widget.outfitController,
                      ),
                    ),
                  );
                },
                onDelete: () => ctrl.deletePlan(p.id),
              ),
            ),

          if (ctrl.selectedDayDetail?.actualWears.isNotEmpty ?? false) ...[
            const SizedBox(height: 8),
            ...ctrl.selectedDayDetail!.actualWears.map((w) => ActualOutfitCard(wear: w)),
          ],

          const SizedBox(height: 80), // Padding for FAB
        ],
      ),
    );
  }
}
