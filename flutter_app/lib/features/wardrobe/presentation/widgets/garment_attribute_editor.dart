import 'package:flutter/material.dart';
import '../../domain/entities/garment_candidate.dart';
import '../theme/wardrobe_theme.dart';

/// Modal bottom sheet allowing immediate review and correction of AI-detected attributes.
class GarmentAttributeEditor extends StatefulWidget {
  final GarmentCandidate candidate;
  final ValueChanged<GarmentCandidate> onSave;

  const GarmentAttributeEditor({
    super.key,
    required this.candidate,
    required this.onSave,
  });

  @override
  State<GarmentAttributeEditor> createState() => _GarmentAttributeEditorState();
}

class _GarmentAttributeEditorState extends State<GarmentAttributeEditor> {
  late TextEditingController _nameController;
  late TextEditingController _primaryColorController;
  late TextEditingController _patternController;
  late TextEditingController _fabricController;
  late TextEditingController _sleeveController;
  late TextEditingController _necklineController;
  late TextEditingController _fitController;
  late TextEditingController _brandController;
  late String _selectedCategory;

  final List<String> _categories = [
    'Tops',
    'Bottoms',
    'Ethnic Wear',
    'Dresses',
    'Outerwear',
    'Activewear',
    'Footwear',
    'Accessories',
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.candidate;
    _nameController = TextEditingController(text: c.suggestedName);
    _primaryColorController = TextEditingController(text: c.primaryColor);
    _patternController = TextEditingController(text: c.pattern ?? 'Solid');
    _fabricController = TextEditingController(text: c.fabricMaterial ?? '');
    _sleeveController = TextEditingController(text: c.sleeveLength ?? '');
    _necklineController = TextEditingController(text: c.neckline ?? '');
    _fitController = TextEditingController(text: c.fit ?? 'Regular Fit');
    _brandController = TextEditingController(text: c.brand ?? '');
    _selectedCategory = c.mainCategory;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _primaryColorController.dispose();
    _patternController.dispose();
    _fabricController.dispose();
    _sleeveController.dispose();
    _necklineController.dispose();
    _fitController.dispose();
    _brandController.dispose();
    super.dispose();
  }

  void _save() {
    final updated = widget.candidate.copyWith(
      suggestedName: _nameController.text.trim().isEmpty ? 'Detected Garment' : _nameController.text.trim(),
      mainCategory: _selectedCategory,
      primaryColor: _primaryColorController.text.trim(),
      pattern: _patternController.text.trim().isEmpty ? null : _patternController.text.trim(),
      fabricMaterial: _fabricController.text.trim().isEmpty ? null : _fabricController.text.trim(),
      sleeveLength: _sleeveController.text.trim().isEmpty ? null : _sleeveController.text.trim(),
      neckline: _necklineController.text.trim().isEmpty ? null : _necklineController.text.trim(),
      fit: _fitController.text.trim().isEmpty ? null : _fitController.text.trim(),
      brand: _brandController.text.trim().isEmpty ? null : _brandController.text.trim(),
    );
    widget.onSave(updated);
    Navigator.of(context).pop();
  }

  InputDecoration _inputDeco(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: WardrobeTheme.textSecondary, fontSize: 13),
      filled: true,
      fillColor: WardrobeTheme.spatialSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: WardrobeTheme.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: WardrobeTheme.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: WardrobeTheme.electricViolet, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          top: 16.0,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16.0,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Correct Detected Attributes',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: WardrobeTheme.textPrimary),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: WardrobeTheme.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Name
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: WardrobeTheme.textPrimary, fontSize: 14),
                decoration: _inputDeco('Garment Name'),
              ),
              const SizedBox(height: 10),

              // Category
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                dropdownColor: WardrobeTheme.elevatedSurface,
                style: const TextStyle(color: WardrobeTheme.textPrimary, fontSize: 14),
                decoration: _inputDeco('Category'),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
              const SizedBox(height: 10),

              // Color & Pattern
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _primaryColorController,
                      style: const TextStyle(color: WardrobeTheme.textPrimary, fontSize: 14),
                      decoration: _inputDeco('Primary Color'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _patternController,
                      style: const TextStyle(color: WardrobeTheme.textPrimary, fontSize: 14),
                      decoration: _inputDeco('Pattern'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Sleeves & Neckline (if applicable)
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _sleeveController,
                      style: const TextStyle(color: WardrobeTheme.textPrimary, fontSize: 14),
                      decoration: _inputDeco('Sleeve Length'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _necklineController,
                      style: const TextStyle(color: WardrobeTheme.textPrimary, fontSize: 14),
                      decoration: _inputDeco('Neckline'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Fabric & Fit
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _fabricController,
                      style: const TextStyle(color: WardrobeTheme.textPrimary, fontSize: 14),
                      decoration: _inputDeco('Fabric Appearance'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _fitController,
                      style: const TextStyle(color: WardrobeTheme.textPrimary, fontSize: 14),
                      decoration: _inputDeco('Fit'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _brandController,
                style: const TextStyle(color: WardrobeTheme.textPrimary, fontSize: 14),
                decoration: _inputDeco('Brand / Retailer'),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: WardrobeTheme.electricViolet,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Save Attributes', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
