import 'package:flutter/material.dart';
import '../../domain/entities/wishlist_item.dart';
import '../theme/wardrobe_theme.dart';

class WishlistPriorityBadge extends StatelessWidget {
  final PurchasePriority priority;

  const WishlistPriorityBadge({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;

    switch (priority) {
      case PurchasePriority.high:
        bg = WardrobeTheme.warningRose.withValues(alpha: 0.15);
        text = WardrobeTheme.warningRose;
        break;
      case PurchasePriority.medium:
        bg = WardrobeTheme.electricCyan.withValues(alpha: 0.15);
        text = WardrobeTheme.electricCyan;
        break;
      case PurchasePriority.low:
        bg = WardrobeTheme.textMuted.withValues(alpha: 0.15);
        text = WardrobeTheme.textMuted;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: text.withValues(alpha: 0.3)),
      ),
      child: Text(
        priority.displayName.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: text,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
