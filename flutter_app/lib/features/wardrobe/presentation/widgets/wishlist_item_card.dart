import 'package:flutter/material.dart';
import '../../domain/entities/wishlist_item.dart';
import '../theme/wardrobe_theme.dart';
import 'wishlist_priority_badge.dart';

class WishlistItemCard extends StatelessWidget {
  final WishlistItem item;
  final VoidCallback onTap;
  final VoidCallback onAssess;
  final VoidCallback onToggleStatus;

  const WishlistItemCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onAssess,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    final currencySymbol = item.expectedCurrency == 'INR' ? '₹' : item.expectedCurrency;
    final priceText = item.expectedPrice != null
        ? '$currencySymbol${item.expectedPrice!.toStringAsFixed(0)}'
        : 'Price unrecorded';

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: WardrobeTheme.spatialSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: item.isPurchased
                ? WardrobeTheme.successEmerald.withValues(alpha: 0.3)
                : WardrobeTheme.subtleBorder,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left photo thumbnail or category placeholder
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 76,
                height: 96,
                color: WardrobeTheme.elevatedSurface,
                child: item.referenceImagePath != null && item.referenceImagePath!.isNotEmpty
                    ? (item.referenceImagePath!.startsWith('http')
                        ? Image.network(
                            item.referenceImagePath!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildFallbackIcon(),
                          )
                        : Image.asset(
                            item.referenceImagePath!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildFallbackIcon(),
                          ))
                    : _buildFallbackIcon(),
              ),
            ),
            const SizedBox(width: 14),

            // Center details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      WishlistPriorityBadge(priority: item.purchasePriority),
                      const SizedBox(width: 6),
                      _buildStatusPill(item.status),
                      const Spacer(),
                      if (item.isConverted)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: WardrobeTheme.electricViolet.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'IN WARDROBE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: WardrobeTheme.softViolet,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: WardrobeTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.category}${item.subcategory != null ? ' • ${item.subcategory}' : ''}${item.desiredColour != null ? ' • ${item.desiredColour}' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: WardrobeTheme.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        priceText,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: item.expectedPrice != null
                              ? WardrobeTheme.textPrimary
                              : WardrobeTheme.textMuted,
                        ),
                      ),
                      const Spacer(),
                      // Intelligence Assessment pill button
                      InkWell(
                        onTap: onAssess,
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: WardrobeTheme.electricCyan.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: WardrobeTheme.electricCyan.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome_rounded,
                                  size: 12, color: WardrobeTheme.electricCyan),
                              const SizedBox(width: 4),
                              Text(
                                'Assess',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: WardrobeTheme.electricCyan,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildFallbackIcon() {
    return Center(
      child: Icon(
        Icons.checkroom_outlined,
        size: 32,
        color: WardrobeTheme.softViolet.withValues(alpha: 0.6),
      ),
    );
  }

  Widget _buildStatusPill(WishlistStatus status) {
    Color color;
    switch (status) {
      case WishlistStatus.shortlisted:
        color = WardrobeTheme.electricCyan;
        break;
      case WishlistStatus.purchased:
        color = WardrobeTheme.successEmerald;
        break;
      case WishlistStatus.notInterested:
        color = WardrobeTheme.textMuted;
        break;
      case WishlistStatus.considering:
        color = WardrobeTheme.softViolet;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
