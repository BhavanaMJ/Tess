import 'package:flutter/material.dart';
import '../../domain/entities/garment.dart';
import '../../domain/entities/laundry_status.dart';
import '../controllers/wardrobe_controller.dart';
import '../theme/wardrobe_theme.dart';

/// Screen for adding or editing a garment in the digital wardrobe.
/// Features category-sensitive attributes, validation, and dark spatial styling.
class GarmentFormScreen extends StatefulWidget {
  final WardrobeController controller;
  final Garment? garment; // If null, creating new; otherwise editing
  final String userId;

  const GarmentFormScreen({
    super.key,
    required this.controller,
    this.garment,
    this.userId = 'tess_user',
  });

  @override
  State<GarmentFormScreen> createState() => _GarmentFormScreenState();
}

class _GarmentFormScreenState extends State<GarmentFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _subcategoryController;
  late TextEditingController _primaryColorController;
  late TextEditingController _secondaryColorsController;
  late TextEditingController _patternController;
  late TextEditingController _fabricController;
  late TextEditingController _sleeveLengthController;
  late TextEditingController _necklineController;
  late TextEditingController _fitController;
  late TextEditingController _silhouetteController;
  late TextEditingController _sizeController;
  late TextEditingController _brandController;
  late TextEditingController _priceController;
  late TextEditingController _notesController;

  String _selectedCategory = 'Tops';
  LaundryStatus? _selectedLaundryStatus;
  bool _isFavorite = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  final List<String> _commonCategories = [
    'Tops',
    'Bottoms',
    'Ethnic Wear',
    'Dresses',
    'Outerwear',
    'Footwear',
    'Accessories',
    'Activewear',
    'Sleepwear',
  ];

  final List<String> _commonColors = [
    'Navy Blue',
    'Light Blue',
    'White',
    'Black',
    'Charcoal',
    'Grey',
    'Beige',
    'Olive Green',
    'Burgundy',
    'Red',
    'Yellow',
    'Pink',
    'Brown',
  ];

  final List<String> _commonSleeves = [
    'Short Sleeves',
    'Full Sleeves',
    '3/4 Sleeves',
    'Sleeveless',
    'Cap Sleeves',
  ];

  final List<String> _commonFits = [
    'Slim Fit',
    'Regular Fit',
    'Relaxed Fit',
    'Oversized',
    'Tailored',
    'Skinny',
    'Straight',
  ];

  bool get _isEditing => widget.garment != null;

  bool get _showsSleeveAndNeckline {
    final cat = _selectedCategory.toLowerCase();
    return cat == 'tops' || cat == 'ethnic wear' || cat == 'dresses' || cat == 'outerwear';
  }

  @override
  void initState() {
    super.initState();
    final g = widget.garment;

    _nameController = TextEditingController(text: g?.name ?? '');
    _subcategoryController = TextEditingController(text: g?.subcategory ?? '');
    _primaryColorController = TextEditingController(text: g?.primaryColor ?? 'Navy Blue');
    _secondaryColorsController = TextEditingController(text: g?.secondaryColors.join(', ') ?? '');
    _patternController = TextEditingController(text: g?.pattern ?? 'Solid');
    _fabricController = TextEditingController(text: g?.fabricMaterial ?? 'Cotton');
    _sleeveLengthController = TextEditingController(text: g?.sleeveLength ?? '');
    _necklineController = TextEditingController(text: g?.neckline ?? '');
    _fitController = TextEditingController(text: g?.fit ?? 'Regular Fit');
    _silhouetteController = TextEditingController(text: g?.silhouette ?? '');
    _sizeController = TextEditingController(text: g?.size ?? 'M');
    _brandController = TextEditingController(text: g?.brand ?? '');
    _priceController = TextEditingController(text: g?.purchasePrice != null ? g!.purchasePrice.toString() : '');
    _notesController = TextEditingController(text: g?.notes ?? '');

    if (g != null) {
      _selectedCategory = g.mainCategory;
      _selectedLaundryStatus = g.laundryStatus;
      _isFavorite = g.isFavorite;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subcategoryController.dispose();
    _primaryColorController.dispose();
    _secondaryColorsController.dispose();
    _patternController.dispose();
    _fabricController.dispose();
    _sleeveLengthController.dispose();
    _necklineController.dispose();
    _fitController.dispose();
    _silhouetteController.dispose();
    _sizeController.dispose();
    _brandController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final now = DateTime.now();
      final secColors = _secondaryColorsController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final price = double.tryParse(_priceController.text.trim());

      final garmentToSave = Garment(
        id: widget.garment?.id ?? 'CLO-${DateTime.now().millisecondsSinceEpoch % 100000}',
        userId: widget.garment?.userId ?? widget.userId,
        name: _nameController.text.trim(),
        mainCategory: _selectedCategory,
        subcategory: _subcategoryController.text.trim().isEmpty ? null : _subcategoryController.text.trim(),
        originalImageRef: widget.garment?.originalImageRef,
        processedImageRef: widget.garment?.processedImageRef,
        thumbnailRef: widget.garment?.thumbnailRef,
        primaryColor: _primaryColorController.text.trim().isEmpty ? 'Navy Blue' : _primaryColorController.text.trim(),
        secondaryColors: secColors,
        pattern: _patternController.text.trim().isEmpty ? null : _patternController.text.trim(),
        fabricMaterial: _fabricController.text.trim().isEmpty ? null : _fabricController.text.trim(),
        neckline: _showsSleeveAndNeckline && _necklineController.text.trim().isNotEmpty
            ? _necklineController.text.trim()
            : null,
        sleeveLength: _showsSleeveAndNeckline && _sleeveLengthController.text.trim().isNotEmpty
            ? _sleeveLengthController.text.trim()
            : null,
        fit: _fitController.text.trim().isEmpty ? null : _fitController.text.trim(),
        silhouette: _silhouetteController.text.trim().isEmpty ? null : _silhouetteController.text.trim(),
        size: _sizeController.text.trim().isEmpty ? null : _sizeController.text.trim(),
        brand: _brandController.text.trim().isEmpty ? null : _brandController.text.trim(),
        purchasePrice: price,
        laundryStatus: _selectedLaundryStatus,
        isFavorite: _isFavorite,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        createdAt: widget.garment?.createdAt ?? now,
        updatedAt: now,
      );

      Garment result;
      if (_isEditing) {
        result = await widget.controller.updateGarment(garmentToSave);
      } else {
        result = await widget.controller.addGarment(garmentToSave);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: WardrobeTheme.elevatedSurface,
            content: Text(
              _isEditing ? 'Garment updated successfully' : 'Garment added to wardrobe',
              style: const TextStyle(color: WardrobeTheme.textPrimary),
            ),
          ),
        );
        Navigator.of(context).pop(result);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isSubmitting = false;
        });
      }
    }
  }

  InputDecoration _inputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: WardrobeTheme.textSecondary, fontSize: 13),
      hintStyle: const TextStyle(color: WardrobeTheme.textMuted, fontSize: 12),
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
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: WardrobeTheme.electricViolet, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: WardrobeTheme.statusCritical),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
          icon: const Icon(Icons.arrow_back, color: WardrobeTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _isEditing ? 'Edit Garment' : 'Add New Garment',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: WardrobeTheme.textPrimary,
            letterSpacing: -0.4,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: _isFavorite ? WardrobeTheme.statusCritical : WardrobeTheme.textMuted,
            ),
            tooltip: 'Mark as Favorite',
            onPressed: () => setState(() => _isFavorite = !_isFavorite),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: TextButton(
              onPressed: _isSubmitting ? null : _handleSave,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: WardrobeTheme.electricCyan),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(
                        color: WardrobeTheme.electricCyan,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: WardrobeTheme.statusCritical.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: WardrobeTheme.statusCritical.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: WardrobeTheme.statusCritical, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 1. Core Identification
              const Text(
                'GARMENT IDENTIFICATION',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: WardrobeTheme.textMuted,
                ),
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: WardrobeTheme.textPrimary, fontSize: 14),
                decoration: _inputDecoration('Garment Name *', hint: 'e.g. Navy Oxford Cotton Shirt'),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a garment name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Category Selector
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                dropdownColor: WardrobeTheme.elevatedSurface,
                style: const TextStyle(color: WardrobeTheme.textPrimary, fontSize: 14),
                decoration: _inputDecoration('Main Category *'),
                items: _commonCategories.map((cat) {
                  return DropdownMenuItem<String>(
                    value: cat,
                    child: Text(cat),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedCategory = val);
                  }
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _subcategoryController,
                style: const TextStyle(color: WardrobeTheme.textPrimary, fontSize: 14),
                decoration: _inputDecoration('Subcategory', hint: 'e.g. Button-down, Chino, Kurta'),
              ),
              const SizedBox(height: 20),

              // 2. Visual & Material Attributes
              const Text(
                'VISUAL & MATERIAL ATTRIBUTES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: WardrobeTheme.textMuted,
                ),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: Autocomplete<String>(
                      initialValue: TextEditingValue(text: _primaryColorController.text),
                      optionsBuilder: (textVal) {
                        if (textVal.text.isEmpty) return _commonColors;
                        return _commonColors.where(
                            (c) => c.toLowerCase().contains(textVal.text.toLowerCase()));
                      },
                      onSelected: (selection) => _primaryColorController.text = selection,
                      fieldViewBuilder: (ctx, controller, focusNode, onSubmitted) {
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          style: const TextStyle(color: WardrobeTheme.textPrimary, fontSize: 14),
                          decoration: _inputDecoration('Primary Color *'),
                          onChanged: (val) => _primaryColorController.text = val,
                          validator: (val) => val == null || val.trim().isEmpty ? 'Enter color' : null,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _patternController,
                      style: const TextStyle(color: WardrobeTheme.textPrimary, fontSize: 14),
                      decoration: _inputDecoration('Pattern', hint: 'e.g. Solid, Striped'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _fabricController,
                      style: const TextStyle(color: WardrobeTheme.textPrimary, fontSize: 14),
                      decoration: _inputDecoration('Fabric', hint: 'e.g. 100% Cotton, Linen'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _secondaryColorsController,
                      style: const TextStyle(color: WardrobeTheme.textPrimary, fontSize: 14),
                      decoration: _inputDecoration('Secondary Colors', hint: 'White, Grey'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Category-sensitive fields: Sleeves and Neckline
              if (_showsSleeveAndNeckline) ...[
                Row(
                  children: [
                    Expanded(
                      child: Autocomplete<String>(
                        initialValue: TextEditingValue(text: _sleeveLengthController.text),
                        optionsBuilder: (textVal) => _commonSleeves.where(
                            (s) => s.toLowerCase().contains(textVal.text.toLowerCase())),
                        onSelected: (selection) => _sleeveLengthController.text = selection,
                        fieldViewBuilder: (ctx, controller, focusNode, onSubmitted) {
                          return TextFormField(
                            controller: controller,
                            focusNode: focusNode,
                            style: const TextStyle(color: WardrobeTheme.textPrimary, fontSize: 14),
                            decoration: _inputDecoration('Sleeve Length', hint: 'e.g. 3/4 Sleeves'),
                            onChanged: (val) => _sleeveLengthController.text = val,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _necklineController,
                        style: const TextStyle(color: WardrobeTheme.textPrimary, fontSize: 14),
                        decoration: _inputDecoration('Neckline', hint: 'e.g. Crew, Mandarin'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              Row(
                children: [
                  Expanded(
                    child: Autocomplete<String>(
                      initialValue: TextEditingValue(text: _fitController.text),
                      optionsBuilder: (textVal) => _commonFits.where(
                          (f) => f.toLowerCase().contains(textVal.text.toLowerCase())),
                      onSelected: (selection) => _fitController.text = selection,
                      fieldViewBuilder: (ctx, controller, focusNode, onSubmitted) {
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          style: const TextStyle(color: WardrobeTheme.textPrimary, fontSize: 14),
                          decoration: _inputDecoration('Fit', hint: 'e.g. Slim Fit'),
                          onChanged: (val) => _fitController.text = val,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _sizeController,
                      style: const TextStyle(color: WardrobeTheme.textPrimary, fontSize: 14),
                      decoration: _inputDecoration('Size', hint: 'e.g. M, 32, 40'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 3. Brand & Economics
              const Text(
                'BRAND & PURCHASE DETAILS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: WardrobeTheme.textMuted,
                ),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _brandController,
                      style: const TextStyle(color: WardrobeTheme.textPrimary, fontSize: 14),
                      decoration: _inputDecoration('Brand / Retailer', hint: 'e.g. Uniqlo, Zara'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: WardrobeTheme.textPrimary, fontSize: 14),
                      decoration: _inputDecoration('Price', hint: 'e.g. 49.99'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 4. Initial Laundry Status
              const Text(
                'LAUNDRY STATUS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: WardrobeTheme.textMuted,
                ),
              ),
              const SizedBox(height: 10),

              DropdownButtonFormField<LaundryStatus?>(
                value: _selectedLaundryStatus,
                dropdownColor: WardrobeTheme.elevatedSurface,
                style: const TextStyle(color: WardrobeTheme.textPrimary, fontSize: 14),
                decoration: _inputDecoration('Current Laundry Status'),
                items: [
                  const DropdownMenuItem<LaundryStatus?>(
                    value: null,
                    child: Text('Unassigned (Initial/Unknown)'),
                  ),
                  ...LaundryStatus.values.map((s) {
                    return DropdownMenuItem<LaundryStatus?>(
                      value: s,
                      child: Text(s.label),
                    );
                  }),
                ],
                onChanged: (val) {
                  setState(() => _selectedLaundryStatus = val);
                },
              ),
              const SizedBox(height: 20),

              // 5. Notes
              const Text(
                'NOTES & STYLING TIPS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: WardrobeTheme.textMuted,
                ),
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _notesController,
                maxLines: 3,
                style: const TextStyle(color: WardrobeTheme.textPrimary, fontSize: 14),
                decoration: _inputDecoration('Garment Notes', hint: 'Special care instructions, styling notes...'),
              ),
              const SizedBox(height: 32),

              // Submit Button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: WardrobeTheme.electricViolet,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: WardrobeTheme.electricViolet.withValues(alpha: 0.4),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        _isEditing ? 'Save Changes' : 'Add to Wardrobe',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

