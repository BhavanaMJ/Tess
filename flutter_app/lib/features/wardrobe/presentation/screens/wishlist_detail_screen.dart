import 'package:flutter/material.dart';
import '../../domain/entities/wishlist_item.dart';
import '../controllers/wishlist_controller.dart';
import '../theme/wardrobe_theme.dart';
import '../widgets/wishlist_priority_badge.dart';
import 'wishlist_add_edit_screen.dart';
import 'purchase_assessment_screen.dart';
import 'wishlist_conversion_screen.dart';

class WishlistDetailScreen extends StatefulWidget {
  final WishlistItem item;
  final WishlistController controller;

  const WishlistDetailScreen({
    super.key,
    required this.item,
    required this.controller,
  });

  @override
  State<WishlistDetailScreen> createState() => _WishlistDetailScreenState();
}

class _WishlistDetailScreenState extends State<WishlistDetailScreen> {
  late WishlistItem _item;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    widget.controller.assessItem(_item.id);
  }

  void _navigateToEdit() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => WishlistAddEditScreen(
          controller: widget.controller,
          item: _item,
        ),
      ),
    );
    if (result == true) {
      final updated = widget.controller.items.firstWhere((i) => i.id == _item.id);
      setState(() => _item = updated);
    }
  }

  void _navigateToAssessment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PurchaseAssessmentScreen(
          item: _item,
          controller: widget.controller,
        ),
      ),
    );
  }

  void _navigateToConversion() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => WishlistConversionScreen(
          item: _item,
          controller: widget.controller,
        ),
      ),
    );
    if (result == true) {
      final updated = widget.controller.items.firstWhere((i) => i.id == _item.id);
      setState(() => _item = updated);
    }
  }

  void _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: WardrobeTheme.elevatedSurface,
        title: Text('Delete Wishlist Item?', style: TextStyle(color: WardrobeTheme.textPrimary)),
        content: Text(
          'Are you sure you want to remove this item from your wishlist?',
          style: TextStyle(color: WardrobeTheme.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: WardrobeTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: WardrobeTheme.warningRose),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.controller.deleteItem(_item.id);
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol = _item.expectedCurrency == 'INR' ? '₹' : _item.expectedCurrency;

    return Scaffold(
      backgroundColor: WardrobeTheme.voidBlack,
      appBar: AppBar(
        backgroundColor: WardrobeTheme.voidBlack,
        title: Text(
          'Wishlist Item Detail',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: WardrobeTheme.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit_outlined, color: WardrobeTheme.electricViolet),
            onPressed: _navigateToEdit,
          ),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: WardrobeTheme.warningRose),
            onPressed: _delete,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Reference photo or placeholder card
          Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              color: WardrobeTheme.spatialSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: WardrobeTheme.subtleBorder),
            ),
            child: _item.referenceImagePath != null && _item.referenceImagePath!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _item.referenceImagePath!.startsWith('http')
                        ? Image.network(
                            _item.referenceImagePath!,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => _buildFallbackHero(),
                          )
                        : Image.asset(
                            _item.referenceImagePath!,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => _buildFallbackHero(),
                          ),
                  )
                : _buildFallbackHero(),
          ),
          const SizedBox(height: 16),

          // Header: Name, priority, status
          Row(
            children: [
              WishlistPriorityBadge(priority: _item.purchasePriority),
              const SizedBox(width: 8),
              _buildStatusPill(_item.status),
              const Spacer(),
              if (_item.isConverted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: WardrobeTheme.electricViolet.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'CONVERTED TO WARDROBE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: WardrobeTheme.softViolet,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _item.name,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: WardrobeTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_item.category}${_item.subcategory != null ? ' • ${_item.subcategory}' : ''}',
            style: TextStyle(
              fontSize: 14,
              color: WardrobeTheme.textMuted,
            ),
          ),
          const SizedBox(height: 16),

          // Financial & Spec Container
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: WardrobeTheme.spatialSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: WardrobeTheme.subtleBorder),
            ),
            child: Column(
              children: [
                _buildSpecRow(
                  'Expected Price',
                  _item.expectedPrice != null
                      ? '$currencySymbol${_item.expectedPrice!.toStringAsFixed(0)}'
                      : 'Unrecorded',
                ),
                if (_item.actualPurchasePrice != null) ...[
                  Divider(color: WardrobeTheme.subtleBorder, height: 16),
                  _buildSpecRow(
                    'Actual Purchase Price',
                    '${_item.actualPurchaseCurrency ?? currencySymbol}${_item.actualPurchasePrice!.toStringAsFixed(0)}',
                  ),
                ],
                Divider(color: WardrobeTheme.subtleBorder, height: 16),
                _buildSpecRow('Target Color', _item.desiredColour ?? 'Any'),
                if (_item.desiredPattern != null) ...[
                  Divider(color: WardrobeTheme.subtleBorder, height: 16),
                  _buildSpecRow('Pattern', _item.desiredPattern!),
                ],
                if (_item.occasion != null) ...[
                  Divider(color: WardrobeTheme.subtleBorder, height: 16),
                  _buildSpecRow('Occasion', _item.occasion!),
                ],
              ],
            ),
          ),

          if (_item.notes != null && _item.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: WardrobeTheme.spatialSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: WardrobeTheme.subtleBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NOTES & REASONING',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: WardrobeTheme.softViolet,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _item.notes!,
                    style: TextStyle(
                      fontSize: 13,
                      color: WardrobeTheme.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Shopping Intelligence Preview Card
          InkWell(
            onTap: _navigateToAssessment,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    WardrobeTheme.spatialSurface,
                    WardrobeTheme.electricCyan.withValues(alpha: 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: WardrobeTheme.electricCyan.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: WardrobeTheme.electricCyan.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: WardrobeTheme.electricCyan,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Shopping Intelligence Assessment',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: WardrobeTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Evaluate similar items owned, category gaps & versatile combinations.',
                          style: TextStyle(
                            fontSize: 11,
                            color: WardrobeTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: WardrobeTheme.electricCyan),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Primary Action: Mark as Purchased / Add to Wardrobe
          if (!_item.isPurchased) ...[
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _navigateToConversion,
                icon: const Icon(Icons.checkroom_rounded, size: 18),
                label: const Text('Mark Purchased & Add to Wardrobe'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: WardrobeTheme.electricViolet,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ] else if (!_item.isConverted) ...[
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _navigateToConversion,
                icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                label: const Text('Add Converted Item to My Wardrobe'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: WardrobeTheme.successEmerald,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildFallbackHero() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.checkroom_outlined, size: 48, color: WardrobeTheme.softViolet),
          const SizedBox(height: 8),
          Text(
            'Wishlist Reference Image',
            style: TextStyle(fontSize: 12, color: WardrobeTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: WardrobeTheme.textMuted),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: WardrobeTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusPill(WishlistStatus status) {
    Color color;
    switch (status) {
      case WishlistStatus.shortlisted:
        color = WardrobeTheme.electricCyan;
        break;
      case WishlistStatus.purchased:
        color = WardrobeTheme.successEmerald;
        break;
      case WishlistStatus.notInterested:
        color = WardrobeTheme.textMuted;
        break;
      case WishlistStatus.considering:
        color = WardrobeTheme.softViolet;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.displayName.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
