import 'package:flutter/material.dart';
import '../theme/wardrobe_theme.dart';
import 'outfit_occasion_selector.dart';

class OutfitFilterSheet extends StatefulWidget {
  final String initialOccasion;
  final bool initialExcludeWorn;
  final bool initialFavoritesOnly;
  final void Function(String occasion, bool excludeWorn, bool favoritesOnly)
      onApply;

  const OutfitFilterSheet({
    super.key,
    required this.initialOccasion,
    required this.initialExcludeWorn,
    required this.initialFavoritesOnly,
    required this.onApply,
  });

  @override
  State<OutfitFilterSheet> createState() => _OutfitFilterSheetState();
}

class _OutfitFilterSheetState extends State<OutfitFilterSheet> {
  late String _occasion;
  late bool _excludeWorn;
  late bool _favoritesOnly;

  @override
  void initState() {
    super.initState();
    _occasion = widget.initialOccasion;
    _excludeWorn = widget.initialExcludeWorn;
    _favoritesOnly = widget.initialFavoritesOnly;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: WardrobeTheme.elevatedSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Stylist Preferences',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: WardrobeTheme.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close,
                        color: WardrobeTheme.textMuted, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Occasion Section
              const Text(
                'Target Occasion',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: WardrobeTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              OutfitOccasionSelector(
                selectedOccasion: _occasion,
                onSelected: (occ) => setState(() => _occasion = occ),
                showAllOption: true,
              ),
              const SizedBox(height: 20),

              // Laundry Eligibility Policy Toggle
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: WardrobeTheme.electricViolet,
                title: const Text(
                  'Only Suggest Clean & Ready Clothes',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: WardrobeTheme.textPrimary),
                ),
                subtitle: const Text(
                  'Strictly excludes garments in laundry or marked worn',
                  style:
                      TextStyle(fontSize: 11, color: WardrobeTheme.textMuted),
                ),
                value: _excludeWorn,
                onChanged: (val) => setState(() => _excludeWorn = val),
              ),

              // Favourites Only Toggle
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: WardrobeTheme.electricViolet,
                title: const Text(
                  'Prioritize Favorite Clothes',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: WardrobeTheme.textPrimary),
                ),
                subtitle: const Text(
                  'Focus recommendations on your starred wardrobe items',
                  style:
                      TextStyle(fontSize: 11, color: WardrobeTheme.textMuted),
                ),
                value: _favoritesOnly,
                onChanged: (val) => setState(() => _favoritesOnly = val),
              ),

              const SizedBox(height: 24),

              // Apply Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WardrobeTheme.electricViolet,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    widget.onApply(_occasion, _excludeWorn, _favoritesOnly);
                    Navigator.pop(context);
                  },
                  child: const Text('Apply Styling Filters',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
