import 'package:flutter/material.dart';
import '../../domain/entities/purchase_assessment.dart';
import '../theme/wardrobe_theme.dart';

class ExistingGarmentMatchCard extends StatelessWidget {
  final GarmentMatch match;

  const ExistingGarmentMatchCard({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    switch (match.matchType) {
      case GarmentMatchType.exactColorAndCategory:
        badgeColor = WardrobeTheme.warningRose;
        break;
      case GarmentMatchType.similarFunction:
        badgeColor = WardrobeTheme.electricViolet;
        break;
      case GarmentMatchType.sameCategory:
        badgeColor = WardrobeTheme.electricCyan;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: WardrobeTheme.spatialSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WardrobeTheme.subtleBorder),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 50,
              height: 50,
              color: WardrobeTheme.elevatedSurface,
              child: match.imageUrl != null && match.imageUrl!.isNotEmpty
                  ? Image.network(
                      match.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildFallbackIcon(),
                    )
                  : _buildFallbackIcon(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        match.matchType.displayName.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: badgeColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      match.primaryColor,
                      style: TextStyle(
                        fontSize: 11,
                        color: WardrobeTheme.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  match.garmentName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: WardrobeTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  match.similarityReason,
                  style: TextStyle(
                    fontSize: 11,
                    color: WardrobeTheme.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackIcon() {
    return Center(
      child: Icon(Icons.checkroom, size: 24, color: WardrobeTheme.softViolet),
    );
  }
}
