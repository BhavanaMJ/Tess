import 'package:flutter/material.dart';
import '../controllers/insights_controller.dart';
import '../theme/wardrobe_theme.dart';

class CapsuleWardrobeScreen extends StatelessWidget {
  final InsightsController controller;

  const CapsuleWardrobeScreen({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final summary = controller.capsuleSummary;

        return Scaffold(
          backgroundColor: WardrobeTheme.voidBg,
          appBar: AppBar(
            backgroundColor: WardrobeTheme.deepVoidBg,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              color: WardrobeTheme.textPrimary,
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text(
              'Capsule Wardrobe Intelligence',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: WardrobeTheme.textPrimary,
              ),
            ),
          ),
          body: summary == null
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(WardrobeTheme.electricViolet),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Summary Banner
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: WardrobeTheme.spatialSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: WardrobeTheme.borderViolet.withOpacity(0.4)),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            WardrobeTheme.spatialSurface,
                            WardrobeTheme.electricViolet.withOpacity(0.1),
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: WardrobeTheme.electricViolet.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.all_inclusive_rounded,
                                  color: WardrobeTheme.electricViolet,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Capsule Versatility Score',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: WardrobeTheme.textPrimary,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Maximizing outfit variety with minimal pieces',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: WardrobeTheme.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildMetric(
                                label: 'Average Versatility',
                                value: '${summary.averageVersatilityScore}%',
                                color: WardrobeTheme.electricCyan,
                              ),
                              _buildMetric(
                                label: 'Anchor Pieces',
                                value: '${summary.capsuleReadyGarmentsCount}',
                                color: WardrobeTheme.electricViolet,
                              ),
                              _buildMetric(
                                label: 'Possible Outfits',
                                value: '${summary.potentialOutfitCombinations}',
                                color: WardrobeTheme.statusSuccess,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Anchor Garments Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'CAPSULE ANCHOR PIECES',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: WardrobeTheme.textSecondary,
                          ),
                        ),
                        Text(
                          '${summary.anchorGarments.length} Anchors',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: WardrobeTheme.electricViolet,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (summary.anchorGarments.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: WardrobeTheme.spatialSurface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: WardrobeTheme.border),
                        ),
                        child: const Center(
                          child: Text(
                            'Add more versatile neutral basics to create capsule anchors.',
                            style: TextStyle(color: WardrobeTheme.textMuted, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else
                      ...summary.anchorGarments.map((anchor) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: WardrobeTheme.spatialSurface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: WardrobeTheme.border),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: WardrobeTheme.elevatedSurface,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: WardrobeTheme.border),
                                  ),
                                  child: const Icon(
                                    Icons.shield_rounded,
                                    color: WardrobeTheme.electricViolet,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        anchor.garmentName,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: WardrobeTheme.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'Pairs with ${anchor.compatiblePairingsCount} garments (${anchor.mainCategory})',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: WardrobeTheme.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${anchor.versatilityScore}%',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: WardrobeTheme.electricCyan,
                                      ),
                                    ),
                                    const Text(
                                      'Versatility',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: WardrobeTheme.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildMetric({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: WardrobeTheme.textMuted),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

