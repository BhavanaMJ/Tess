import 'package:flutter/material.dart';
import '../../domain/entities/wishlist_item.dart';
import '../controllers/wishlist_controller.dart';
import '../theme/wardrobe_theme.dart';

class WishlistConversionScreen extends StatefulWidget {
  final WishlistItem item;
  final WishlistController controller;

  const WishlistConversionScreen({
    super.key,
    required this.item,
    required this.controller,
  });

  @override
  State<WishlistConversionScreen> createState() => _WishlistConversionScreenState();
}

class _WishlistConversionScreenState extends State<WishlistConversionScreen> {
  late TextEditingController _priceController;
  late TextEditingController _nameController;
  late TextEditingController _colorController;
  final DateTime _purchaseDate = DateTime.now();
  String _currency = 'INR';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(
      text: widget.item.expectedPrice != null
          ? widget.item.expectedPrice!.toStringAsFixed(0)
          : '',
    );
    _nameController = TextEditingController(text: widget.item.name);
    _colorController = TextEditingController(text: widget.item.desiredColour ?? 'Multi');
    _currency = widget.item.expectedCurrency;
  }

  @override
  void dispose() {
    _priceController.dispose();
    _nameController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  void _confirmConversion() async {
    setState(() => _isSubmitting = true);
    final price = double.tryParse(_priceController.text.trim());

    final res = await widget.controller.convertToWardrobe(
      widget.item.id,
      actualPrice: price,
      actualCurrency: _currency,
      purchaseDate: _purchaseDate,
      garmentNameOverride: _nameController.text.trim().isNotEmpty
          ? _nameController.text.trim()
          : null,
      primaryColor: _colorController.text.trim().isNotEmpty
          ? _colorController.text.trim()
          : null,
      // Note: laundryStatus is omitted to keep it unassigned!
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (res != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: WardrobeTheme.successEmerald,
            content: const Text('Item successfully registered in My Wardrobe!'),
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: WardrobeTheme.warningRose,
            content: Text(widget.controller.errorMessage ?? 'Conversion failed'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WardrobeTheme.voidBlack,
      appBar: AppBar(
        backgroundColor: WardrobeTheme.voidBlack,
        title: Text(
          'Confirm Purchase & Register',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: WardrobeTheme.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Item preview
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: WardrobeTheme.spatialSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: WardrobeTheme.subtleBorder),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 50,
                    height: 60,
                    color: WardrobeTheme.elevatedSurface,
                    child: widget.item.referenceImagePath != null &&
                            widget.item.referenceImagePath!.isNotEmpty
                        ? Image.asset(
                            widget.item.referenceImagePath!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.checkroom,
                              color: WardrobeTheme.softViolet,
                            ),
                          )
                        : Icon(
                            Icons.checkroom,
                            color: WardrobeTheme.softViolet,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CONVERTING FROM WISHLIST',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: WardrobeTheme.softViolet,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.item.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: WardrobeTheme.textPrimary,
                        ),
                      ),
                      Text(
                        widget.item.category,
                        style: TextStyle(
                          fontSize: 12,
                          color: WardrobeTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Laundry Status Safety Warning Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: WardrobeTheme.electricViolet.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: WardrobeTheme.electricViolet.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined,
                    size: 18, color: WardrobeTheme.softViolet),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Unassigned Laundry Status Protection',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: WardrobeTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'The garment laundry status remains unassigned until you physically wash or verify it. We never assume a newly acquired piece is clean.',
                        style: TextStyle(
                          fontSize: 11,
                          color: WardrobeTheme.textMuted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Financial details
          Text(
            'ACTUAL PURCHASE DETAILS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: WardrobeTheme.softViolet,
            ),
          ),
          const SizedBox(height: 8),

          TextFormField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            style: TextStyle(color: WardrobeTheme.textPrimary),
            decoration: InputDecoration(
              labelText: 'Actual Purchase Price',
              prefixText: '$_currency ',
              prefixStyle: TextStyle(color: WardrobeTheme.electricCyan),
              labelStyle: TextStyle(color: WardrobeTheme.textMuted, fontSize: 13),
              filled: true,
              fillColor: WardrobeTheme.spatialSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: WardrobeTheme.subtleBorder),
              ),
            ),
          ),
          const SizedBox(height: 14),

          TextFormField(
            controller: _nameController,
            style: TextStyle(color: WardrobeTheme.textPrimary),
            decoration: InputDecoration(
              labelText: 'Garment Name',
              labelStyle: TextStyle(color: WardrobeTheme.textMuted, fontSize: 13),
              filled: true,
              fillColor: WardrobeTheme.spatialSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: WardrobeTheme.subtleBorder),
              ),
            ),
          ),
          const SizedBox(height: 14),

          TextFormField(
            controller: _colorController,
            style: TextStyle(color: WardrobeTheme.textPrimary),
            decoration: InputDecoration(
              labelText: 'Primary Color',
              labelStyle: TextStyle(color: WardrobeTheme.textMuted, fontSize: 13),
              filled: true,
              fillColor: WardrobeTheme.spatialSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: WardrobeTheme.subtleBorder),
              ),
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _confirmConversion,
              style: ElevatedButton.styleFrom(
                backgroundColor: WardrobeTheme.electricViolet,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Confirm & Register in My Wardrobe',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
