import 'package:flutter/material.dart';
import '../../../../shared/widgets/tess_card.dart';
import '../theme/wardrobe_theme.dart';

/// Reusable action card for Clothes Organizer module navigation.
class WardrobeActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? badge;
  final Color? badgeColor;
  final VoidCallback onTap;
  final bool isFeatured;

  const WardrobeActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badge,
    this.badgeColor,
    required this.onTap,
    this.isFeatured = false,
  });

  @override
  Widget build(BuildContext context) {
    return TessCard(
      onTap: onTap,
      backgroundColor: isFeatured
          ? WardrobeTheme.elevatedSurface
          : WardrobeTheme.spatialSurface,
      borderColor: isFeatured
          ? WardrobeTheme.borderViolet
          : WardrobeTheme.border,
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (isFeatured ? WardrobeTheme.electricViolet : WardrobeTheme.electricCyan)
                  .withValues(alpha: 0.15),
              border: Border.all(
                color: (isFeatured ? WardrobeTheme.electricViolet : WardrobeTheme.electricCyan)
                    .withValues(alpha: 0.35),
                width: 1.0,
              ),
            ),
            child: Icon(
              icon,
              color: isFeatured ? WardrobeTheme.softViolet : WardrobeTheme.electricCyan,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: WardrobeTheme.textPrimary,
                        ),
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (badgeColor ?? WardrobeTheme.electricViolet).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: (badgeColor ?? WardrobeTheme.electricViolet).withValues(alpha: 0.35),
                            width: 1.0,
                          ),
                        ),
                        child: Text(
                          badge!,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: badgeColor ?? WardrobeTheme.softViolet,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: WardrobeTheme.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.chevron_right_rounded,
            color: WardrobeTheme.textMuted,
            size: 20,
          ),
        ],
      ),
    );
  }
}
