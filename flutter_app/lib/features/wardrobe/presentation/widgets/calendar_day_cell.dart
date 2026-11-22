import 'package:flutter/material.dart';
import '../../domain/entities/outfit_calendar_entry.dart';
import '../theme/wardrobe_theme.dart';

class CalendarDayCell extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final bool isCurrentMonth;
  final CalendarDayDetail? detail;
  final ValueChanged<DateTime> onSelect;

  const CalendarDayCell({
    super.key,
    required this.date,
    required this.isSelected,
    this.isCurrentMonth = true,
    this.detail,
    required this.onSelect,
  });

  bool get _isToday {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final hasPlan = detail?.hasPlan ?? false;
    final hasActualWear = detail?.hasActualWear ?? false;

    Color borderColor = Colors.transparent;
    if (isSelected) {
      borderColor = WardrobeTheme.electricViolet;
    } else if (hasActualWear) {
      borderColor = WardrobeTheme.borderCyan;
    } else if (hasPlan) {
      borderColor = WardrobeTheme.borderViolet;
    } else if (_isToday) {
      borderColor = WardrobeTheme.border;
    }

    Color bgColor = Colors.transparent;
    if (isSelected) {
      bgColor = WardrobeTheme.electricViolet.withOpacity(0.18);
    } else if (hasActualWear) {
      bgColor = WardrobeTheme.electricCyan.withOpacity(0.08);
    } else if (hasPlan) {
      bgColor = WardrobeTheme.electricViolet.withOpacity(0.06);
    }

    return GestureDetector(
      onTap: () => onSelect(date),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: _isToday
                  ? BoxDecoration(
                      color: WardrobeTheme.electricViolet,
                      borderRadius: BorderRadius.circular(6),
                    )
                  : null,
              child: Text(
                '${date.day}',
                style: TextStyle(
                  color: _isToday
                      ? Colors.white
                      : (isCurrentMonth ? WardrobeTheme.textPrimary : WardrobeTheme.textDim),
                  fontSize: 12,
                  fontWeight: isSelected || _isToday ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (hasPlan)
                  Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: const BoxDecoration(
                      color: WardrobeTheme.softViolet,
                      shape: BoxShape.circle,
                    ),
                  ),
                if (hasActualWear)
                  Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: const BoxDecoration(
                      color: WardrobeTheme.electricCyan,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
