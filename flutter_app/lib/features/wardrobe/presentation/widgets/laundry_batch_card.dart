import 'package:flutter/material.dart';
import '../../domain/entities/laundry_batch.dart';
import '../theme/wardrobe_theme.dart';

class LaundryBatchCard extends StatelessWidget {
  final LaundryBatch batch;
  final VoidCallback onTap;

  const LaundryBatchCard({
    super.key,
    required this.batch,
    required this.onTap,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'WASHING':
        return WardrobeTheme.electricCyan;
      case 'DRYING':
        return WardrobeTheme.statusWarning;
      case 'COMPLETED':
        return WardrobeTheme.statusSuccess;
      default:
        return WardrobeTheme.electricViolet;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(batch.status);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: WardrobeTheme.spatialSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: statusColor.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: WardrobeTheme.elevatedSurface,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: WardrobeTheme.border),
                        ),
                        child: Text(
                          batch.batchNumber,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: WardrobeTheme.textSecondary,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          batch.status,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: statusColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${batch.itemsCount} ${batch.itemsCount == 1 ? "item" : "items"}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: WardrobeTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                batch.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: WardrobeTheme.textPrimary,
                ),
              ),
              if (batch.notes != null && batch.notes!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  batch.notes!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: WardrobeTheme.textMuted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
