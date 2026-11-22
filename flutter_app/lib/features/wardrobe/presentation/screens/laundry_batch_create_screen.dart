import 'package:flutter/material.dart';
import '../../domain/entities/garment.dart';
import '../controllers/laundry_controller.dart';
import '../theme/wardrobe_theme.dart';
import '../widgets/garment_image_placeholder.dart';

class LaundryBatchCreateScreen extends StatefulWidget {
  final LaundryController controller;
  final List<String>? preselectedGarmentIds;

  const LaundryBatchCreateScreen({
    super.key,
    required this.controller,
    this.preselectedGarmentIds,
  });

  @override
  State<LaundryBatchCreateScreen> createState() => _LaundryBatchCreateScreenState();
}

class _LaundryBatchCreateScreenState extends State<LaundryBatchCreateScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final List<Garment> _selectedGarments = [];
  bool _isLoadingItems = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final preselected = widget.preselectedGarmentIds ?? [];
    await widget.controller.loadItemsByStatus('WORN');
    final wornItems = widget.controller.currentStatusItems;

    setState(() {
      if (preselected.isNotEmpty) {
        _selectedGarments.addAll(wornItems.where((g) => preselected.contains(g.id)));
      } else {
        // By default include all worn items or allow selection
        _selectedGarments.addAll(wornItems);
      }
      _isLoadingItems = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    if (_selectedGarments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: WardrobeTheme.elevatedSurface,
          content: Text('Please select at least one garment for this laundry batch.'),
        ),
      );
      return;
    }

    final garmentIds = _selectedGarments.map((g) => g.id).toList();
    final name = _nameController.text.trim().isEmpty ? null : _nameController.text.trim();
    final notes = _notesController.text.trim().isEmpty ? null : _notesController.text.trim();

    final batch = await widget.controller.createBatch(garmentIds, name: name, notes: notes);
    if (!mounted) return;

    if (batch != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: WardrobeTheme.elevatedSurface,
          content: Text('Created ${batch.name} with ${batch.itemsCount} garments!'),
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: WardrobeTheme.elevatedSurface,
          content: Text(widget.controller.errorMessage ?? 'Failed to create batch.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WardrobeTheme.voidBg,
      appBar: AppBar(
        backgroundColor: WardrobeTheme.voidBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: WardrobeTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'New Laundry Batch',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: WardrobeTheme.textPrimary,
          ),
        ),
      ),
      body: _isLoadingItems
          ? const Center(child: CircularProgressIndicator(color: WardrobeTheme.electricViolet))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Batch Name Input
                  TextFormField(
                    controller: _nameController,
                    style: const TextStyle(color: WardrobeTheme.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Batch Name (Optional)',
                      hintText: 'e.g. Regular Wash, Delicates, Workout Gear',
                      hintStyle: const TextStyle(color: WardrobeTheme.textMuted, fontSize: 13),
                      labelStyle: const TextStyle(color: WardrobeTheme.textSecondary, fontSize: 13),
                      filled: true,
                      fillColor: WardrobeTheme.spatialSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: WardrobeTheme.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: WardrobeTheme.border),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Optional Notes
                  TextFormField(
                    controller: _notesController,
                    style: const TextStyle(color: WardrobeTheme.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Batch Notes (Optional)',
                      hintText: 'e.g. Cold water 30°C, hang dry wool items',
                      hintStyle: const TextStyle(color: WardrobeTheme.textMuted, fontSize: 13),
                      labelStyle: const TextStyle(color: WardrobeTheme.textSecondary, fontSize: 13),
                      filled: true,
                      fillColor: WardrobeTheme.spatialSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: WardrobeTheme.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: WardrobeTheme.border),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Selected Garments List Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'GARMENTS IN BATCH',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: WardrobeTheme.textSecondary,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: WardrobeTheme.electricViolet.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${_selectedGarments.length} SELECTED',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: WardrobeTheme.softViolet,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  if (_selectedGarments.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: WardrobeTheme.spatialSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: WardrobeTheme.borderSubtle),
                      ),
                      child: const Center(
                        child: Text(
                          'No garments selected. Go to Worn clothes to select items.',
                          style: TextStyle(color: WardrobeTheme.textMuted, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _selectedGarments.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, idx) {
                        final g = _selectedGarments[idx];
                        return Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: WardrobeTheme.spatialSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: WardrobeTheme.borderSubtle),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  color: WardrobeTheme.studioBackground,
                                  child: GarmentImagePlaceholder(
                                    imageUrl: g.displayImageRef,
                                    category: g.mainCategory,
                                    width: 44,
                                    height: 44,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      g.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: WardrobeTheme.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      '${g.id} • ${g.mainCategory}',
                                      style: const TextStyle(fontSize: 11, color: WardrobeTheme.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline_rounded, color: WardrobeTheme.statusCritical, size: 20),
                                tooltip: 'Remove from batch',
                                onPressed: () {
                                  setState(() {
                                    _selectedGarments.removeAt(idx);
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 28),

                  ElevatedButton(
                    onPressed: _selectedGarments.isEmpty ? null : _handleCreate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: WardrobeTheme.electricViolet,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: WardrobeTheme.electricViolet.withValues(alpha: 0.3),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      'Start Batch (${_selectedGarments.length} Garments)',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
