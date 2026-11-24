import 'package:flutter/material.dart';
import '../../domain/entities/cost_per_wear.dart';
import '../theme/wardrobe_theme.dart';

class CostPerWearCard extends StatelessWidget {
  final CostPerWearItem item;

  const CostPerWearCard({
    super.key,
    required this.item,
  });

  Color _resolveTierColor(ValueTier tier) {
    switch (tier) {
      case ValueTier.excellentValue:
        return WardrobeTheme.statusSuccess;
      case ValueTier.goodValue:
        return WardrobeTheme.electricCyan;
      case ValueTier.fairValue:
        return WardrobeTheme.softViolet;
      case ValueTier.highCostPerWear:
        return WardrobeTheme.statusWarning;
      case ValueTier.unrecordedWears:
        return WardrobeTheme.statusCritical;
      case ValueTier.missingPrice:
        return WardrobeTheme.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tierColor = _resolveTierColor(item.valueTier);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: WardrobeTheme.spatialSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: WardrobeTheme.border),
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
            child: Icon(
              Icons.monetization_on_outlined,
              color: WardrobeTheme.electricCyan,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.garmentName,
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
                  item.purchasePrice != null
                      ? 'Bought: ₹${item.purchasePrice!.toStringAsFixed(0)} • ${item.wearCount} Wears'
                      : 'Price unrecorded • ${item.wearCount} Wears',
                  style: TextStyle(
                    fontSize: 12,
                    color: WardrobeTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (item.costPerWear != null) ...[
                Text(
                  '₹${item.costPerWear!.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: tierColor,
                  ),
                ),
                Text(
                  '/ wear',
                  style: TextStyle(
                    fontSize: 10,
                    color: WardrobeTheme.textMuted,
                  ),
                ),
              ] else ...[
                Text(
                  item.valueTier == ValueTier.unrecordedWears ? 'Never Worn' : 'No Price',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: tierColor,
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: tierColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.valueTier.label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: tierColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

