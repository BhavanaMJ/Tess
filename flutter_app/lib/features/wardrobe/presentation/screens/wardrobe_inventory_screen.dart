import 'package:flutter/material.dart';
import '../../../../core/auth/auth_service.dart';
import '../../../../shared/widgets/tess_card.dart';
import '../../domain/entities/garment.dart';
import '../../domain/entities/laundry_status.dart';
import '../controllers/wardrobe_controller.dart';
import '../theme/wardrobe_theme.dart';
import '../widgets/category_chip.dart';
import '../widgets/garment_image_placeholder.dart';
import '../widgets/garment_status_indicator.dart';

/// WardrobeInventoryScreen: Digital Wardrobe Inventory Foundation.
/// Displays categorized garments with studio photography cards, status badges, and filtering.
class WardrobeInventoryScreen extends StatefulWidget {
  final WardrobeController controller;
  final AuthService? authService;

  const WardrobeInventoryScreen({
    super.key,
    required this.controller,
    this.authService,
  });

  @override
  State<WardrobeInventoryScreen> createState() => _WardrobeInventoryScreenState();
}

class _WardrobeInventoryScreenState extends State<WardrobeInventoryScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Garment> _applySearch(List<Garment> list) {
    if (_searchQuery.trim().isEmpty) return list;
    final q = _searchQuery.trim().toLowerCase();
    return list.where((g) {
      return g.name.toLowerCase().contains(q) ||
          g.id.toLowerCase().contains(q) ||
          g.mainCategory.toLowerCase().contains(q) ||
          (g.subcategory != null && g.subcategory!.toLowerCase().contains(q)) ||
          g.primaryColor.toLowerCase().contains(q) ||
          (g.brand != null && g.brand!.toLowerCase().contains(q));
    }).toList();
  }

  void _showLaundryStatusSheet(Garment garment) {
    showModalBottomSheet(
      context: context,
      backgroundColor: WardrobeTheme.elevatedSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Update Status: ${garment.name}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: WardrobeTheme.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: WardrobeTheme.textMuted, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...LaundryStatus.values.map((status) {
                  final isSelected = garment.laundryStatus == status;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: GarmentStatusIndicator(status: status, compact: true),
                    title: Text(
                      status.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? WardrobeTheme.textPrimary : WardrobeTheme.textSecondary,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: WardrobeTheme.electricViolet, size: 20)
                        : null,
                    onTap: () {
                      widget.controller.updateLaundryStatus(garment.id, status);
                      Navigator.pop(ctx);
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
        title: const Text(
          'My Wardrobe',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: WardrobeTheme.textPrimary,
            letterSpacing: -0.4,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: WardrobeTheme.textSecondary, size: 20),
            tooltip: 'Filter Options',
            onPressed: () {},
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final allGarments = widget.controller.filteredGarments;
          final displayedGarments = _applySearch(allGarments);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: WardrobeTheme.spatialSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: WardrobeTheme.border, width: 1.0),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: const TextStyle(fontSize: 13, color: WardrobeTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search garments by name, color, category...',
                      hintStyle: const TextStyle(fontSize: 12, color: WardrobeTheme.textMuted),
                      prefixIcon: const Icon(Icons.search, size: 18, color: WardrobeTheme.textMuted),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16, color: WardrobeTheme.textMuted),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),

              // Category Filter Bar
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  children: [
                    CategoryChip(
                      label: 'All (${widget.controller.totalGarmentsCount})',
                      isSelected: widget.controller.selectedCategory == null,
                      onTap: () => widget.controller.setCategoryFilter(null),
                    ),
                    const SizedBox(width: 8),
                    ...widget.controller.categories.map((cat) {
                      final isSelected = widget.controller.selectedCategory == cat.name;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: CategoryChip(
                          label: cat.name,
                          isSelected: isSelected,
                          onTap: () => widget.controller.setCategoryFilter(cat.name),
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Garments List / Empty State
              Expanded(
                child: displayedGarments.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.filter_alt_off_outlined,
                                color: WardrobeTheme.textMuted,
                                size: 40,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'No garments match your filters',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: WardrobeTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Try clearing search terms or selecting another category.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: WardrobeTheme.textMuted,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                  widget.controller.setCategoryFilter(null);
                                  widget.controller.setLaundryFilter(null);
                                },
                                child: const Text(
                                  'Clear All Filters',
                                  style: TextStyle(color: WardrobeTheme.electricCyan),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        itemCount: displayedGarments.length,
                        itemBuilder: (ctx, i) {
                          final garment = displayedGarments[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: TessCard(
                              backgroundColor: WardrobeTheme.spatialSurface,
                              borderColor: WardrobeTheme.border,
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  // Clean Studio Photography Placeholder Card
                                  GarmentImagePlaceholder(
                                    imageUrl: garment.displayImageRef,
                                    category: garment.mainCategory,
                                    width: 64,
                                    height: 64,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                garment.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: WardrobeTheme.textPrimary,
                                                ),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () => widget.controller.toggleFavorite(garment.id),
                                              child: Icon(
                                                garment.isFavorite
                                                    ? Icons.favorite_rounded
                                                    : Icons.favorite_border_rounded,
                                                color: garment.isFavorite
                                                    ? WardrobeTheme.statusCritical
                                                    : WardrobeTheme.textMuted,
                                                size: 18,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(
                                              garment.id,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                fontFamily: 'monospace',
                                                color: WardrobeTheme.softViolet,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '•  ${garment.mainCategory}${garment.sleeveLength != null ? " • ${garment.sleeveLength}" : ""}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: WardrobeTheme.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        GestureDetector(
                                          onTap: () => _showLaundryStatusSheet(garment),
                                          child: GarmentStatusIndicator(
                                            status: garment.laundryStatus,
                                            compact: true,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
