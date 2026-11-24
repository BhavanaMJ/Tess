import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../domain/entities/garment_metadata_v1_1.dart';
import '../controllers/garment_import_controller.dart';
import '../theme/wardrobe_theme.dart';

class ImportStage4Review extends StatefulWidget {
  final GarmentImportController controller;
  final VoidCallback onRegistered;

  const ImportStage4Review({
    super.key,
    required this.controller,
    required this.onRegistered,
  });

  @override
  State<ImportStage4Review> createState() => _ImportStage4ReviewState();
}

class _ImportStage4ReviewState extends State<ImportStage4Review> {
  // Collapsible section states
  bool _expandAppearance = true;
  bool _expandConstruction = true;
  bool _expandMaterial = false;
  bool _expandSizing = false;
  bool _expandUsage = false;
  bool _expandCare = false;

  void _openEditFieldDialog({
    required String title,
    required String initialValue,
    required ValueChanged<String> onSaved,
  }) {
    final textController = TextEditingController(text: initialValue);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: WardrobeTheme.elevatedSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          'Edit $title',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: WardrobeTheme.textPrimary),
        ),
        content: TextField(
          controller: textController,
          autofocus: true,
          style: TextStyle(color: WardrobeTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'Enter $title',
            hintStyle: TextStyle(color: WardrobeTheme.textMuted),
            filled: true,
            fillColor: WardrobeTheme.spatialSurface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: WardrobeTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              onSaved(textController.text.trim());
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: WardrobeTheme.electricViolet,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showRegistrationConfirmation() {
    final meta = widget.controller.metadata;
    if (meta == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: WardrobeTheme.elevatedSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.checkroom_rounded, color: WardrobeTheme.electricCyan, size: 24),
            const SizedBox(width: 8),
            Text(
              'Add to My Wardrobe?',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: WardrobeTheme.textPrimary),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Register "${meta.identity.garmentName}" into your permanent wardrobe collection.',
              style: TextStyle(fontSize: 13, color: WardrobeTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: WardrobeTheme.spatialSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: WardrobeTheme.borderSubtle),
              ),
              child: Column(
                children: [
                  _buildSummaryMiniRow('Category', meta.identity.category ?? 'Tops'),
                  _buildSummaryMiniRow('Primary Colour', meta.appearance.primaryColour ?? 'Unknown'),
                  _buildSummaryMiniRow('Laundry Status', 'Unassigned (null initially)'),
                  _buildSummaryMiniRow('Provenance', 'User Imported (ChatGPT Project)'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Review More', style: TextStyle(color: WardrobeTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await widget.controller.registerGarment();
              if (success && mounted) {
                widget.onRegistered();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: WardrobeTheme.electricViolet,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Confirm & Register'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryMiniRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: WardrobeTheme.textMuted)),
          Text(val, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: WardrobeTheme.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildProvenanceBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }

  Widget _buildAttributeRow({
    required String label,
    required String? value,
    required VoidCallback onEdit,
    String status = 'AI_DETECTED', // AI_DETECTED, USER_VERIFIED, UNKNOWN
  }) {
    final isUnknown = value == null || value.trim().isEmpty || value == 'Unknown';
    Color badgeColor;
    String badgeText;

    if (isUnknown) {
      badgeColor = WardrobeTheme.textMuted;
      badgeText = 'Unknown';
    } else if (status == 'USER_VERIFIED') {
      badgeColor = WardrobeTheme.statusSuccess;
      badgeText = 'User Verified';
    } else {
      badgeColor = WardrobeTheme.softViolet;
      badgeText = 'AI Detected';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: WardrobeTheme.textSecondary),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              isUnknown ? '—' : value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isUnknown ? FontWeight.normal : FontWeight.w700,
                color: isUnknown ? WardrobeTheme.textMuted : WardrobeTheme.textPrimary,
              ),
            ),
          ),
          _buildProvenanceBadge(badgeText, badgeColor),
          IconButton(
            icon: Icon(Icons.edit_outlined, size: 16, color: WardrobeTheme.electricCyan),
            tooltip: 'Edit $label',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required bool isExpanded,
    required VoidCallback onToggle,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: WardrobeTheme.spatialSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WardrobeTheme.borderSubtle),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(icon, size: 18, color: WardrobeTheme.electricCyan),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: WardrobeTheme.textPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    color: WardrobeTheme.textMuted,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            Divider(color: WardrobeTheme.borderSubtle, height: 1),
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(children: children),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final meta = widget.controller.metadata;
    final isRegistering = widget.controller.isRegistering;
    final error = widget.controller.errorMessage;

    if (meta == null) {
      return Center(
        child: Text('No metadata available for review.', style: TextStyle(color: WardrobeTheme.textMuted)),
      );
    }

    final identity = meta.identity;
    final appearance = meta.appearance;
    final construction = meta.construction;
    final material = meta.material;
    final sizing = meta.sizing;
    final usage = meta.usage;
    final purchase = meta.purchase;
    final care = meta.care;
    final location = meta.physicalLocation;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Visual Assets Showcase (Studio Catalogue + Original Photo)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: WardrobeTheme.spatialSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: WardrobeTheme.borderViolet),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _buildProvenanceBadge('Catalogue Image (Primary)', WardrobeTheme.electricViolet),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 180,
                            decoration: BoxDecoration(
                              color: WardrobeTheme.studioBackground,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: widget.controller.catalogueImageBytes != null
                                ? Image.memory(
                                    Uint8List.fromList(widget.controller.catalogueImageBytes!),
                                    fit: BoxFit.contain,
                                    width: double.infinity,
                                  )
                                : Center(child: Icon(Icons.checkroom, color: WardrobeTheme.textMuted)),
                          ),
                        ],
                      ),
                    ),
                    if (widget.controller.hasOriginalImage) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _buildProvenanceBadge('Original Photo', WardrobeTheme.textMuted),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 180,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: widget.controller.originalImageBytes != null
                                  ? Image.memory(
                                      Uint8List.fromList(widget.controller.originalImageBytes!),
                                      fit: BoxFit.contain,
                                      width: double.infinity,
                                    )
                                  : Center(child: Icon(Icons.image, color: WardrobeTheme.textMuted)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  identity.garmentName ?? 'Untitled Garment',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: WardrobeTheme.textPrimary),
                ),
                Text(
                  '${identity.category ?? "Tops"}${identity.subcategory != null ? " • ${identity.subcategory}" : ""}',
                  style: TextStyle(fontSize: 12, color: WardrobeTheme.softViolet, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          if (error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: WardrobeTheme.statusCritical.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: WardrobeTheme.statusCritical.withValues(alpha: 0.3)),
              ),
              child: Text(error, style: TextStyle(color: WardrobeTheme.statusCritical, fontSize: 12)),
            ),
          ],

          const SizedBox(height: 16),

          // 1. Appearance & Colours
          _buildSectionCard(
            title: 'Appearance & Colours',
            icon: Icons.palette_outlined,
            isExpanded: _expandAppearance,
            onToggle: () => setState(() => _expandAppearance = !_expandAppearance),
            children: [
              _buildAttributeRow(
                label: 'Primary Colour',
                value: appearance.primaryColour,
                onEdit: () => _openEditFieldDialog(
                  title: 'Primary Colour',
                  initialValue: appearance.primaryColour ?? '',
                  onSaved: (v) => widget.controller.updateMetadata(
                    meta.copyWith(appearance: appearance.copyWith(primaryColour: v)),
                  ),
                ),
              ),
              _buildAttributeRow(
                label: 'Secondary Colours',
                value: appearance.secondaryColours.isEmpty ? null : appearance.secondaryColours.join(', '),
                onEdit: () => _openEditFieldDialog(
                  title: 'Secondary Colours (comma-separated)',
                  initialValue: appearance.secondaryColours.join(', '),
                  onSaved: (v) => widget.controller.updateMetadata(
                    meta.copyWith(
                      appearance: appearance.copyWith(
                        secondaryColours: v.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
                      ),
                    ),
                  ),
                ),
              ),
              _buildAttributeRow(
                label: 'Pattern',
                value: appearance.pattern,
                onEdit: () => _openEditFieldDialog(
                  title: 'Pattern',
                  initialValue: appearance.pattern ?? '',
                  onSaved: (v) => widget.controller.updateMetadata(
                    meta.copyWith(appearance: appearance.copyWith(pattern: v)),
                  ),
                ),
              ),
              _buildAttributeRow(
                label: 'Visual Texture',
                value: appearance.visualTexture,
                onEdit: () => _openEditFieldDialog(
                  title: 'Visual Texture',
                  initialValue: appearance.visualTexture ?? '',
                  onSaved: (v) => widget.controller.updateMetadata(
                    meta.copyWith(appearance: appearance.copyWith(visualTexture: v)),
                  ),
                ),
              ),
            ],
          ),

          // 2. Construction & Silhouette
          _buildSectionCard(
            title: 'Construction & Fit',
            icon: Icons.straighten_outlined,
            isExpanded: _expandConstruction,
            onToggle: () => setState(() => _expandConstruction = !_expandConstruction),
            children: [
              _buildAttributeRow(
                label: 'Neckline',
                value: construction.neckline,
                onEdit: () => _openEditFieldDialog(
                  title: 'Neckline',
                  initialValue: construction.neckline ?? '',
                  onSaved: (v) => widget.controller.updateMetadata(
                    meta.copyWith(construction: construction.copyWith(neckline: v)),
                  ),
                ),
              ),
              _buildAttributeRow(
                label: 'Sleeve Length',
                value: construction.sleeveLength,
                onEdit: () => _openEditFieldDialog(
                  title: 'Sleeve Length',
                  initialValue: construction.sleeveLength ?? '',
                  onSaved: (v) => widget.controller.updateMetadata(
                    meta.copyWith(construction: construction.copyWith(sleeveLength: v)),
                  ),
                ),
              ),
              _buildAttributeRow(
                label: 'Fit',
                value: construction.fit,
                onEdit: () => _openEditFieldDialog(
                  title: 'Fit',
                  initialValue: construction.fit ?? '',
                  onSaved: (v) => widget.controller.updateMetadata(
                    meta.copyWith(construction: construction.copyWith(fit: v)),
                  ),
                ),
              ),
              _buildAttributeRow(
                label: 'Silhouette',
                value: construction.silhouette,
                onEdit: () => _openEditFieldDialog(
                  title: 'Silhouette',
                  initialValue: construction.silhouette ?? '',
                  onSaved: (v) => widget.controller.updateMetadata(
                    meta.copyWith(construction: construction.copyWith(silhouette: v)),
                  ),
                ),
              ),
              _buildAttributeRow(
                label: 'Garment Length',
                value: construction.garmentLength,
                onEdit: () => _openEditFieldDialog(
                  title: 'Garment Length',
                  initialValue: construction.garmentLength ?? '',
                  onSaved: (v) => widget.controller.updateMetadata(
                    meta.copyWith(construction: construction.copyWith(garmentLength: v)),
                  ),
                ),
              ),
            ],
          ),

          // 3. Material & Fabric
          _buildSectionCard(
            title: 'Fabric & Composition',
            icon: Icons.texture_rounded,
            isExpanded: _expandMaterial,
            onToggle: () => setState(() => _expandMaterial = !_expandMaterial),
            children: [
              _buildAttributeRow(
                label: 'Fabric Appearance',
                value: material.fabricAppearance,
                onEdit: () => _openEditFieldDialog(
                  title: 'Fabric Appearance',
                  initialValue: material.fabricAppearance ?? '',
                  onSaved: (v) => widget.controller.updateMetadata(
                    meta.copyWith(material: material.copyWith(fabricAppearance: v)),
                  ),
                ),
              ),
              _buildAttributeRow(
                label: 'Primary Material',
                value: material.primaryMaterial,
                onEdit: () => _openEditFieldDialog(
                  title: 'Primary Material',
                  initialValue: material.primaryMaterial ?? '',
                  onSaved: (v) => widget.controller.updateMetadata(
                    meta.copyWith(material: material.copyWith(primaryMaterial: v)),
                  ),
                ),
              ),
              _buildAttributeRow(
                label: 'Composition',
                value: material.fabricComposition,
                onEdit: () => _openEditFieldDialog(
                  title: 'Fabric Composition',
                  initialValue: material.fabricComposition ?? '',
                  onSaved: (v) => widget.controller.updateMetadata(
                    meta.copyWith(material: material.copyWith(fabricComposition: v)),
                  ),
                ),
              ),
            ],
          ),

          // 4. Sizing & Brand
          _buildSectionCard(
            title: 'Sizing & Brand',
            icon: Icons.format_size_rounded,
            isExpanded: _expandSizing,
            onToggle: () => setState(() => _expandSizing = !_expandSizing),
            children: [
              _buildAttributeRow(
                label: 'Labelled Size',
                value: sizing.labelledSize,
                onEdit: () => _openEditFieldDialog(
                  title: 'Labelled Size',
                  initialValue: sizing.labelledSize ?? '',
                  onSaved: (v) => widget.controller.updateMetadata(
                    meta.copyWith(sizing: sizing.copyWith(labelledSize: v)),
                  ),
                ),
              ),
              _buildAttributeRow(
                label: 'Brand',
                value: purchase.brand,
                onEdit: () => _openEditFieldDialog(
                  title: 'Brand',
                  initialValue: purchase.brand ?? '',
                  onSaved: (v) => widget.controller.updateMetadata(
                    meta.copyWith(purchase: purchase.copyWith(brand: v)),
                  ),
                ),
              ),
            ],
          ),

          // 5. Usage & Occasions
          _buildSectionCard(
            title: 'Usage, Occasions & Seasons',
            icon: Icons.calendar_today_rounded,
            isExpanded: _expandUsage,
            onToggle: () => setState(() => _expandUsage = !_expandUsage),
            children: [
              _buildAttributeRow(
                label: 'Occasions',
                value: usage.occasions.isEmpty ? null : usage.occasions.join(', '),
                onEdit: () => _openEditFieldDialog(
                  title: 'Occasions (comma-separated)',
                  initialValue: usage.occasions.join(', '),
                  onSaved: (v) => widget.controller.updateMetadata(
                    meta.copyWith(
                      usage: usage.copyWith(
                        occasions: v.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
                      ),
                    ),
                  ),
                ),
              ),
              _buildAttributeRow(
                label: 'Seasons',
                value: usage.seasons.isEmpty ? null : usage.seasons.join(', '),
                onEdit: () => _openEditFieldDialog(
                  title: 'Seasons (comma-separated)',
                  initialValue: usage.seasons.join(', '),
                  onSaved: (v) => widget.controller.updateMetadata(
                    meta.copyWith(
                      usage: usage.copyWith(
                        seasons: v.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // 6. Care & Storage
          _buildSectionCard(
            title: 'Care & Physical Location',
            icon: Icons.local_laundry_service_outlined,
            isExpanded: _expandCare,
            onToggle: () => setState(() => _expandCare = !_expandCare),
            children: [
              _buildAttributeRow(
                label: 'Washing Method',
                value: care.washingMethod,
                onEdit: () => _openEditFieldDialog(
                  title: 'Washing Method',
                  initialValue: care.washingMethod ?? '',
                  onSaved: (v) => widget.controller.updateMetadata(
                    meta.copyWith(care: CareSection(washingMethod: v)),
                  ),
                ),
              ),
              _buildAttributeRow(
                label: 'Storage Location',
                value: location.storageLocation,
                onEdit: () => _openEditFieldDialog(
                  title: 'Storage Location',
                  initialValue: location.storageLocation ?? '',
                  onSaved: (v) => widget.controller.updateMetadata(
                    meta.copyWith(physicalLocation: PhysicalLocationSection(storageLocation: v)),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Final Add to My Wardrobe Button
          ElevatedButton.icon(
            onPressed: isRegistering ? null : _showRegistrationConfirmation,
            icon: isRegistering
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.checkroom_rounded, size: 20),
            label: Text(
              isRegistering ? 'Registering Garment...' : 'Add to My Wardrobe',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: WardrobeTheme.electricViolet,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
