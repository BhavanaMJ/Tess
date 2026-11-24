import 'package:flutter/material.dart';
import '../theme/wardrobe_theme.dart';

class WishlistEmptyState extends StatelessWidget {
  final VoidCallback onAddItem;
  final VoidCallback onExploreGaps;

  const WishlistEmptyState({
    super.key,
    required this.onAddItem,
    required this.onExploreGaps,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: WardrobeTheme.spatialSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WardrobeTheme.subtleBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: WardrobeTheme.electricViolet.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bookmark_add_outlined,
              size: 36,
              color: WardrobeTheme.softViolet,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Your Wishlist is Empty',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: WardrobeTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Plan future clothing purchases with intention. Check your wardrobe gaps before adding new items.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: WardrobeTheme.textMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: onExploreGaps,
                icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                label: const Text('View Gaps'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: WardrobeTheme.electricCyan,
                  side: const BorderSide(color: WardrobeTheme.electricCyan),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: onAddItem,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Item'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: WardrobeTheme.electricViolet,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
