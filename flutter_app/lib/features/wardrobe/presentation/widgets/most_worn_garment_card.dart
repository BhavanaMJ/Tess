import 'package:flutter/material.dart';
import '../../domain/entities/wardrobe_insights.dart';
import '../theme/wardrobe_theme.dart';

class MostWornGarmentCard extends StatelessWidget {
  final GarmentUsage usage;
  final int rank;
  final VoidCallback? onTap;

  const MostWornGarmentCard({
    super.key,
    required this.usage,
    required this.rank,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: WardrobeTheme.spatialSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: WardrobeTheme.border),
        ),
        child: Row(
          children: [
            // Rank badge
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: rank == 1
                    ? WardrobeTheme.electricViolet
                    : WardrobeTheme.elevatedSurface,
                shape: BoxShape.circle,
                border: Border.all(color: WardrobeTheme.borderViolet),
              ),
              child: Center(
                child: Text(
                  '#$rank',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Garment icon/thumb placeholder
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: WardrobeTheme.elevatedSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: WardrobeTheme.border),
              ),
              child: Icon(
                Icons.checkroom_rounded,
                color: WardrobeTheme.electricCyan,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    usage.garmentName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: WardrobeTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${usage.mainCategory} • ${usage.primaryColor}',
                    style: TextStyle(
                      fontSize: 12,
                      color: WardrobeTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            // Wear Count & CPW
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: WardrobeTheme.electricCyan.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: WardrobeTheme.electricCyan.withOpacity(0.3)),
                  ),
                  child: Text(
                    '${usage.wearCount} Wears',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: WardrobeTheme.electricCyan,
                    ),
                  ),
                ),
                if (usage.costPerWear != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    '₹${usage.costPerWear!.toStringAsFixed(0)} / wear',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: WardrobeTheme.statusSuccess,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

