import 'package:flutter/material.dart';
import '../../domain/entities/outfit_item.dart';
import '../theme/wardrobe_theme.dart';
import 'outfit_garment_preview.dart';

class OutfitCard extends StatelessWidget {
  final String title;
  final String occasion;
  final String? explanation;
  final List<OutfitItem> garments;
  final bool isAvailable;
  final int wearCount;
  final bool isFavourite;
  final VoidCallback? onSave;
  final VoidCallback? onWear;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFavourite;
  final bool isSaved;

  const OutfitCard({
    super.key,
    required this.title,
    required this.occasion,
    this.explanation,
    required this.garments,
    this.isAvailable = true,
    this.wearCount = 0,
    this.isFavourite = false,
    this.onSave,
    this.onWear,
    this.onTap,
    this.onToggleFavourite,
    this.isSaved = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: WardrobeTheme.elevatedSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isAvailable
                ? WardrobeTheme.borderSubtle
                : WardrobeTheme.statusWarning.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar: Occasion & Availability Badges + Favourite
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: WardrobeTheme.electricViolet.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color:
                          WardrobeTheme.electricViolet.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    occasion.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: WardrobeTheme.softViolet,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isAvailable
                        ? WardrobeTheme.statusSuccess.withValues(alpha: 0.15)
                        : WardrobeTheme.statusWarning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isAvailable
                            ? Icons.check_circle_outline
                            : Icons.error_outline,
                        size: 11,
                        color: isAvailable
                            ? WardrobeTheme.statusSuccess
                            : WardrobeTheme.statusWarning,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isAvailable ? 'READY' : 'IN LAUNDRY',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isAvailable
                              ? WardrobeTheme.statusSuccess
                              : WardrobeTheme.statusWarning,
                        ),
                      ),
                    ],
                  ),
                ),
                if (wearCount > 0) ...[
                  const SizedBox(width: 8),
                  Text(
                    'Worn $wearCount${wearCount == 1 ? 'x' : 'x'}',
                    style: TextStyle(
                      fontSize: 11,
                      color: WardrobeTheme.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const Spacer(),
                if (onToggleFavourite != null)
                  IconButton(
                    icon: Icon(
                      isFavourite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: isFavourite
                          ? WardrobeTheme.electricViolet
                          : WardrobeTheme.textMuted,
                      size: 20,
                    ),
                    onPressed: onToggleFavourite,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Title
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: WardrobeTheme.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),

            // Garment Images Strip
            OutfitGarmentPreview(garments: garments),

            // Stylist Reason / Explanation
            if (explanation != null && explanation!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: WardrobeTheme.spatialSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: WardrobeTheme.electricViolet.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 14,
                      color: WardrobeTheme.electricCyan,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        explanation!,
                        style: TextStyle(
                          fontSize: 11,
                          color: WardrobeTheme.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),

            // Action Buttons
            Row(
              children: [
                if (!isSaved && onSave != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.bookmark_add_outlined, size: 16),
                      label: const Text('Save Outfit',
                          style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: WardrobeTheme.softViolet,
                        side: BorderSide(
                            color: WardrobeTheme.electricViolet),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: onSave,
                    ),
                  ),
                if (!isSaved && onSave != null && onWear != null)
                  const SizedBox(width: 10),
                if (onWear != null)
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.checkroom_rounded, size: 16),
                      label: const Text('Wear Outfit',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isAvailable
                            ? WardrobeTheme.electricViolet
                            : WardrobeTheme.spatialSurface,
                        foregroundColor: isAvailable
                            ? Colors.white
                            : WardrobeTheme.textMuted,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: isAvailable ? onWear : null,
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
