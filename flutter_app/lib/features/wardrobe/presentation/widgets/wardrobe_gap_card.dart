import 'package:flutter/material.dart';
import '../../domain/entities/wardrobe_gap.dart';
import '../theme/wardrobe_theme.dart';

class WardrobeGapCard extends StatelessWidget {
  final WardrobeGap gap;
  final VoidCallback onAddWishlistItem;

  const WardrobeGapCard({
    super.key,
    required this.gap,
    required this.onAddWishlistItem,
  });

  @override
  Widget build(BuildContext context) {
    Color severityColor;
    switch (gap.severity) {
      case GapSeverity.high:
        severityColor = WardrobeTheme.warningRose;
        break;
      case GapSeverity.medium:
        severityColor = WardrobeTheme.electricCyan;
        break;
      case GapSeverity.low:
        severityColor = WardrobeTheme.textMuted;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WardrobeTheme.spatialSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WardrobeTheme.subtleBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  gap.severity.displayName.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: severityColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: WardrobeTheme.electricViolet.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  gap.category.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: WardrobeTheme.softViolet,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${(gap.confidenceScore * 100).toStringAsFixed(0)}% confidence',
                style: TextStyle(
                  fontSize: 11,
                  color: WardrobeTheme.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            gap.title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: WardrobeTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            gap.supportingEvidence,
            style: TextStyle(
              fontSize: 13,
              color: WardrobeTheme.textMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: WardrobeTheme.elevatedSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: WardrobeTheme.electricCyan,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '+${gap.potentialOutfitCombinationsGained} new outfit combinations possible',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: WardrobeTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (gap.compatibleExistingGarmentNames.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Compatible items you already own:',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: WardrobeTheme.textMuted,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: gap.compatibleExistingGarmentNames.map((name) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: WardrobeTheme.spatialSurface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: WardrobeTheme.subtleBorder),
                  ),
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 11,
                      color: WardrobeTheme.textPrimary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onAddWishlistItem,
              icon: const Icon(Icons.add_shopping_cart, size: 15),
              label: const Text('Add to Wishlist to Fill Gap'),
              style: ElevatedButton.styleFrom(
                backgroundColor: WardrobeTheme.electricViolet,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
