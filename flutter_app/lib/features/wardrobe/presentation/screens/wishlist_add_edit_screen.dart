import 'package:flutter/material.dart';
import '../../domain/entities/wishlist_item.dart';
import '../controllers/wishlist_controller.dart';
import '../theme/wardrobe_theme.dart';

class WishlistAddEditScreen extends StatefulWidget {
  final WishlistController controller;
  final WishlistItem? item;

  const WishlistAddEditScreen({
    super.key,
    required this.controller,
    this.item,
  });

  @override
  State<WishlistAddEditScreen> createState() => _WishlistAddEditScreenState();
}

class _WishlistAddEditScreenState extends State<WishlistAddEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _subcategoryController;
  late TextEditingController _expectedPriceController;
  late TextEditingController _desiredColorController;
  late TextEditingController _desiredPatternController;
  late TextEditingController _occasionController;
  late TextEditingController _notesController;

  late String _selectedCategory;
  late String _selectedCurrency;
  late PurchasePriority _selectedPriority;
  String? _referenceImagePath;

  final List<String> _categories = [
    'Tops',
    'Bottoms',
    'Ethnic wear',
    'Dresses',
    'Outerwear',
    'Activewear',
    'Footwear',
    'Accessories',
    'Innerwear',
    'Sleepwear',
  ];

  final List<String> _currencies = ['INR', 'USD', 'EUR', 'GBP'];

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameController = TextEditingController(text: item?.name ?? '');
    _subcategoryController = TextEditingController(text: item?.subcategory ?? '');
    _expectedPriceController = TextEditingController(
      text: item?.expectedPrice != null ? item!.expectedPrice!.toStringAsFixed(0) : '',
    );
    _desiredColorController = TextEditingController(text: item?.desiredColour ?? '');
    _desiredPatternController = TextEditingController(text: item?.desiredPattern ?? '');
    _occasionController = TextEditingController(text: item?.occasion ?? '');
    _notesController = TextEditingController(text: item?.notes ?? '');

    _selectedCategory = item?.category ?? 'Bottoms';
    _selectedCurrency = item?.expectedCurrency ?? 'INR';
    _selectedPriority = item?.purchasePriority ?? PurchasePriority.medium;
    _referenceImagePath = item?.referenceImagePath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subcategoryController.dispose();
    _expectedPriceController.dispose();
    _desiredColorController.dispose();
    _desiredPatternController.dispose();
    _occasionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    final price = double.tryParse(_expectedPriceController.text.trim());

    if (widget.item == null) {
      final created = await widget.controller.createItem(
        name: _nameController.text.trim(),
        category: _selectedCategory,
        subcategory: _subcategoryController.text.trim().isEmpty ? null : _subcategoryController.text.trim(),
        referenceImagePath: _referenceImagePath,
        expectedPrice: price,
        expectedCurrency: _selectedCurrency,
        purchasePriority: _selectedPriority,
        occasion: _occasionController.text.trim().isEmpty ? null : _occasionController.text.trim(),
        desiredColour: _desiredColorController.text.trim().isEmpty ? null : _desiredColorController.text.trim(),
        desiredPattern: _desiredPatternController.text.trim().isEmpty ? null : _desiredPatternController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
      if (mounted && created != null) {
        Navigator.pop(context, true);
      }
    } else {
      final updated = widget.item!.copyWith(
        name: _nameController.text.trim(),
        category: _selectedCategory,
        subcategory: _subcategoryController.text.trim().isEmpty ? null : _subcategoryController.text.trim(),
        referenceImagePath: _referenceImagePath,
        expectedPrice: price,
        expectedCurrency: _selectedCurrency,
        purchasePriority: _selectedPriority,
        occasion: _occasionController.text.trim().isEmpty ? null : _occasionController.text.trim(),
        desiredColour: _desiredColorController.text.trim().isEmpty ? null : _desiredColorController.text.trim(),
        desiredPattern: _desiredPatternController.text.trim().isEmpty ? null : _desiredPatternController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
      final success = await widget.controller.updateItem(updated);
      if (mounted && success) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.item != null;

    return Scaffold(
      backgroundColor: WardrobeTheme.voidBlack,
      appBar: AppBar(
        backgroundColor: WardrobeTheme.voidBlack,
        title: Text(
          isEditing ? 'Edit Wishlist Item' : 'Add to Wishlist',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: WardrobeTheme.textPrimary,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Reference image placeholder or upload button
            Center(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _referenceImagePath = 'assets/images/wishlist_placeholder.jpg';
                  });
                },
                child: Container(
                  width: 120,
                  height: 140,
                  decoration: BoxDecoration(
                    color: WardrobeTheme.spatialSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: WardrobeTheme.subtleBorder),
                  ),
                  child: _referenceImagePath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            _referenceImagePath!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildAddPhotoPlaceholder(),
                          ),
                        )
                      : _buildAddPhotoPlaceholder(),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Item Name
            TextFormField(
              controller: _nameController,
              style: TextStyle(color: WardrobeTheme.textPrimary),
              decoration: _buildInputDecoration('Item Name *', 'e.g. Black Formal Trousers'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter an item name' : null,
            ),
            const SizedBox(height: 14),

            // Category & Subcategory Row
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    dropdownColor: WardrobeTheme.spatialSurface,
                    style: TextStyle(color: WardrobeTheme.textPrimary),
                    decoration: _buildInputDecoration('Category *', ''),
                    items: _categories.map((cat) {
                      return DropdownMenuItem(value: cat, child: Text(cat));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _subcategoryController,
                    style: TextStyle(color: WardrobeTheme.textPrimary),
                    decoration: _buildInputDecoration('Subcategory', 'e.g. Pants'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Price & Currency Row
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _expectedPriceController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: WardrobeTheme.textPrimary),
                    decoration: _buildInputDecoration('Expected Price', 'e.g. 3500'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    value: _selectedCurrency,
                    dropdownColor: WardrobeTheme.spatialSurface,
                    style: TextStyle(color: WardrobeTheme.textPrimary),
                    decoration: _buildInputDecoration('Currency', ''),
                    items: _currencies.map((c) {
                      return DropdownMenuItem(value: c, child: Text(c));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCurrency = val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Purchase Priority Selector
            Text(
              'PURCHASE PRIORITY',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: WardrobeTheme.softViolet,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildPriorityOption(PurchasePriority.high, 'High', WardrobeTheme.warningRose),
                const SizedBox(width: 8),
                _buildPriorityOption(PurchasePriority.medium, 'Medium', WardrobeTheme.electricCyan),
                const SizedBox(width: 8),
                _buildPriorityOption(PurchasePriority.low, 'Low', WardrobeTheme.textMuted),
              ],
            ),
            const SizedBox(height: 16),

            // Desired Color & Pattern Row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _desiredColorController,
                    style: TextStyle(color: WardrobeTheme.textPrimary),
                    decoration: _buildInputDecoration('Target Color', 'e.g. Black / Navy'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _desiredPatternController,
                    style: TextStyle(color: WardrobeTheme.textPrimary),
                    decoration: _buildInputDecoration('Pattern', 'e.g. Solid / Plaid'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Occasion
            TextFormField(
              controller: _occasionController,
              style: TextStyle(color: WardrobeTheme.textPrimary),
              decoration: _buildInputDecoration('Occasion', 'e.g. Work, Casual, Festive'),
            ),
            const SizedBox(height: 14),

            // Notes
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              style: TextStyle(color: WardrobeTheme.textPrimary),
              decoration: _buildInputDecoration('Notes / Why do you want this?', 'Enter notes...'),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: WardrobeTheme.electricViolet,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  isEditing ? 'Update Wishlist Item' : 'Save to Wishlist',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildAddPhotoPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_a_photo_outlined, size: 28, color: WardrobeTheme.softViolet),
        const SizedBox(height: 6),
        Text(
          'Inspiration Photo',
          style: TextStyle(fontSize: 10, color: WardrobeTheme.textMuted),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPriorityOption(PurchasePriority p, String label, Color color) {
    final isSelected = _selectedPriority == p;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedPriority = p),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.15) : WardrobeTheme.spatialSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : WardrobeTheme.subtleBorder,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? color : WardrobeTheme.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(color: WardrobeTheme.textMuted, fontSize: 13),
      hintStyle: TextStyle(color: WardrobeTheme.textMuted, fontSize: 12),
      filled: true,
      fillColor: WardrobeTheme.spatialSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: WardrobeTheme.subtleBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: WardrobeTheme.subtleBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: WardrobeTheme.electricViolet),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}
