import 'package:flutter/material.dart';
import '../../domain/entities/outfit.dart';
import '../controllers/outfit_controller.dart';
import '../theme/wardrobe_theme.dart';
import '../widgets/outfit_card.dart';
import '../widgets/outfit_occasion_selector.dart';
import 'outfit_detail_screen.dart';

class SavedOutfitsScreen extends StatefulWidget {
  final OutfitController controller;

  const SavedOutfitsScreen({
    super.key,
    required this.controller,
  });

  @override
  State<SavedOutfitsScreen> createState() => _SavedOutfitsScreenState();
}

class _SavedOutfitsScreenState extends State<SavedOutfitsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.controller.loadSavedOutfits();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToDetail(Outfit outfit) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => OutfitDetailScreen(
              outfit: outfit,
              controller: widget.controller,
            ),
          ),
        )
        .then((_) => widget.controller.loadSavedOutfits());
  }

  void _confirmWear(Outfit outfit) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: WardrobeTheme.elevatedSurface,
        title: Text('Wear this Outfit today?',
            style: TextStyle(color: WardrobeTheme.textPrimary)),
        content: Text(
          'Wearing "${outfit.name}" will update ${outfit.items.length} garments to WORN in Laundry Manager and record this wear event.',
          style:
              TextStyle(color: WardrobeTheme.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: WardrobeTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: WardrobeTheme.electricViolet),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await widget.controller.wearOutfit(outfit.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: ok
                        ? WardrobeTheme.elevatedSurface
                        : WardrobeTheme.statusCritical,
                    content: Text(
                      ok
                          ? 'Enjoy your look! Wear recorded.'
                          : widget.controller.errorMessage ??
                              'Failed to wear outfit.',
                    ),
                  ),
                );
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
          icon: Icon(Icons.arrow_back, color: WardrobeTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Saved Lookbook',
          style: TextStyle(
            color: WardrobeTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              controller.favoritesOnly
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: controller.favoritesOnly
                  ? WardrobeTheme.electricViolet
                  : WardrobeTheme.textMuted,
            ),
            tooltip: 'Filter Favorites',
            onPressed: () {
              controller.setFavoritesOnly(!controller.favoritesOnly);
              controller.loadSavedOutfits();
            },
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return Column(
            children: [
              // Search Bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(
                      color: WardrobeTheme.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search saved looks...',
                    hintStyle: TextStyle(color: WardrobeTheme.textMuted),
                    prefixIcon: Icon(Icons.search,
                        color: WardrobeTheme.textMuted, size: 20),
                    filled: true,
                    fillColor: WardrobeTheme.elevatedSurface,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: WardrobeTheme.borderSubtle),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: WardrobeTheme.borderSubtle),
                    ),
                  ),
                  onChanged: (q) => controller.setSearchQuery(q.trim()),
                ),
              ),

              // Occasion Filter Bar
              OutfitOccasionSelector(
                selectedOccasion: controller.selectedOccasion,
                showAllOption: true,
                onSelected: (occ) {
                  controller.setOccasion(occ);
                  controller.loadSavedOutfits();
                },
              ),
              const SizedBox(height: 10),

              Expanded(
                child: controller.isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                            color: WardrobeTheme.electricViolet))
                    : controller.savedOutfits.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.bookmarks_rounded,
                                      size: 48, color: WardrobeTheme.textMuted),
                                  const SizedBox(height: 12),
                                  Text('No saved outfits yet',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: WardrobeTheme.textPrimary)),
                                  const SizedBox(height: 6),
                                  Text(
                                      'Create outfits in Automatic, Guided or Manual mode to build your lookbook.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: WardrobeTheme.textMuted,
                                          fontSize: 13)),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            WardrobeTheme.electricViolet),
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Return to Studio',
                                        style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 24),
                            itemCount: controller.savedOutfits.length,
                            itemBuilder: (ctx, idx) {
                              final out = controller.savedOutfits[idx];
                              return OutfitCard(
                                title: out.name,
                                occasion: out.occasion,
                                explanation: out.stylingExplanation,
                                garments: out.items,
                                isAvailable: out.isAvailable,
                                wearCount: out.wearCount,
                                isFavourite: out.isFavourite,
                                isSaved: true,
                                onTap: () => _navigateToDetail(out),
                                onToggleFavourite: () =>
                                    controller.toggleFavourite(out),
                                onWear: () => _confirmWear(out),
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
