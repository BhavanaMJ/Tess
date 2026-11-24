import 'package:flutter/material.dart';
import '../../domain/entities/wardrobe_insights.dart';
import '../theme/wardrobe_theme.dart';

class InsightRecommendationCard extends StatelessWidget {
  final WardrobeRecommendation recommendation;
  final VoidCallback? onActionPressed;

  const InsightRecommendationCard({
    super.key,
    required this.recommendation,
    this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color accentColor;

    switch (recommendation.type) {
      case RecommendationType.reviveNeglected:
        icon = Icons.replay_circle_filled_rounded;
        accentColor = WardrobeTheme.electricViolet;
        break;
      case RecommendationType.highWearFavorite:
        icon = Icons.star_rounded;
        accentColor = WardrobeTheme.electricCyan;
        break;
      case RecommendationType.categoryBalance:
        icon = Icons.balance_rounded;
        accentColor = WardrobeTheme.softViolet;
        break;
      case RecommendationType.newCombination:
        icon = Icons.auto_awesome_rounded;
        accentColor = WardrobeTheme.statusSuccess;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WardrobeTheme.spatialSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.3)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            WardrobeTheme.spatialSurface,
            accentColor.withOpacity(0.06),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accentColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  recommendation.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: WardrobeTheme.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${(recommendation.confidenceScore * 100).toInt()}% Match',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: WardrobeTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            recommendation.description,
            style: TextStyle(
              fontSize: 13,
              color: WardrobeTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: onActionPressed,
              icon: const Icon(Icons.arrow_forward_rounded, size: 14),
              label: Text(
                recommendation.suggestedAction,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor.withOpacity(0.2),
                foregroundColor: accentColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: accentColor.withOpacity(0.4)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
