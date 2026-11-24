import 'package:flutter/material.dart';
import '../controllers/insights_controller.dart';
import '../theme/wardrobe_theme.dart';
import '../widgets/period_selector.dart';
import '../widgets/wardrobe_utilisation_card.dart';
import '../widgets/category_distribution_chart.dart';
import '../widgets/colour_distribution_chart.dart';
import '../widgets/most_worn_garment_card.dart';
import '../widgets/neglected_garment_card.dart';
import '../widgets/insight_recommendation_card.dart';
import 'cost_per_wear_screen.dart';
import 'capsule_wardrobe_screen.dart';
import 'outfit_repetition_screen.dart';
import 'style_memory_screen.dart';

class WardrobeInsightsScreen extends StatefulWidget {
  final InsightsController controller;

  const WardrobeInsightsScreen({
    super.key,
    required this.controller,
  });

  @override
  State<WardrobeInsightsScreen> createState() => _WardrobeInsightsScreenState();
}

class _WardrobeInsightsScreenState extends State<WardrobeInsightsScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.loadDashboard();
  }

  void _navigateToCostPerWear() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CostPerWearScreen(controller: widget.controller),
      ),
    );
  }

  void _navigateToCapsuleWardrobe() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CapsuleWardrobeScreen(controller: widget.controller),
      ),
    );
  }

  void _navigateToOutfitRepetition() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OutfitRepetitionScreen(controller: widget.controller),
      ),
    );
  }

  void _navigateToStyleMemory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StyleMemoryScreen(controller: widget.controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final ctrl = widget.controller;

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
            title: Row(
              children: [
                Text(
                  'Wardrobe Insights',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: WardrobeTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: WardrobeTheme.electricViolet.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: WardrobeTheme.borderViolet),
                  ),
                  child: Text(
                    'PHASE 7',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: WardrobeTheme.electricViolet,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 20),
                color: WardrobeTheme.textSecondary,
                onPressed: () => ctrl.loadDashboard(),
              ),
            ],
          ),
          body: ctrl.isLoading && ctrl.overview == null
              ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(WardrobeTheme.electricCyan),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => ctrl.loadDashboard(),
                  color: WardrobeTheme.electricCyan,
                  backgroundColor: WardrobeTheme.spatialSurface,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    children: [
                      // Sub-module Quick Jump Hub
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            _buildModulePill(
                              label: 'Cost-Per-Wear',
                              icon: Icons.monetization_on_outlined,
                              accent: WardrobeTheme.electricCyan,
                              onTap: _navigateToCostPerWear,
                            ),
                            const SizedBox(width: 8),
                            _buildModulePill(
                              label: 'Capsule Wardrobe',
                              icon: Icons.all_inclusive_rounded,
                              accent: WardrobeTheme.electricViolet,
                              onTap: _navigateToCapsuleWardrobe,
                            ),
                            const SizedBox(width: 8),
                            _buildModulePill(
                              label: 'Outfit Repetition',
                              icon: Icons.repeat_rounded,
                              accent: WardrobeTheme.softViolet,
                              onTap: _navigateToOutfitRepetition,
                            ),
                            const SizedBox(width: 8),
                            _buildModulePill(
                              label: 'Style Memory',
                              icon: Icons.psychology_rounded,
                              accent: WardrobeTheme.statusSuccess,
                              onTap: _navigateToStyleMemory,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Period Selector
                      PeriodSelector(
                        selectedPeriod: ctrl.selectedPeriod,
                        onPeriodSelected: (period) => ctrl.selectPeriod(period),
                      ),

                      const SizedBox(height: 16),

                      // 1. Wardrobe Utilisation Card
                      if (ctrl.overview != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: WardrobeUtilisationCard(
                            utilisationPercentage: ctrl.overview!.utilisationPercentage,
                            uniqueGarmentsWorn: ctrl.overview!.uniqueGarmentsWornInPeriod,
                            totalActiveGarments: ctrl.overview!.totalActiveGarments,
                            totalOutfitsWorn: ctrl.overview!.totalOutfitsWornInPeriod,
                            summaryText:
                                'Utilisation is based on unique garments worn at least once in the selected period against your active collection.',
                          ),
                        ),

                      const SizedBox(height: 20),

                      // 2. Intelligent Recommendations
                      if (ctrl.recommendations.isNotEmpty) ...[
                        _buildSectionHeader('AI STYLING RECOMMENDATIONS', '${ctrl.recommendations.length} SUGGESTIONS'),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: ctrl.recommendations.map((rec) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: InsightRecommendationCard(
                                  recommendation: rec,
                                  onActionPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Action initiated for ${rec.title}'),
                                        backgroundColor: WardrobeTheme.spatialSurface,
                                      ),
                                    );
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // 3. Category Distribution Chart
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: CategoryDistributionChart(
                          distribution: ctrl.categoryDistribution,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 4. Colour Palette Distribution
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ColourDistributionChart(
                          distribution: ctrl.colourDistribution,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 5. Most Worn Garments
                      _buildSectionHeader('MOST WORN PIECES', 'TOP 5'),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ctrl.mostWorn.isEmpty
                            ? _buildEmptyPlaceholder('No wear history recorded yet for this period.')
                            : Column(
                                children: List.generate(ctrl.mostWorn.length, (idx) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: MostWornGarmentCard(
                                      usage: ctrl.mostWorn[idx],
                                      rank: idx + 1,
                                    ),
                                  );
                                }),
                              ),
                      ),

                      const SizedBox(height: 20),

                      // 6. Neglected / Rarely Worn Garments
                      _buildSectionHeader('NEGLECTED & UNUSED', '${ctrl.neglected.length} ITEMS'),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ctrl.neglected.isEmpty
                            ? _buildEmptyPlaceholder('No neglected garments detected! Fantastic wardrobe usage.')
                            : Column(
                                children: ctrl.neglected.take(4).map((neg) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: NeglectedGarmentCard(
                                      usage: neg,
                                      onPlanLook: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Ready to style ${neg.garmentName}!'),
                                            backgroundColor: WardrobeTheme.spatialSurface,
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                }).toList(),
                              ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildModulePill({
    required String label,
    required IconData icon,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: WardrobeTheme.spatialSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: accent, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String badge) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: WardrobeTheme.textSecondary,
            ),
          ),
          Text(
            badge,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: WardrobeTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPlaceholder(String text) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: WardrobeTheme.spatialSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: WardrobeTheme.border),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(color: WardrobeTheme.textMuted, fontSize: 13),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
