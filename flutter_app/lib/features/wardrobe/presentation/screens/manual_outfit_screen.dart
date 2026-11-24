import 'package:flutter/material.dart';
import '../../data/repositories/wardrobe_repository_impl.dart';
import '../../domain/entities/garment.dart';
import '../../domain/entities/outfit.dart';
import '../controllers/outfit_controller.dart';
import '../theme/wardrobe_theme.dart';
import '../widgets/garment_selection_grid.dart';
import '../widgets/outfit_occasion_selector.dart';

class ManualOutfitScreen extends StatefulWidget {
  final OutfitController controller;

  const ManualOutfitScreen({
    super.key,
    required this.controller,
  });

  @override
  State<ManualOutfitScreen> createState() => _ManualOutfitScreenState();
}

class _ManualOutfitScreenState extends State<ManualOutfitScreen> {
  List<Garment> _allGarments = [];
  String _selectedCategory = 'All';
  bool _isLoading = true;

  final List<String> _categories = [
    'All',
    'Tops',
    'Bottoms',
    'Dresses',
    'Ethnic wear',
    'Outerwear',
    'Shoes',
    'Accessories',
  ];

  @override
  void initState() {
    super.initState();
    widget.controller.clearManualSelection();
    _loadGarments();
  }

  Future<void> _loadGarments() async {
    setState(() => _isLoading = true);
    try {
      final repo = WardrobeRepositoryImpl();
      final items = await repo.getGarments();
      if (mounted) {
        setState(() {
          _allGarments = items;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Garment> get _filteredGarments {
    if (_selectedCategory == 'All') return _allGarments;
    return _allGarments
        .where((g) =>
            g.mainCategory.toLowerCase() == _selectedCategory.toLowerCase())
        .toList();
  }

  Future<void> _executeSave(String name, String occasion, String notes) async {
    final saved = await widget.controller.saveOutfit(
      name: name.trim().isNotEmpty ? name.trim() : 'Custom Outfit',
      occasion: occasion,
      notes: notes.trim(),
      creationSource: OutfitSource.manual,
      garmentIds: widget.controller.manualSelectedGarmentIds,
    );
    if (saved != null && mounted) {
      Navigator.pop(context); // Return to studio
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved "${saved.name}" to lookbook!')),
      );
    }
  }

  void _showSaveDialog() {
    final nameController = TextEditingController(text: 'My Custom Look');
    final notesController = TextEditingController();
    String occasion = 'Casual';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: WardrobeTheme.elevatedSurface,
          title: Text('Save Custom Outfit',
              style: TextStyle(color: WardrobeTheme.textPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Outfit Name',
                    labelStyle: TextStyle(color: WardrobeTheme.textMuted),
                  ),
                  style: TextStyle(color: WardrobeTheme.textPrimary),
                ),
                const SizedBox(height: 12),
                Text('Occasion',
                    style: TextStyle(
                        color: WardrobeTheme.textSecondary, fontSize: 12)),
                const SizedBox(height: 6),
                OutfitOccasionSelector(
                  selectedOccasion: occasion,
                  onSelected: (occ) => setDlgState(() => occasion = occ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  decoration: InputDecoration(
                    labelText: 'Notes (optional)',
                    labelStyle: TextStyle(color: WardrobeTheme.textMuted),
                  ),
                  style: TextStyle(color: WardrobeTheme.textPrimary),
                ),
              ],
            ),
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
              onPressed: () {
                Navigator.pop(ctx);
                _executeSave(
                    nameController.text, occasion, notesController.text);
              },
              child: const Text('Save to Lookbook',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
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
          'Manual Outfit Builder',
          style: TextStyle(
            color: WardrobeTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (controller.manualSelectedGarmentIds.isNotEmpty)
            TextButton(
              onPressed: () => controller.clearManualSelection(),
              child: Text('Clear',
                  style: TextStyle(color: WardrobeTheme.statusCritical)),
            ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                  color: WardrobeTheme.electricViolet))
          : Column(
              children: [
                // Category Filter Bar
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (ctx, idx) {
                      final cat = _categories[idx];
                      final isSelected = cat == _selectedCategory;
                      return ChoiceChip(
                        label: Text(cat,
                            style: TextStyle(
                                fontSize: 12,
                                color: isSelected
                                    ? Colors.white
                                    : WardrobeTheme.textSecondary)),
                        selected: isSelected,
                        selectedColor: WardrobeTheme.electricViolet,
                        backgroundColor: WardrobeTheme.elevatedSurface,
                        onSelected: (_) =>
                            setState(() => _selectedCategory = cat),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),

                // Garments Grid
                Expanded(
                  child: GarmentSelectionGrid(
                    garments: _filteredGarments,
                    selectedGarmentIds: controller.manualSelectedGarmentIds,
                    onToggleGarment: (g) =>
                        controller.toggleGarmentSelection(g.id),
                  ),
                ),

                // Bottom Validation & Action Drawer
                if (controller.manualSelectedGarmentIds.isNotEmpty)
                  AnimatedBuilder(
                    animation: controller,
                    builder: (context, _) {
                      final val = controller.manualValidationResult;
                      final isWearable = val?['is_wearable'] ?? true;
                      final conflicts =
                          (val?['conflicts'] as List<dynamic>?) ?? [];

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: WardrobeTheme.elevatedSurface,
                          border: Border(
                            top: BorderSide(
                              color: isWearable
                                  ? WardrobeTheme.borderSubtle
                                  : WardrobeTheme.statusWarning,
                              width: 1,
                            ),
                          ),
                        ),
                        child: SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    isWearable
                                        ? Icons.check_circle
                                        : Icons.warning_amber_rounded,
                                    size: 16,
                                    color: isWearable
                                        ? WardrobeTheme.statusSuccess
                                        : WardrobeTheme.statusWarning,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${controller.manualSelectedGarmentIds.length} garments selected',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: WardrobeTheme.textPrimary,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    isWearable
                                        ? 'READY FOR WEAR'
                                        : 'HAS CONFLICTS',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: isWearable
                                          ? WardrobeTheme.statusSuccess
                                          : WardrobeTheme.statusWarning,
                                    ),
                                  ),
                                ],
                              ),
                              if (conflicts.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  conflicts.join('\n'),
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: WardrobeTheme.statusWarning),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.bookmark_add_rounded,
                                      size: 18),
                                  label: const Text('Save Outfit to Lookbook',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        WardrobeTheme.electricViolet,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                  ),
                                  onPressed: _showSaveDialog,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
    );
  }
}
