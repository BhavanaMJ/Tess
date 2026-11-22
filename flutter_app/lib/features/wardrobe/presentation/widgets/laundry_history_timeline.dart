import 'package:flutter/material.dart';
import '../../domain/entities/laundry_history_entry.dart';
import '../theme/wardrobe_theme.dart';

class LaundryHistoryTimeline extends StatelessWidget {
  final List<LaundryHistoryEntry> history;

  const LaundryHistoryTimeline({
    super.key,
    required this.history,
  });

  String _formatTimestamp(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Color _getEventColor(String eventType) {
    switch (eventType) {
      case 'WEAR':
        return WardrobeTheme.statusWarning;
      case 'WASH_CYCLE_STARTED':
        return WardrobeTheme.electricCyan;
      case 'WASH_CYCLE_COMPLETED':
        return WardrobeTheme.statusSuccess;
      case 'STORED':
        return WardrobeTheme.electricViolet;
      case 'MANUAL_OVERRIDE':
        return WardrobeTheme.softViolet;
      default:
        return WardrobeTheme.textSecondary;
    }
  }

  IconData _getEventIcon(String eventType) {
    switch (eventType) {
      case 'WEAR':
        return Icons.checkroom_rounded;
      case 'WASH_CYCLE_STARTED':
        return Icons.local_laundry_service_outlined;
      case 'WASH_CYCLE_COMPLETED':
        return Icons.verified_rounded;
      case 'STORED':
        return Icons.inventory_2_outlined;
      case 'BATCH_ASSIGNED':
        return Icons.group_work_outlined;
      default:
        return Icons.update_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history_rounded, size: 36, color: WardrobeTheme.textMuted.withValues(alpha: 0.5)),
              const SizedBox(height: 10),
              const Text(
                'No Laundry History Yet',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: WardrobeTheme.textSecondary),
              ),
              const SizedBox(height: 4),
              const Text(
                'Lifecycle changes, wears and wash cycles will appear here chronologically.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: WardrobeTheme.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final entry = history[index];
        final eventColor = _getEventColor(entry.eventType);
        final isLast = index == history.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline line and node
              Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: eventColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: eventColor, width: 1.5),
                    ),
                    child: Icon(_getEventIcon(entry.eventType), size: 14, color: eventColor),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 1.5,
                        color: WardrobeTheme.borderSubtle,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),

              // Event details card
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: WardrobeTheme.spatialSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: WardrobeTheme.borderSubtle),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              entry.eventType.replaceAll('_', ' '),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: eventColor,
                              ),
                            ),
                            Text(
                              _formatTimestamp(entry.createdAt),
                              style: const TextStyle(fontSize: 10, color: WardrobeTheme.textMuted),
                            ),
                          ],
                        ),
                        if (entry.previousStatus != null || entry.newStatus != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${entry.previousStatus ?? "UNASSIGNED"}  ➔  ${entry.newStatus ?? "UNASSIGNED"}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: WardrobeTheme.textPrimary,
                            ),
                          ),
                        ],
                        if (entry.notes != null && entry.notes!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            entry.notes!,
                            style: const TextStyle(fontSize: 11, color: WardrobeTheme.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
