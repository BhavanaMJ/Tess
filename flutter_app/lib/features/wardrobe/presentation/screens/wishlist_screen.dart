import 'package:flutter/material.dart';
import '../../domain/entities/wishlist_item.dart';
import '../../domain/repositories/wishlist_repository.dart';
import '../controllers/wishlist_controller.dart';
import '../theme/wardrobe_theme.dart';
import '../widgets/wishlist_summary_card.dart';
import '../widgets/wishlist_item_card.dart';
import '../widgets/wishlist_empty_state.dart';
import 'wishlist_add_edit_screen.dart';
import 'wishlist_detail_screen.dart';
import 'wardrobe_gap_analysis_screen.dart';
import 'purchase_assessment_screen.dart';

class WishlistScreen extends StatefulWidget {
  final WishlistController? controller;
  final WishlistRepository? repository;

  const WishlistScreen({
    super.key,
    this.controller,
    this.repository,
  });

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  late final WishlistController _controller;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = WishlistController(repository: widget.repository!);
      _controller.loadDashboard();
    }
  }

  void _navigateToAdd() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => WishlistAddEditScreen(controller: _controller),
      ),
    );
    if (result == true) {
      _controller.loadDashboard();
    }
  }

  void _navigateToDetail(WishlistItem item) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => WishlistDetailScreen(
          item: item,
          controller: _controller,
        ),
      ),
    );
    if (result == true) {
      _controller.loadDashboard();
    }
  }

  void _navigateToGaps() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WardrobeGapAnalysisScreen(controller: _controller),
      ),
    );
  }

  void _navigateToAssessment(WishlistItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PurchaseAssessmentScreen(
          item: item,
          controller: _controller,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WardrobeTheme.voidBlack,
      appBar: AppBar(
        backgroundColor: WardrobeTheme.voidBlack,
        title: const Text(
          'Wardrobe Wishlist',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: WardrobeTheme.textPrimary,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: WardrobeTheme.electricViolet.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: WardrobeTheme.electricViolet.withValues(alpha: 0.3)),
            ),
            child: const Text(
              'PHASE 8',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: WardrobeTheme.softViolet,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAdd,
        backgroundColor: WardrobeTheme.electricViolet,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add to Wishlist',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.isLoading && _controller.items.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: WardrobeTheme.electricViolet),
            );
          }

          final items = _controller.filteredItems;

          return RefreshIndicator(
            onRefresh: _controller.loadDashboard,
            color: WardrobeTheme.electricViolet,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 1. Summary Card
                if (_controller.summary != null) ...[
                  WishlistSummaryCard(summary: _controller.summary!),
                  const SizedBox(height: 16),
                ],

                // 2. Wardrobe Gap Intelligence Callout Banner
                if (_controller.gaps.isNotEmpty) ...[
                  InkWell(
                    onTap: _navigateToGaps,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: WardrobeTheme.electricCyan.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: WardrobeTheme.electricCyan.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome_rounded,
                              size: 20, color: WardrobeTheme.electricCyan),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_controller.gaps.length} Wardrobe Gaps Identified',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: WardrobeTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'See items that maximize combinations with your existing wardrobe.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: WardrobeTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded,
                              size: 14, color: WardrobeTheme.electricCyan),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 3. Priority Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildPriorityFilterChip(null, 'All Priorities'),
                      const SizedBox(width: 8),
                      _buildPriorityFilterChip(PurchasePriority.high, 'High Priority'),
                      const SizedBox(width: 8),
                      _buildPriorityFilterChip(PurchasePriority.medium, 'Medium'),
                      const SizedBox(width: 8),
                      _buildPriorityFilterChip(PurchasePriority.low, 'Low'),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // 4. Status Filter Pills
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatusFilterChip(null, 'All Status'),
                      const SizedBox(width: 8),
                      _buildStatusFilterChip(WishlistStatus.considering, 'Considering'),
                      const SizedBox(width: 8),
                      _buildStatusFilterChip(WishlistStatus.shortlisted, 'Shortlisted'),
                      const SizedBox(width: 8),
                      _buildStatusFilterChip(WishlistStatus.purchased, 'Purchased'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 5. Items List or Empty State
                if (items.isEmpty) ...[
                  WishlistEmptyState(
                    onAddItem: _navigateToAdd,
                    onExploreGaps: _navigateToGaps,
                  ),
                ] else ...[
                  ...items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: WishlistItemCard(
                        item: item,
                        onTap: () => _navigateToDetail(item),
                        onAssess: () => _navigateToAssessment(item),
                        onToggleStatus: () {
                          final next = item.status == WishlistStatus.considering
                              ? WishlistStatus.shortlisted
                              : WishlistStatus.considering;
                          _controller.updateStatus(item.id, next);
                        },
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 60),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPriorityFilterChip(PurchasePriority? priority, String label) {
    final isSelected = _controller.selectedPriorityFilter == priority;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? Colors.white : WardrobeTheme.textMuted,
      ),
      backgroundColor: WardrobeTheme.spatialSurface,
      selectedColor: WardrobeTheme.electricViolet,
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? WardrobeTheme.electricViolet : WardrobeTheme.subtleBorder,
        ),
      ),
      onSelected: (_) => _controller.setPriorityFilter(priority),
    );
  }

  Widget _buildStatusFilterChip(WishlistStatus? status, String label) {
    final isSelected = _controller.selectedStatusFilter == status;
    return ChoiceChip(
      selected: isSelected,
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? Colors.white : WardrobeTheme.textMuted,
      ),
      backgroundColor: WardrobeTheme.spatialSurface,
      selectedColor: WardrobeTheme.electricCyan.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? WardrobeTheme.electricCyan : WardrobeTheme.subtleBorder,
        ),
      ),
      onSelected: (_) => _controller.setStatusFilter(status),
    );
  }
}
