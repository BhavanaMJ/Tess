import 'package:flutter/material.dart';
import '../../domain/entities/garment.dart';
import '../controllers/laundry_controller.dart';
import '../theme/wardrobe_theme.dart';
import '../widgets/garment_image_placeholder.dart';
import '../widgets/laundry_status_selector_sheet.dart';
import 'garment_laundry_history_screen.dart';
import 'laundry_batch_create_screen.dart';

class LaundryStatusItemsScreen extends StatefulWidget {
  final LaundryController controller;
  final String? statusFilter;
  final String statusTitle;

  const LaundryStatusItemsScreen({
    super.key,
    required this.controller,
    required this.statusFilter,
    required this.statusTitle,
  });

  @override
  State<LaundryStatusItemsScreen> createState() =>
      _LaundryStatusItemsScreenState();
}

class _LaundryStatusItemsScreenState extends State<LaundryStatusItemsScreen> {
  final Set<String> _selectedGarmentIds = {};
  bool _isSelectionMode = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.loadItemsByStatus(widget.statusFilter);
    });
  }

  void _showStatusSelector(Garment garment) {
    showModalBottomSheet(
      context: context,
      backgroundColor: WardrobeTheme.elevatedSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => LaundryStatusSelectorSheet(
        garmentName: garment.name,
        currentStatus: garment.laundryStatus,
        onSelected: (newStatus) async {
          final ok = await widget.controller
              .updateGarmentStatus(garment.id, newStatus);
          if (ok && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: WardrobeTheme.elevatedSurface,
                content: Text(
                    'Updated ${garment.name} to ${newStatus?.label ?? "Unassigned"}'),
              ),
            );
          }
        },
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.statusTitle,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: WardrobeTheme.textPrimary,
              ),
            ),
            Text(
              '${widget.controller.currentStatusItems.length} items',
              style:
                  TextStyle(fontSize: 11, color: WardrobeTheme.textMuted),
            ),
          ],
        ),
        actions: [
          if (widget.statusFilter == 'WORN' &&
              widget.controller.currentStatusItems.isNotEmpty)
            TextButton(
              onPressed: () {
                setState(() {
                  _isSelectionMode = !_isSelectionMode;
                  if (!_isSelectionMode) _selectedGarmentIds.clear();
                });
              },
              child: Text(
                _isSelectionMode ? 'Cancel' : 'Select',
                style: TextStyle(
                    color: WardrobeTheme.electricViolet,
                    fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          if (widget.controller.isLoading) {
            return Center(
                child: CircularProgressIndicator(
                    color: WardrobeTheme.electricViolet));
          }

          final allItems = widget.controller.currentStatusItems;
          final items = _searchQuery.trim().isEmpty
              ? allItems
              : allItems
                  .where((g) =>
                      g.name
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase()) ||
                      g.id.toLowerCase().contains(_searchQuery.toLowerCase()))
                  .toList();

          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.checkroom_rounded,
                        size: 48, color: WardrobeTheme.textMuted),
                    const SizedBox(height: 12),
                    Text(
                      'No garments currently in "${widget.statusTitle}"',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: WardrobeTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              // Search Input
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  style: TextStyle(
                      color: WardrobeTheme.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search by name or CLO-ID...',
                    hintStyle: TextStyle(
                        color: WardrobeTheme.textMuted, fontSize: 13),
                    prefixIcon: Icon(Icons.search_rounded,
                        color: WardrobeTheme.textMuted, size: 18),
                    filled: true,
                    fillColor: WardrobeTheme.spatialSurface,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: WardrobeTheme.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: WardrobeTheme.border),
                    ),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),

              // Garments List
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, idx) {
                    final garment = items[idx];
                    final isSelected = _selectedGarmentIds.contains(garment.id);

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          if (_isSelectionMode) {
                            setState(() {
                              if (isSelected) {
                                _selectedGarmentIds.remove(garment.id);
                              } else {
                                _selectedGarmentIds.add(garment.id);
                              }
                            });
                          } else {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => GarmentLaundryHistoryScreen(
                                  garment: garment,
                                  controller: widget.controller,
                                ),
                              ),
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: WardrobeTheme.spatialSurface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? WardrobeTheme.electricViolet
                                  : WardrobeTheme.borderSubtle,
                              width: isSelected ? 2.0 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              if (_isSelectionMode) ...[
                                Checkbox(
                                  value: isSelected,
                                  activeColor: WardrobeTheme.electricViolet,
                                  onChanged: (val) {
                                    setState(() {
                                      if (val == true) {
                                        _selectedGarmentIds.add(garment.id);
                                      } else {
                                        _selectedGarmentIds.remove(garment.id);
                                      }
                                    });
                                  },
                                ),
                                const SizedBox(width: 8),
                              ],

                              // Thumbnail
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: 56,
                                  height: 56,
                                  color: WardrobeTheme.studioBackground,
                                  child: GarmentImagePlaceholder(
                                    imageUrl: garment.displayImageRef,
                                    category: garment.mainCategory,
                                    width: 56,
                                    height: 56,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          garment.id,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: WardrobeTheme.textMuted,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '• ${garment.mainCategory}',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color:
                                                  WardrobeTheme.textSecondary),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      garment.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: WardrobeTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        if (garment.wearCount > 0)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                right: 8.0),
                                            child: Text(
                                              'Worn: ${garment.wearCount}x',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: WardrobeTheme
                                                      .statusWarning),
                                            ),
                                          ),
                                        if (garment.washCount > 0)
                                          Text(
                                            'Washed: ${garment.washCount}x',
                                            style: TextStyle(
                                                fontSize: 11,
                                                color:
                                                    WardrobeTheme.electricCyan),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Quick status change button
                              IconButton(
                                icon: Icon(Icons.swap_horiz_rounded,
                                    color: WardrobeTheme.electricViolet,
                                    size: 22),
                                tooltip: 'Change Status',
                                onPressed: () => _showStatusSelector(garment),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Bottom Batch Creation Action Bar if items selected
              if (_isSelectionMode && _selectedGarmentIds.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: WardrobeTheme.elevatedSurface,
                    border: Border(
                        top: BorderSide(color: WardrobeTheme.borderSubtle)),
                  ),
                  child: SafeArea(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context)
                            .push(
                          MaterialPageRoute(
                            builder: (_) => LaundryBatchCreateScreen(
                              controller: widget.controller,
                              preselectedGarmentIds:
                                  _selectedGarmentIds.toList(),
                            ),
                          ),
                        )
                            .then((_) {
                          setState(() {
                            _isSelectionMode = false;
                            _selectedGarmentIds.clear();
                          });
                          widget.controller
                              .loadItemsByStatus(widget.statusFilter);
                        });
                      },
                      icon: const Icon(Icons.local_laundry_service_outlined),
                      label: Text(
                          'Create Batch (${_selectedGarmentIds.length} items)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: WardrobeTheme.electricViolet,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
