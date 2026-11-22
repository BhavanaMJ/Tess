import 'package:flutter/material.dart';
import '../../domain/entities/outfit.dart';
import '../../domain/entities/outfit_recommendation.dart';
import '../controllers/outfit_controller.dart';
import '../theme/wardrobe_theme.dart';
import '../widgets/outfit_card.dart';
import '../widgets/outfit_filter_sheet.dart';
import '../widgets/outfit_occasion_selector.dart';

class AutomaticOutfitsScreen extends StatefulWidget {
  final OutfitController controller;

  const AutomaticOutfitsScreen({
    super.key,
    required this.controller,
  });

  @override
  State<AutomaticOutfitsScreen> createState() => _AutomaticOutfitsScreenState();
}

class _AutomaticOutfitsScreenState extends State<AutomaticOutfitsScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.generateRecommendations();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OutfitFilterSheet(
        initialOccasion: widget.controller.selectedOccasion,
        initialExcludeWorn: widget.controller.excludeWorn,
        initialFavoritesOnly: widget.controller.favoritesOnly,
        onApply: (occ, excl, favs) {
          widget.controller.setOccasion(occ);
          widget.controller.setExcludeWorn(excl);
          widget.controller.setFavoritesOnly(favs);
          widget.controller.generateRecommendations(occasion: occ);
        },
      ),
    );
  }

  void _showSaveDialog(OutfitRecommendation rec) {
    final nameController = TextEditingController(text: rec.name);
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: WardrobeTheme.elevatedSurface,
        title: const Text('Save Look to Lookbook',
            style: TextStyle(color: WardrobeTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Outfit Name',
                labelStyle: TextStyle(color: WardrobeTheme.textMuted),
              ),
              style: const TextStyle(color: WardrobeTheme.textPrimary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                labelStyle: TextStyle(color: WardrobeTheme.textMuted),
              ),
              style: const TextStyle(color: WardrobeTheme.textPrimary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: WardrobeTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: WardrobeTheme.electricViolet),
            onPressed: () async {
              Navigator.pop(ctx);
              final saved = await widget.controller.saveOutfit(
                name: nameController.text.trim().isNotEmpty
                    ? nameController.text.trim()
                    : rec.name,
                occasion: rec.occasion,
                notes: notesController.text.trim(),
                creationSource: OutfitSource.automatic,
                stylingExplanation: rec.explanation,
                garmentIds: rec.garmentIds,
              );
              if (mounted && saved != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: WardrobeTheme.elevatedSurface,
                    content: Text('Saved "${saved.name}" to lookbook!'),
                  ),
                );
              }
            },
            child:
                const Text('Save Look', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmWearOutfit(OutfitRecommendation rec) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: WardrobeTheme.elevatedSurface,
        title: const Text('Wear this Outfit today?',
            style: TextStyle(color: WardrobeTheme.textPrimary)),
        content: Text(
          'Wearing "${rec.name}" will update ${rec.garmentIds.length} garments to WORN in Laundry Manager and increment their wear count.',
          style:
              const TextStyle(color: WardrobeTheme.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: WardrobeTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: WardrobeTheme.electricViolet),
            onPressed: () async {
              Navigator.pop(ctx);
              // Save first if not saved
              final saved = await widget.controller.saveOutfit(
                name: rec.name,
                occasion: rec.occasion,
                creationSource: OutfitSource.automatic,
                stylingExplanation: rec.explanation,
                garmentIds: rec.garmentIds,
              );
              if (saved != null) {
                final success = await widget.controller.wearOutfit(saved.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: success
                          ? WardrobeTheme.elevatedSurface
                          : WardrobeTheme.statusCritical,
                      content: Text(
                        success
                            ? 'Enjoy your look! Garment wear recorded.'
                            : widget.controller.errorMessage ??
                                'Failed to wear outfit.',
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text('Confirm & Wear',
                style: TextStyle(color: Colors.white)),
          ),
        ],
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
          icon: const Icon(Icons.arrow_back, color: WardrobeTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Automatic Suggestions',
          style: TextStyle(
            color: WardrobeTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded,
                color: WardrobeTheme.textPrimary),
            tooltip: 'Filter Options',
            onPressed: _showFilterSheet,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: WardrobeTheme.electricCyan),
            tooltip: 'Regenerate Suggestions',
            onPressed: () => controller.generateRecommendations(),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return Column(
            children: [
              const SizedBox(height: 8),
              OutfitOccasionSelector(
                selectedOccasion: controller.selectedOccasion,
                showAllOption: false,
                onSelected: (occ) {
                  controller.setOccasion(occ);
                  controller.generateRecommendations(occasion: occ);
                },
              ),
              const SizedBox(height: 12),
              Expanded(
                child: controller.isLoading
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                                color: WardrobeTheme.electricViolet),
                            SizedBox(height: 16),
                            Text(
                              'Styling clean combinations...',
                              style: TextStyle(
                                  color: WardrobeTheme.textMuted, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : controller.recommendations.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.checkroom_rounded,
                                      size: 48, color: WardrobeTheme.textMuted),
                                  const SizedBox(height: 12),
                                  const Text('No combinations found',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: WardrobeTheme.textPrimary)),
                                  const SizedBox(height: 6),
                                  const Text(
                                      'Ensure you have clean tops and bottoms or dresses in your wardrobe.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: WardrobeTheme.textMuted,
                                          fontSize: 13)),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            WardrobeTheme.electricViolet),
                                    onPressed: () =>
                                        controller.generateRecommendations(),
                                    child: const Text('Refresh Suggestions',
                                        style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 24),
                            itemCount: controller.recommendations.length,
                            itemBuilder: (ctx, idx) {
                              final rec = controller.recommendations[idx];
                              return OutfitCard(
                                title: rec.name,
                                occasion: rec.occasion,
                                explanation: rec.explanation,
                                garments: rec.garments,
                                isAvailable: rec.isAvailable,
                                onSave: () => _showSaveDialog(rec),
                                onWear: () => _confirmWearOutfit(rec),
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }
}
