import 'package:flutter/material.dart';
import '../../data/repositories/wardrobe_repository_impl.dart';
import '../../domain/entities/garment.dart';
import '../../domain/entities/outfit.dart';
import '../../domain/entities/outfit_recommendation.dart';
import '../controllers/outfit_controller.dart';
import '../theme/wardrobe_theme.dart';
import '../widgets/garment_selection_grid.dart';
import '../widgets/outfit_card.dart';

class GuidedStylingScreen extends StatefulWidget {
  final OutfitController controller;

  const GuidedStylingScreen({
    super.key,
    required this.controller,
  });

  @override
  State<GuidedStylingScreen> createState() => _GuidedStylingScreenState();
}

class _GuidedStylingScreenState extends State<GuidedStylingScreen> {
  List<Garment> _wardrobeGarments = [];
  Garment? _selectedSeed;
  bool _isLoadingGarments = true;

  @override
  void initState() {
    super.initState();
    _loadUserGarments();
  }

  Future<void> _loadUserGarments() async {
    setState(() => _isLoadingGarments = true);
    try {
      final repo = WardrobeRepositoryImpl();
      final items = await repo.getGarments();
      if (mounted) {
        setState(() {
          _wardrobeGarments = items;
          _isLoadingGarments = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingGarments = false);
    }
  }

  void _selectSeedAndStyle(Garment garment) {
    setState(() => _selectedSeed = garment);
    widget.controller.generateGuidedStyling(garment.id);
  }

  Future<void> _saveGuidedOutfit(OutfitRecommendation rec) async {
    final saved = await widget.controller.saveOutfit(
      name: rec.name,
      occasion: rec.occasion,
      creationSource: OutfitSource.guided,
      stylingExplanation: rec.explanation,
      garmentIds: rec.garmentIds,
    );
    if (saved != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: WardrobeTheme.elevatedSurface,
          content: Text('Saved "${saved.name}" to lookbook!'),
        ),
      );
    }
  }

  Future<void> _wearGuidedOutfit(OutfitRecommendation rec) async {
    final saved = await widget.controller.saveOutfit(
      name: rec.name,
      occasion: rec.occasion,
      creationSource: OutfitSource.guided,
      stylingExplanation: rec.explanation,
      garmentIds: rec.garmentIds,
    );
    if (saved != null) {
      await widget.controller.wearOutfit(saved.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enjoy your outfit! Wear recorded.')),
      );
    }
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
          onPressed: () {
            if (_selectedSeed != null) {
              setState(() => _selectedSeed = null);
              controller.setSeedGarmentId(null);
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          _selectedSeed == null ? 'Select Key Garment' : 'Guided Styling',
          style: TextStyle(
            color: WardrobeTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (_selectedSeed != null)
            TextButton.icon(
              icon: Icon(Icons.change_circle_outlined,
                  size: 16, color: WardrobeTheme.electricCyan),
              label: Text('Change Key',
                  style: TextStyle(
                      color: WardrobeTheme.electricCyan, fontSize: 12)),
              onPressed: () {
                setState(() => _selectedSeed = null);
                controller.setSeedGarmentId(null);
              },
            ),
        ],
      ),
      body: _isLoadingGarments
          ? Center(
              child: CircularProgressIndicator(
                  color: WardrobeTheme.electricViolet))
          : _selectedSeed == null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        'Choose a garment you want to wear today, and TESS will recommend complementary pieces from your wardrobe.',
                        style: TextStyle(
                            color: WardrobeTheme.textSecondary, fontSize: 13),
                      ),
                    ),
                    Expanded(
                      child: GarmentSelectionGrid(
                        garments: _wardrobeGarments,
                        selectedGarmentIds: const [],
                        singleSelect: true,
                        onToggleGarment: _selectSeedAndStyle,
                      ),
                    ),
                  ],
                )
              : AnimatedBuilder(
                  animation: controller,
                  builder: (context, _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Selected Seed Garment Anchor Card
                        Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: WardrobeTheme.elevatedSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: WardrobeTheme.electricViolet
                                    .withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: WardrobeTheme.electricViolet
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.push_pin_rounded,
                                    color: WardrobeTheme.softViolet, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('ANCHOR GARMENT',
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: WardrobeTheme.softViolet,
                                            fontWeight: FontWeight.w700)),
                                    Text(
                                      _selectedSeed!.name,
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: WardrobeTheme.textPrimary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${_selectedSeed!.mainCategory} • ${_selectedSeed!.primaryColor}',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: WardrobeTheme.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.refresh_rounded,
                                    color: WardrobeTheme.electricCyan),
                                tooltip: 'Regenerate Pairings',
                                onPressed: () => controller
                                    .generateGuidedStyling(_selectedSeed!.id),
                              ),
                            ],
                          ),
                        ),

                        // Recommendations List
                        Expanded(
                          child: controller.isLoading
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircularProgressIndicator(
                                          color: WardrobeTheme.electricViolet),
                                      const SizedBox(height: 12),
                                      Text('Curating matching partners...',
                                          style: TextStyle(
                                              color: WardrobeTheme.textMuted,
                                              fontSize: 13)),
                                    ],
                                  ),
                                )
                              : controller.guidedRecommendations.isEmpty
                                  ? Center(
                                      child: Text(
                                        'No matching clean items found for this garment.',
                                        style: TextStyle(
                                            color: WardrobeTheme.textMuted,
                                            fontSize: 13),
                                      ),
                                    )
                                  : ListView.builder(
                                      padding:
                                          const EdgeInsets.only(bottom: 24),
                                      itemCount: controller
                                          .guidedRecommendations.length,
                                      itemBuilder: (ctx, idx) {
                                        final rec = controller
                                            .guidedRecommendations[idx];
                                        return OutfitCard(
                                          title: rec.name,
                                          occasion: rec.occasion,
                                          explanation: rec.explanation,
                                          garments: rec.garments,
                                          isAvailable: rec.isAvailable,
                                          onSave: () => _saveGuidedOutfit(rec),
                                          onWear: () => _wearGuidedOutfit(rec),
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
