import 'package:flutter/material.dart';
import '../../domain/entities/garment.dart';
import '../../domain/entities/laundry_status.dart';
import '../theme/wardrobe_theme.dart';
import 'garment_image_placeholder.dart';

class GarmentSelectionGrid extends StatelessWidget {
  final List<Garment> garments;
  final List<String> selectedGarmentIds;
  final ValueChanged<Garment> onToggleGarment;
  final bool singleSelect;

  const GarmentSelectionGrid({
    super.key,
    required this.garments,
    required this.selectedGarmentIds,
    required this.onToggleGarment,
    this.singleSelect = false,
  });

  @override
  Widget build(BuildContext context) {
    if (garments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            'No matching garments in this category',
            style: TextStyle(color: WardrobeTheme.textMuted, fontSize: 13),
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: garments.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (ctx, idx) {
        final g = garments[idx];
        final isSelected = selectedGarmentIds.contains(g.id);
        final isEligible = g.laundryStatus == LaundryStatus.clean ||
            g.laundryStatus == LaundryStatus.stored;

        return GestureDetector(
          onTap: () => onToggleGarment(g),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: WardrobeTheme.elevatedSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? WardrobeTheme.electricViolet
                    : (isEligible
                        ? WardrobeTheme.borderSubtle
                        : WardrobeTheme.statusWarning.withValues(alpha: 0.4)),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: WardrobeTheme.electricViolet
                            .withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : null,
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Studio cutout preview
                    Expanded(
                      flex: 6,
                      child: Container(
                        color: WardrobeTheme.studioBackground,
                        child: GarmentImagePlaceholder(
                          category: g.mainCategory,
                          imageUrl: g.processedImageRef ??
                              g.thumbnailRef ??
                              g.originalImageRef,
                        ),
                      ),
                    ),
                    // Details
                    Expanded(
                      flex: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              g.name,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: WardrobeTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${g.mainCategory} • ${g.primaryColor}',
                              style: TextStyle(
                                fontSize: 10,
                                color: WardrobeTheme.textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            // Laundry status chip
                            Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isEligible
                                        ? WardrobeTheme.statusSuccess
                                        : (g.laundryStatus == LaundryStatus.worn
                                            ? WardrobeTheme.statusWarning
                                            : WardrobeTheme.statusCritical),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    g.laundryStatus?.label ?? 'Unassigned',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: isEligible
                                          ? WardrobeTheme.statusSuccess
                                          : (g.laundryStatus ==
                                                  LaundryStatus.worn
                                              ? WardrobeTheme.statusWarning
                                              : WardrobeTheme.statusCritical),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                // Selection Checkmark
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? WardrobeTheme.electricViolet
                          : Colors.black.withValues(alpha: 0.4),
                      border: Border.all(
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
