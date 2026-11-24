import 'package:flutter/material.dart';
import '../../domain/entities/wishlist_item.dart';
import '../controllers/wishlist_controller.dart';
import '../theme/wardrobe_theme.dart';
import '../widgets/purchase_assessment_card.dart';
import '../widgets/existing_garment_match_card.dart';

class PurchaseAssessmentScreen extends StatefulWidget {
  final WishlistItem item;
  final WishlistController controller;

  const PurchaseAssessmentScreen({
    super.key,
    required this.item,
    required this.controller,
  });

  @override
  State<PurchaseAssessmentScreen> createState() => _PurchaseAssessmentScreenState();
}

class _PurchaseAssessmentScreenState extends State<PurchaseAssessmentScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.assessItem(widget.item.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WardrobeTheme.voidBlack,
      appBar: AppBar(
        backgroundColor: WardrobeTheme.voidBlack,
        title: const Text(
          'Purchase Assessment',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: WardrobeTheme.textPrimary,
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          final assessment = widget.controller.currentAssessment;

          if (widget.controller.isLoading && assessment == null) {
            return const Center(
              child: CircularProgressIndicator(color: WardrobeTheme.electricViolet),
            );
          }

          if (assessment == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Unable to load assessment',
                    style: TextStyle(color: WardrobeTheme.textMuted),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => widget.controller.assessItem(widget.item.id),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Main decision assessment card
              PurchaseAssessmentCard(assessment: assessment),
              const SizedBox(height: 20),

              // Versatility & Combinations metrics
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: WardrobeTheme.spatialSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: WardrobeTheme.subtleBorder),
                ),
                child: Row(
                  children: [
                    _buildMetricCol(
                      'Compatible Pieces',
                      assessment.compatiblePiecesCount.toString(),
                      WardrobeTheme.electricCyan,
                    ),
                    Container(width: 1, height: 40, color: WardrobeTheme.subtleBorder),
                    _buildMetricCol(
                      'Potential Looks',
                      '+${assessment.potentialNewCombinations}',
                      WardrobeTheme.electricViolet,
                    ),
                    Container(width: 1, height: 40, color: WardrobeTheme.subtleBorder),
                    _buildMetricCol(
                      'Category Gap',
                      assessment.fillsCategoryGap ? 'Yes' : 'No',
                      assessment.fillsCategoryGap
                          ? WardrobeTheme.successEmerald
                          : WardrobeTheme.textMuted,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Similar owned items section
              if (assessment.hasSimilarOwned) ...[
                const Text(
                  'EXISTING SIMILAR GARMENTS IN YOUR WARDROBE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: WardrobeTheme.softViolet,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'You already own pieces that serve a similar purpose or share the same palette.',
                  style: TextStyle(fontSize: 12, color: WardrobeTheme.textMuted),
                ),
                const SizedBox(height: 10),
                ...assessment.existingSimilarGarments.map((match) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ExistingGarmentMatchCard(match: match),
                  );
                }),
                const SizedBox(height: 20),
              ],

              // Philosophy note
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: WardrobeTheme.elevatedSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 16, color: WardrobeTheme.softViolet),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'TESS assessments are decision-support insights, not absolute directives. Prioritize purchases that bring lasting joy and versatile utility.',
                        style: TextStyle(
                          fontSize: 11,
                          color: WardrobeTheme.textMuted,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMetricCol(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: WardrobeTheme.textMuted,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
