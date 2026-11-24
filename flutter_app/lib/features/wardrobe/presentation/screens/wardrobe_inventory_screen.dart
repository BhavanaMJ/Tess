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
import 'garment_form_screen.dart';
import 'wardrobe_detail_screen.dart';

/// WardrobeInventoryScreen: Digital Wardrobe Inventory.
/// Displays categorized garments with studio photography cards, status badges, multi-factor filtering, and sorting.
class WardrobeInventoryScreen extends StatefulWidget {
  final WardrobeController controller;
  final AuthService? authService;

  const WardrobeInventoryScreen({
    super.key,
    required this.controller,
    this.authService,
  });

  @override
  State<WardrobeInventoryScreen> createState() =>
      _WardrobeInventoryScreenState();
}

class _WardrobeInventoryScreenState extends State<WardrobeInventoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.controller.searchQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showLaundryStatusSheet(Garment garment) {
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
                        'Update Status: ${garment.name}',
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
                  final isSelected = garment.laundryStatus == status;
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

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: WardrobeTheme.elevatedSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final activeCount = widget.controller.activeFilterCount;

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filter Wardrobe',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: WardrobeTheme.textPrimary,
                          ),
                        ),
                        if (activeCount > 0)
                          TextButton(
                            onPressed: () {
                              widget.controller.clearAllFilters();
                              setModalState(() {});
                            },
                            child: Text(
                              'Reset All',
                              style: TextStyle(
                                  color: WardrobeTheme.electricCyan,
                                  fontSize: 13),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Favorites Only Switch
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Favorites Only',
                        style: TextStyle(
                            color: WardrobeTheme.textPrimary, fontSize: 14),
                      ),
                      value: widget.controller.favoritesOnly,
                      activeColor: WardrobeTheme.electricViolet,
                      onChanged: (val) {
                        widget.controller.toggleFavoritesOnly();
                        setModalState(() {});
                      },
                    ),
                    const SizedBox(height: 12),

                    // Laundry Status Filter
                    Text(
                      'LAUNDRY STATUS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: WardrobeTheme.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('All'),
                          selected:
                              widget.controller.selectedLaundryStatus == null,
                          onSelected: (_) {
                            widget.controller.setLaundryFilter(null);
                            setModalState(() {});
                          },
                          selectedColor: WardrobeTheme.electricViolet,
                        ),
                        ...LaundryStatus.values.map((s) {
                          final isSelected =
                              widget.controller.selectedLaundryStatus == s;
                          return ChoiceChip(
                            label: Text(s.label),
                            selected: isSelected,
                            onSelected: (_) {
                              widget.controller
                                  .setLaundryFilter(isSelected ? null : s);
                              setModalState(() {});
                            },
                            selectedColor: WardrobeTheme.electricViolet,
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: WardrobeTheme.electricViolet,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Apply Filters',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSortModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: WardrobeTheme.elevatedSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sort Wardrobe',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: WardrobeTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Recently Added',
                      style: TextStyle(color: WardrobeTheme.textPrimary)),
                  trailing: widget.controller.sortBy == 'created_at' &&
                          widget.controller.sortOrder == 'desc'
                      ? Icon(Icons.check,
                          color: WardrobeTheme.electricViolet)
                      : null,
                  onTap: () {
                    widget.controller.setSort('created_at', 'desc');
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Name (A-Z)',
                      style: TextStyle(color: WardrobeTheme.textPrimary)),
                  trailing: widget.controller.sortBy == 'name' &&
                          widget.controller.sortOrder == 'asc'
                      ? Icon(Icons.check,
                          color: WardrobeTheme.electricViolet)
                      : null,
                  onTap: () {
                    widget.controller.setSort('name', 'asc');
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Recently Updated',
                      style: TextStyle(color: WardrobeTheme.textPrimary)),
                  trailing: widget.controller.sortBy == 'updated_at' &&
                          widget.controller.sortOrder == 'desc'
                      ? Icon(Icons.check,
                          color: WardrobeTheme.electricViolet)
                      : null,
                  onTap: () {
                    widget.controller.setSort('updated_at', 'desc');
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateToDetail(Garment garment) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WardrobeDetailScreen(
          initialGarment: garment,
          controller: widget.controller,
          userId: widget.authService?.currentUser?.id ?? 'tess_user',
        ),
      ),
    );
  }

  void _navigateToAddGarment() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GarmentFormScreen(
          controller: widget.controller,
          userId: widget.authService?.currentUser?.id ?? 'tess_user',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeFilterCount = widget.controller.activeFilterCount;

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
            icon: Icon(Icons.sort_rounded,
                color: WardrobeTheme.textSecondary, size: 20),
            tooltip: 'Sort Options',
            onPressed: _showSortModal,
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.tune_rounded,
                    color: WardrobeTheme.textSecondary, size: 20),
                tooltip: 'Filter Options',
                onPressed: _showFilterModal,
              ),
              if (activeFilterCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: WardrobeTheme.electricViolet,
                      shape: BoxShape.circle,
                    ),
                    constraints:
                        const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '$activeFilterCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.add_rounded,
                color: WardrobeTheme.electricCyan, size: 24),
            tooltip: 'Add Garment',
            onPressed: _navigateToAddGarment,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: WardrobeTheme.electricViolet,
        foregroundColor: Colors.white,
        tooltip: 'Add Garment',
        onPressed: _navigateToAddGarment,
        child: const Icon(Icons.add),
      ),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final displayedGarments = widget.controller.filteredGarments;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search Bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: WardrobeTheme.spatialSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: WardrobeTheme.border, width: 1.0),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => widget.controller.setSearchQuery(val),
                    style: TextStyle(
                        fontSize: 13, color: WardrobeTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search garments by name, color, category...',
                      hintStyle: TextStyle(
                          fontSize: 12, color: WardrobeTheme.textMuted),
                      prefixIcon: Icon(Icons.search,
                          size: 18, color: WardrobeTheme.textMuted),
                      suffixIcon: widget.controller.searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear,
                                  size: 16, color: WardrobeTheme.textMuted),
                              onPressed: () {
                                _searchController.clear();
                                widget.controller.setSearchQuery('');
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
                      final isSelected =
                          widget.controller.selectedCategory?.toLowerCase() ==
                              cat.name.toLowerCase();
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: CategoryChip(
                          label: cat.name,
                          isSelected: isSelected,
                          onTap: () =>
                              widget.controller.setCategoryFilter(cat.name),
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
                              Icon(
                                Icons.filter_alt_off_outlined,
                                color: WardrobeTheme.textMuted,
                                size: 40,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No garments match your filters',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: WardrobeTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
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
                                  widget.controller.clearAllFilters();
                                },
                                child: Text(
                                  'Clear All Filters',
                                  style: TextStyle(
                                      color: WardrobeTheme.electricCyan),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        itemCount: displayedGarments.length,
                        itemBuilder: (ctx, i) {
                          final garment = displayedGarments[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: GestureDetector(
                              onTap: () => _navigateToDetail(garment),
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  garment.name,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color: WardrobeTheme
                                                        .textPrimary,
                                                  ),
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: () => widget.controller
                                                    .toggleFavorite(garment.id),
                                                child: Icon(
                                                  garment.isFavorite
                                                      ? Icons.favorite_rounded
                                                      : Icons
                                                          .favorite_border_rounded,
                                                  color: garment.isFavorite
                                                      ? WardrobeTheme
                                                          .statusCritical
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
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  fontFamily: 'monospace',
                                                  color:
                                                      WardrobeTheme.softViolet,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  '•  ${garment.mainCategory}${garment.sleeveLength != null ? " • ${garment.sleeveLength}" : ""}',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: WardrobeTheme
                                                        .textSecondary,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          GestureDetector(
                                            onTap: () =>
                                                _showLaundryStatusSheet(
                                                    garment),
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
