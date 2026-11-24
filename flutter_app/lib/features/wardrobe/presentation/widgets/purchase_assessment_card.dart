import 'package:flutter/material.dart';
import '../../domain/entities/purchase_assessment.dart';
import '../theme/wardrobe_theme.dart';

class PurchaseAssessmentCard extends StatelessWidget {
  final PurchaseAssessment assessment;

  const PurchaseAssessmentCard({super.key, required this.assessment});

  @override
  Widget build(BuildContext context) {
    Color outcomeColor;
    IconData outcomeIcon;

    switch (assessment.outcome) {
      case AssessmentOutcome.strongAddition:
        outcomeColor = WardrobeTheme.successEmerald;
        outcomeIcon = Icons.check_circle_outline_rounded;
        break;
      case AssessmentOutcome.considerAlternatives:
        outcomeColor = WardrobeTheme.warningRose;
        outcomeIcon = Icons.warning_amber_rounded;
        break;
      case AssessmentOutcome.insufficientInfo:
        outcomeColor = WardrobeTheme.textMuted;
        outcomeIcon = Icons.help_outline_rounded;
        break;
      case AssessmentOutcome.potentiallyUseful:
        outcomeColor = WardrobeTheme.electricCyan;
        outcomeIcon = Icons.lightbulb_outline_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WardrobeTheme.spatialSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: outcomeColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(outcomeIcon, color: outcomeColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  assessment.outcome.displayName.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: outcomeColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (assessment.assessmentScore != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: outcomeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${assessment.assessmentScore!.toStringAsFixed(0)} / 100',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: outcomeColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            assessment.headline,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: WardrobeTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            assessment.explanation,
            style: TextStyle(
              fontSize: 13,
              color: WardrobeTheme.textMuted,
              height: 1.4,
            ),
          ),
          if (assessment.contributingFactors.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Analysis Factors:',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: WardrobeTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            ...assessment.contributingFactors.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ',
                        style: TextStyle(color: outcomeColor, fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Text(
                        f,
                        style: TextStyle(
                          fontSize: 12,
                          color: WardrobeTheme.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: WardrobeTheme.elevatedSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: WardrobeTheme.subtleBorder),
            ),
            child: Row(
              children: [
                Icon(Icons.recommend_rounded,
                    size: 16, color: WardrobeTheme.electricViolet),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    assessment.recommendationAction,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: WardrobeTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
