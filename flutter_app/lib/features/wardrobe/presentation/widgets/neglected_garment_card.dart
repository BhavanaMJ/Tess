import 'package:flutter/material.dart';
import '../../domain/entities/wardrobe_insights.dart';
import '../theme/wardrobe_theme.dart';

class NeglectedGarmentCard extends StatelessWidget {
  final GarmentUsage usage;
  final VoidCallback? onPlanLook;

  const NeglectedGarmentCard({
    super.key,
    required this.usage,
    this.onPlanLook,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: WardrobeTheme.spatialSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: WardrobeTheme.statusWarning.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: WardrobeTheme.elevatedSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: WardrobeTheme.border),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: WardrobeTheme.statusWarning,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  usage.garmentName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: WardrobeTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: WardrobeTheme.statusWarning.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        usage.neglectReason?.label ?? 'Neglected',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: WardrobeTheme.statusWarning,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${usage.wearCount} wears',
                      style: const TextStyle(
                        fontSize: 11,
                        color: WardrobeTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (onPlanLook != null)
            TextButton(
              onPressed: onPlanLook,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              child: const Text(
                'Wear',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: WardrobeTheme.electricViolet,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
