import 'package:flutter/material.dart';
import '../theme/wardrobe_theme.dart';

class WardrobeUtilisationCard extends StatelessWidget {
  final double utilisationPercentage;
  final int uniqueGarmentsWorn;
  final int totalActiveGarments;
  final int totalOutfitsWorn;
  final String? summaryText;

  const WardrobeUtilisationCard({
    super.key,
    required this.utilisationPercentage,
    required this.uniqueGarmentsWorn,
    required this.totalActiveGarments,
    required this.totalOutfitsWorn,
    this.summaryText,
  });

  @override
  Widget build(BuildContext context) {
    Color gaugeColor;
    if (utilisationPercentage >= 65.0) {
      gaugeColor = WardrobeTheme.statusSuccess;
    } else if (utilisationPercentage >= 35.0) {
      gaugeColor = WardrobeTheme.electricCyan;
    } else {
      gaugeColor = WardrobeTheme.statusWarning;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: WardrobeTheme.spatialSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WardrobeTheme.borderViolet.withOpacity(0.4)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            WardrobeTheme.spatialSurface,
            WardrobeTheme.electricViolet.withOpacity(0.08),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.speed_rounded,
                    color: gaugeColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'WARDROBE UTILISATION',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: WardrobeTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: gaugeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: gaugeColor.withOpacity(0.4)),
                ),
                child: Text(
                  utilisationPercentage >= 50.0 ? 'HEALTHY' : 'UNDERUTILIZED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: gaugeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Circular / Progress representation
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: CircularProgressIndicator(
                      value: (utilisationPercentage / 100.0).clamp(0.0, 1.0),
                      strokeWidth: 7,
                      backgroundColor: Colors.white.withOpacity(0.08),
                      valueColor: AlwaysStoppedAnimation<Color>(gaugeColor),
                    ),
                  ),
                  Text(
                    '${utilisationPercentage.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: WardrobeTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              // Metrics Breakdown
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$uniqueGarmentsWorn of $totalActiveGarments Pieces Worn',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: WardrobeTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$totalOutfitsWorn total outfit logged appearances',
                      style: TextStyle(
                        fontSize: 12,
                        color: WardrobeTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Progress bar ratio
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (utilisationPercentage / 100.0).clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: Colors.white.withOpacity(0.08),
                        valueColor: AlwaysStoppedAnimation<Color>(gaugeColor),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (summaryText != null && summaryText!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              summaryText!,
              style: TextStyle(
                fontSize: 12,
                color: WardrobeTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

