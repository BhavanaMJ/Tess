import 'package:flutter/material.dart';
import '../controllers/calendar_controller.dart';
import '../theme/wardrobe_theme.dart';
import '../widgets/actual_outfit_card.dart';

class OutfitHistoryScreen extends StatefulWidget {
  final CalendarController controller;

  const OutfitHistoryScreen({
    super.key,
    required this.controller,
  });

  @override
  State<OutfitHistoryScreen> createState() => _OutfitHistoryScreenState();
}

class _OutfitHistoryScreenState extends State<OutfitHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    widget.controller.loadHistory();
    widget.controller.loadIntelligence();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final wears = widget.controller.wearHistory;
        final unused = widget.controller.unusedGarments;
        final recent = widget.controller.recentlyWornGarments;

        return Scaffold(
          backgroundColor: WardrobeTheme.voidBg,
          appBar: AppBar(
            backgroundColor: WardrobeTheme.voidBg,
            elevation: 0,
            title: Text(
              'Wear History & Intelligence',
              style: TextStyle(color: WardrobeTheme.textPrimary, fontSize: 18),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: WardrobeTheme.electricViolet,
              indicatorWeight: 2,
              labelColor: WardrobeTheme.electricViolet,
              unselectedLabelColor: WardrobeTheme.textMuted,
              tabs: [
                Tab(text: 'Worn Outfits (${wears.length})'),
                Tab(text: 'Unused (${unused.length})'),
                Tab(text: 'Recent Pieces (${recent.length})'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // 1. Wear History Tab
              if (wears.isEmpty)
                Center(
                  child: Text(
                    'No recorded outfit wear history yet.\nConfirm what you wear from the Outfit Calendar.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: WardrobeTheme.textMuted, fontSize: 14),
                  ),
                )
              else
                ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: wears.length,
                  itemBuilder: (context, idx) => ActualOutfitCard(wear: wears[idx]),
                ),

              // 2. Unused Garments Tab
              if (unused.isEmpty)
                Center(
                  child: Text(
                    'All your garments have been worn recently!',
                    style: TextStyle(color: WardrobeTheme.textMuted, fontSize: 14),
                  ),
                )
              else
                ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: unused.length,
                  itemBuilder: (context, idx) {
                    final item = unused[idx];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: WardrobeTheme.spatialSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: WardrobeTheme.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: WardrobeTheme.railBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.checkroom_rounded, size: 20, color: WardrobeTheme.textMuted),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.garmentName,
                                  style: TextStyle(
                                    color: WardrobeTheme.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${item.mainCategory} • ${item.primaryColor}',
                                  style: TextStyle(color: WardrobeTheme.textMuted, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: WardrobeTheme.statusWarning.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.wearCount == 0 ? 'Never Worn' : '30+ Days Unused',
                              style: TextStyle(
                                color: WardrobeTheme.statusWarning,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

              // 3. Recently Worn Garments Tab
              if (recent.isEmpty)
                Center(
                  child: Text(
                    'No garment wear history available.',
                    style: TextStyle(color: WardrobeTheme.textMuted, fontSize: 14),
                  ),
                )
              else
                ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: recent.length,
                  itemBuilder: (context, idx) {
                    final item = recent[idx];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: WardrobeTheme.spatialSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: WardrobeTheme.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: WardrobeTheme.railBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.dry_cleaning_rounded, size: 20, color: WardrobeTheme.electricCyan),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.garmentName,
                                  style: TextStyle(
                                    color: WardrobeTheme.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${item.mainCategory} • ${item.primaryColor}',
                                  style: TextStyle(color: WardrobeTheme.textMuted, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'Worn ${item.wearCount}x',
                            style: TextStyle(
                              color: WardrobeTheme.electricCyan,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

