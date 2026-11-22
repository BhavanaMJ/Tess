import 'package:flutter/material.dart';
import '../../domain/entities/outfit_item.dart';
import '../theme/wardrobe_theme.dart';
import 'garment_image_placeholder.dart';

class OutfitGarmentPreview extends StatelessWidget {
  final List<OutfitItem> garments;
  final double cardWidth;
  final double cardHeight;
  final ValueChanged<OutfitItem>? onTapItem;

  const OutfitGarmentPreview({
    super.key,
    required this.garments,
    this.cardWidth = 90,
    this.cardHeight = 110,
    this.onTapItem,
  });

  @override
  Widget build(BuildContext context) {
    if (garments.isEmpty) {
      return Container(
        height: cardHeight,
        alignment: Alignment.center,
        child: const Text(
          'No garments in this combination',
          style: TextStyle(color: WardrobeTheme.textMuted, fontSize: 12),
        ),
      );
    }

    return SizedBox(
      height: cardHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: garments.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (ctx, idx) {
          final item = garments[idx];
          return GestureDetector(
            onTap: onTapItem != null ? () => onTapItem!(item) : null,
            child: Container(
              width: cardWidth,
              decoration: BoxDecoration(
                color: WardrobeTheme.spatialSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: item.isEligible
                      ? WardrobeTheme.borderSubtle
                      : WardrobeTheme.statusWarning.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Studio cutout / Image preview
                      Expanded(
                        child: Container(
                          color: WardrobeTheme.studioBackground,
                          child: GarmentImagePlaceholder(
                            category: item.mainCategory,
                            imageUrl: item.processedImageRef ??
                                item.thumbnailRef ??
                                item.originalImageRef,
                          ),
                        ),
                      ),
                      // Garment title & category
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 4),
                        color: WardrobeTheme.spatialSurface,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: WardrobeTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              item.mainCategory,
                              style: const TextStyle(
                                fontSize: 9,
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
                  // Availability Indicator if ineligible
                  if (!item.isEligible)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: WardrobeTheme.statusWarning,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.laundryStatus?.label.toUpperCase() ?? 'UNSET',
                          style: const TextStyle(
                            fontSize: 7,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
