import 'package:flutter/material.dart';
import '../controllers/outfit_controller.dart';
import '../theme/wardrobe_theme.dart';
import '../widgets/wardrobe_action_card.dart';
import '../widgets/wardrobe_section_header.dart';
import 'automatic_outfits_screen.dart';
import 'guided_styling_screen.dart';
import 'manual_outfit_screen.dart';
import 'saved_outfits_screen.dart';

class OutfitStudioScreen extends StatefulWidget {
  final OutfitController controller;

  const OutfitStudioScreen({
    super.key,
    required this.controller,
  });

  @override
  State<OutfitStudioScreen> createState() => _OutfitStudioScreenState();
}

class _OutfitStudioScreenState extends State<OutfitStudioScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.loadSavedOutfits();
  }

  void _navigateToAutomatic() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AutomaticOutfitsScreen(controller: widget.controller),
      ),
    );
  }

  void _navigateToGuided() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GuidedStylingScreen(controller: widget.controller),
      ),
    );
  }

  void _navigateToManual() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ManualOutfitScreen(controller: widget.controller),
      ),
    );
  }

  void _navigateToSaved() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SavedOutfitsScreen(controller: widget.controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return Scaffold(
      backgroundColor: WardrobeTheme.voidBg,
      appBar: AppBar(
        backgroundColor: WardrobeTheme.voidBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: WardrobeTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Outfit Studio',
          style: TextStyle(
            color: WardrobeTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.bookmarks_rounded,
                color: WardrobeTheme.softViolet),
            tooltip: 'Saved Outfits',
            onPressed: _navigateToSaved,
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Banner
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        WardrobeTheme.electricViolet.withValues(alpha: 0.2),
                        WardrobeTheme.spatialSurface,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          WardrobeTheme.electricViolet.withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: WardrobeTheme.electricViolet
                              .withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          size: 28,
                          color: WardrobeTheme.softViolet,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI Personal Stylist',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: WardrobeTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Create combinations using only verified, clean garments in your wardrobe.',
                              style: TextStyle(
                                fontSize: 12,
                                color: WardrobeTheme.textSecondary,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Creation Modes Header
                const WardrobeSectionHeader(
                  title: 'CREATION MODES',
                  badgeText: '3 STYLING MODES',
                ),

                const SizedBox(height: 12),

                // Mode A: Automatic Suggestions
                WardrobeActionCard(
                  icon: Icons.auto_awesome,
                  title: 'Automatic Suggestions',
                  subtitle:
                      'TESS analyzes your clean clothes and suggests diverse full outfits',
                  badge: 'AI ACTIVE',
                  badgeColor: WardrobeTheme.electricViolet,
                  isFeatured: true,
                  onTap: _navigateToAutomatic,
                ),

                const SizedBox(height: 12),

                // Mode B: Guided Styling
                WardrobeActionCard(
                  icon: Icons.assistant_direction_rounded,
                  title: 'Guided Styling',
                  subtitle:
                      'Pick a seed garment (e.g. Kurta or Blazer) and discover compatible pairings',
                  badge: 'GUIDED',
                  badgeColor: WardrobeTheme.electricCyan,
                  onTap: _navigateToGuided,
                ),

                const SizedBox(height: 12),

                // Mode C: Manual Outfit Builder
                WardrobeActionCard(
                  icon: Icons.dashboard_customize_rounded,
                  title: 'Manual Outfit Builder',
                  subtitle:
                      'Curate your own combination with real-time laundry availability validation',
                  badge: 'CANVAS',
                  badgeColor: WardrobeTheme.statusSuccess,
                  onTap: _navigateToManual,
                ),

                const SizedBox(height: 24),

                // Lookbook Section
                const WardrobeSectionHeader(
                  title: 'SAVED LOOKBOOK',
                  badgeText: 'COLLECTIONS',
                ),

                const SizedBox(height: 12),

                WardrobeActionCard(
                  icon: Icons.bookmarks_rounded,
                  title: 'Saved Outfits & Lookbook',
                  subtitle:
                      'View saved combinations, wear history, and outfit notes',
                  badge: '${controller.savedOutfits.length} LOOKS',
                  badgeColor: WardrobeTheme.softViolet,
                  onTap: _navigateToSaved,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
