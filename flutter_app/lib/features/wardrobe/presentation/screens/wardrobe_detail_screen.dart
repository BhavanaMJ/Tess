import 'package:flutter/material.dart';
import '../../domain/entities/garment.dart';
import '../../domain/entities/laundry_status.dart';
import '../controllers/wardrobe_controller.dart';
import '../theme/wardrobe_theme.dart';
import '../widgets/garment_image_placeholder.dart';
import '../widgets/garment_status_indicator.dart';
import 'garment_form_screen.dart';
import '../../data/repositories/laundry_repository_impl.dart';
import '../controllers/laundry_controller.dart';
import 'garment_laundry_history_screen.dart';

/// Screen for displaying complete details of a single garment in the digital wardrobe.
/// Features studio photography presentation, attribute grid, laundry controls, and edit/delete actions.
class WardrobeDetailScreen extends StatefulWidget {
  final Garment initialGarment;
  final WardrobeController controller;
  final String userId;

  const WardrobeDetailScreen({
    super.key,
    required this.initialGarment,
    required this.controller,
    this.userId = 'tess_user',
  });

  @override
  State<WardrobeDetailScreen> createState() => _WardrobeDetailScreenState();
}

class _WardrobeDetailScreenState extends State<WardrobeDetailScreen> {
  late Garment _garment;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _garment = widget.initialGarment;
  }

  void _showLaundryStatusSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: WardrobeTheme.elevatedSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Update Status: ${_garment.name}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: WardrobeTheme.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close,
                          color: WardrobeTheme.textMuted, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...LaundryStatus.values.map((status) {
                  final isSelected = _garment.laundryStatus == status;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading:
                        GarmentStatusIndicator(status: status, compact: true),
                    title: Text(
                      status.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? WardrobeTheme.textPrimary
                            : WardrobeTheme.textSecondary,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_circle,
                            color: WardrobeTheme.electricViolet, size: 20)
                        : null,
                    onTap: () async {
                      Navigator.pop(ctx);
                      await widget.controller
                          .updateLaundryStatus(_garment.id, status);
                      setState(() {
                        _garment = _garment.copyWith(laundryStatus: status);
                      });
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: WardrobeTheme.elevatedSurface,
        title: Text(
          'Delete Garment?',
          style: TextStyle(
              color: WardrobeTheme.textPrimary, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to remove "${_garment.name}" from your wardrobe? It will be archived safely.',
          style:
              TextStyle(color: WardrobeTheme.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: TextStyle(color: WardrobeTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: WardrobeTheme.statusCritical,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isDeleting = true);
      final success = await widget.controller.deleteGarment(_garment.id);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: WardrobeTheme.elevatedSurface,
              content: Text('Garment archived successfully',
                  style: TextStyle(color: WardrobeTheme.textPrimary)),
            ),
          );
          Navigator.of(context).pop();
        } else {
          setState(() => _isDeleting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: WardrobeTheme.elevatedSurface,
              content: Text('Failed to delete garment',
                  style: TextStyle(color: WardrobeTheme.statusCritical)),
            ),
          );
        }
      }
    }
  }

  Future<void> _navigateToEdit() async {
    final updated = await Navigator.of(context).push<Garment>(
      MaterialPageRoute(
        builder: (_) => GarmentFormScreen(
          controller: widget.controller,
          garment: _garment,
          userId: widget.userId,
        ),
      ),
    );

    if (updated != null && mounted) {
      setState(() {
        _garment = updated;
      });
    }
  }

  Widget _buildSpecItem(String label, String? value, {IconData? icon}) {
    if (value == null || value.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: WardrobeTheme.textMuted),
            const SizedBox(width: 8),
          ],
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: WardrobeTheme.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: WardrobeTheme.textPrimary,
              ),
            ),
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
          _garment.id,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            fontFamily: 'monospace',
            color: WardrobeTheme.softViolet,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _garment.isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: _garment.isFavorite
                  ? WardrobeTheme.statusCritical
                  : WardrobeTheme.textMuted,
            ),
            tooltip: 'Favorite',
            onPressed: () async {
              await widget.controller.toggleFavorite(_garment.id);
              setState(() {
                _garment = _garment.copyWith(isFavorite: !_garment.isFavorite);
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.edit_outlined,
                color: WardrobeTheme.textSecondary),
            tooltip: 'Edit Garment',
            onPressed: _navigateToEdit,
          ),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded,
                color: WardrobeTheme.statusCritical),
            tooltip: 'Delete Garment',
            onPressed: _isDeleting ? null : _handleDelete,
          ),
        ],
      ),
      body: _isDeleting
          ? Center(
              child: CircularProgressIndicator(
                  color: WardrobeTheme.electricViolet),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Studio-White Garment Photography Presentation
                  Container(
                    height: 260,
                    decoration: BoxDecoration(
                      color: WardrobeTheme.studioBackground,
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: WardrobeTheme.border, width: 1.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        GarmentImagePlaceholder(
                          imageUrl: _garment.displayImageRef,
                          category: _garment.mainCategory,
                          width: double.infinity,
                          height: 260,
                        ),
                        // Top Right Category pill
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: WardrobeTheme.spatialSurface
                                  .withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: WardrobeTheme.border),
                            ),
                            child: Text(
                              _garment.mainCategory,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: WardrobeTheme.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 2. Garment Title & Status
                  Text(
                    _garment.name,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: WardrobeTheme.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      if (_garment.brand != null &&
                          _garment.brand!.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: WardrobeTheme.spatialSurface,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: WardrobeTheme.border),
                          ),
                          child: Text(
                            _garment.brand!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: WardrobeTheme.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (_garment.subcategory != null) ...[
                        Text(
                          _garment.subcategory!,
                          style: TextStyle(
                            fontSize: 13,
                            color: WardrobeTheme.textMuted,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      const Spacer(),
                      GestureDetector(
                        onTap: _showLaundryStatusSheet,
                        child: GarmentStatusIndicator(
                          status: _garment.laundryStatus,
                          compact: false,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 3. Quick Actions Row
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showLaundryStatusSheet,
                          icon: const Icon(Icons.local_laundry_service_outlined,
                              size: 16),
                          label: const Text('Update Status'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: WardrobeTheme.electricCyan,
                            side: BorderSide(
                                color: WardrobeTheme.borderCyan),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _navigateToEdit,
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text('Edit Details'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: WardrobeTheme.electricViolet,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 4. Specifications & Attributes
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: WardrobeTheme.spatialSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: WardrobeTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SPECIFICATIONS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: WardrobeTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Divider(
                            color: WardrobeTheme.borderSubtle, height: 1),
                        const SizedBox(height: 8),
                        _buildSpecItem('Category', _garment.mainCategory),
                        _buildSpecItem('Subcategory', _garment.subcategory),
                        _buildSpecItem('Primary Color', _garment.primaryColor),
                        if (_garment.secondaryColors.isNotEmpty)
                          _buildSpecItem(
                              'Secondary', _garment.secondaryColors.join(', ')),
                        _buildSpecItem('Pattern', _garment.pattern),
                        _buildSpecItem('Fabric', _garment.fabricMaterial),
                        _buildSpecItem('Sleeve Length', _garment.sleeveLength),
                        _buildSpecItem('Neckline', _garment.neckline),
                        _buildSpecItem('Fit', _garment.fit),
                        _buildSpecItem('Silhouette', _garment.silhouette),
                        _buildSpecItem('Size', _garment.size),
                        _buildSpecItem('Brand', _garment.brand),
                        if (_garment.purchasePrice != null)
                          _buildSpecItem('Price',
                              '\$${_garment.purchasePrice!.toStringAsFixed(2)}'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 4. Laundry Lifecycle & History Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: WardrobeTheme.spatialSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: WardrobeTheme.borderViolet),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'LAUNDRY LIFECYCLE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: WardrobeTheme.textMuted,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => GarmentLaundryHistoryScreen(
                                      garment: _garment,
                                      controller: LaundryController(
                                        repository: LaundryRepositoryImpl(),
                                      ),
                                    ),
                                  ),
                                );
                              },
                              icon: Icon(Icons.history_rounded,
                                  size: 16,
                                  color: WardrobeTheme.electricViolet),
                              label: Text(
                                'View History',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: WardrobeTheme.electricViolet,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: WardrobeTheme.elevatedSurface,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('WEARS',
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: WardrobeTheme.textMuted,
                                            fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 2),
                                    Text('${_garment.wearCount}x',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color:
                                                WardrobeTheme.statusWarning)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: WardrobeTheme.elevatedSurface,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('WASHES',
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: WardrobeTheme.textMuted,
                                            fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 2),
                                    Text('${_garment.washCount}x',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: WardrobeTheme.electricCyan)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  if (_garment.notes != null && _garment.notes!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: WardrobeTheme.spatialSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: WardrobeTheme.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NOTES',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: WardrobeTheme.textMuted,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _garment.notes!,
                            style: TextStyle(
                              fontSize: 13,
                              color: WardrobeTheme.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}
