import 'package:flutter/material.dart';
import '../../domain/entities/outfit.dart';
import '../../domain/entities/outfit_item.dart';
import '../controllers/outfit_controller.dart';
import '../theme/wardrobe_theme.dart';
import '../widgets/garment_image_placeholder.dart';
import '../widgets/outfit_occasion_selector.dart';

class OutfitDetailScreen extends StatefulWidget {
  final Outfit outfit;
  final OutfitController controller;

  const OutfitDetailScreen({
    super.key,
    required this.outfit,
    required this.controller,
  });

  @override
  State<OutfitDetailScreen> createState() => _OutfitDetailScreenState();
}

class _OutfitDetailScreenState extends State<OutfitDetailScreen> {
  late Outfit _outfit;

  @override
  void initState() {
    super.initState();
    _outfit = widget.outfit;
  }

  void _showEditDialog() {
    final nameController = TextEditingController(text: _outfit.name);
    final descController =
        TextEditingController(text: _outfit.description ?? '');
    final notesController = TextEditingController(text: _outfit.notes ?? '');
    String occ = _outfit.occasion;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: WardrobeTheme.elevatedSurface,
          title: Text('Edit Outfit',
              style: TextStyle(color: WardrobeTheme.textPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
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
                  selectedOccasion: occ,
                  onSelected: (val) => setDlgState(() => occ = val),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    labelStyle: TextStyle(color: WardrobeTheme.textMuted),
                  ),
                  style: TextStyle(color: WardrobeTheme.textPrimary),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  decoration: InputDecoration(
                    labelText: 'Notes',
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
              onPressed: () async {
                Navigator.pop(ctx);
                final updated = await widget.controller.updateOutfit(
                  _outfit.id,
                  name: nameController.text.trim(),
                  description: descController.text.trim(),
                  occasion: occ,
                  notes: notesController.text.trim(),
                );
                if (mounted && updated != null) {
                  setState(() => _outfit = updated);
                }
              },
              child: const Text('Save Changes',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: WardrobeTheme.elevatedSurface,
        title: Text('Delete Outfit?',
            style: TextStyle(color: WardrobeTheme.textPrimary)),
        content: Text(
          'This will remove the look from your saved lookbook. Your physical garments will remain in your wardrobe.',
          style: TextStyle(color: WardrobeTheme.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: WardrobeTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: WardrobeTheme.statusCritical),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await widget.controller.deleteOutfit(_outfit.id);
              if (mounted && ok) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Outfit deleted from lookbook.')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmWear() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: WardrobeTheme.elevatedSurface,
        title: Text('Wear this Outfit today?',
            style: TextStyle(color: WardrobeTheme.textPrimary)),
        content: Text(
          'Wearing "${_outfit.name}" will update all constituent garments to WORN in Laundry Manager and increment their wear counts.',
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
              final ok = await widget.controller.wearOutfit(_outfit.id);
              if (mounted) {
                if (ok) {
                  setState(() {
                    _outfit = _outfit.copyWith(
                      wearCount: _outfit.wearCount + 1,
                      lastWornDate: DateTime.now(),
                    );
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Look wear recorded! Garments moved to Worn.')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: WardrobeTheme.statusCritical,
                      content: Text(widget.controller.errorMessage ??
                          'Failed to wear outfit.'),
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
          _outfit.name,
          style: TextStyle(
            color: WardrobeTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit_outlined,
                color: WardrobeTheme.textPrimary),
            tooltip: 'Edit Outfit',
            onPressed: _showEditDialog,
          ),
          IconButton(
            icon: Icon(Icons.delete_outline,
                color: WardrobeTheme.statusCritical),
            tooltip: 'Delete Outfit',
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: WardrobeTheme.elevatedSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: WardrobeTheme.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: WardrobeTheme.electricViolet
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _outfit.occasion.toUpperCase(),
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: WardrobeTheme.softViolet),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: WardrobeTheme.spatialSurface,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _outfit.creationSource.value,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: WardrobeTheme.textMuted),
                        ),
                      ),
                      const Spacer(),
                      if (_outfit.wearCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: WardrobeTheme.electricCyan
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Worn ${_outfit.wearCount}x',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: WardrobeTheme.electricCyan),
                          ),
                        ),
                    ],
                  ),
                  if (_outfit.description != null &&
                      _outfit.description!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      _outfit.description!,
                      style: TextStyle(
                          fontSize: 13,
                          color: WardrobeTheme.textSecondary,
                          height: 1.4),
                    ),
                  ],
                  if (_outfit.stylingExplanation != null &&
                      _outfit.stylingExplanation!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: WardrobeTheme.spatialSurface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.auto_awesome,
                              size: 14, color: WardrobeTheme.electricCyan),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _outfit.stylingExplanation!,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: WardrobeTheme.textSecondary,
                                  height: 1.35),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Availability Banner
            if (!_outfit.isAvailable)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: WardrobeTheme.statusWarning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color:
                          WardrobeTheme.statusWarning.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: WardrobeTheme.statusWarning, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Some garments are in laundry. Wash and dry them before wearing this look.\n${_outfit.unavailableReasons.join(', ')}',
                        style: TextStyle(
                            color: WardrobeTheme.statusWarning,
                            fontSize: 11,
                            height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),

            // Constituent Garments List
            Text(
              'CONSTITUENT GARMENTS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: WardrobeTheme.textMuted,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),

            ..._outfit.items.map((item) => _buildGarmentTile(item)),

            const SizedBox(height: 24),

            // Wear Outfit Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.checkroom_rounded, size: 18),
                label: Text(
                  _outfit.isAvailable
                      ? 'Wear This Look Today'
                      : 'Unavailable (Garments in Laundry)',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _outfit.isAvailable
                      ? WardrobeTheme.electricViolet
                      : WardrobeTheme.spatialSurface,
                  foregroundColor: _outfit.isAvailable
                      ? Colors.white
                      : WardrobeTheme.textMuted,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _outfit.isAvailable ? _confirmWear : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGarmentTile(OutfitItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: WardrobeTheme.elevatedSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.isEligible
              ? WardrobeTheme.borderSubtle
              : WardrobeTheme.statusWarning.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: WardrobeTheme.studioBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: GarmentImagePlaceholder(
              category: item.mainCategory,
              imageUrl: item.processedImageRef ??
                  item.thumbnailRef ??
                  item.originalImageRef,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: WardrobeTheme.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${item.mainCategory} • ${item.primaryColor}${item.pattern != null ? ' • ${item.pattern}' : ''}',
                  style: TextStyle(
                      fontSize: 11, color: WardrobeTheme.textMuted),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: item.isEligible
                  ? WardrobeTheme.statusSuccess.withValues(alpha: 0.15)
                  : WardrobeTheme.statusWarning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              item.laundryStatus?.label.toUpperCase() ?? 'UNASSIGNED',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: item.isEligible
                    ? WardrobeTheme.statusSuccess
                    : WardrobeTheme.statusWarning,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
