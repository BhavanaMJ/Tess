import 'package:flutter/material.dart';
import '../controllers/laundry_controller.dart';
import '../theme/wardrobe_theme.dart';
import '../widgets/laundry_batch_card.dart';
import '../widgets/laundry_status_card.dart';
import 'laundry_batch_create_screen.dart';
import 'laundry_batch_detail_screen.dart';
import 'laundry_status_items_screen.dart';

class LaundryDashboardScreen extends StatefulWidget {
  final LaundryController controller;

  const LaundryDashboardScreen({
    super.key,
    required this.controller,
  });

  @override
  State<LaundryDashboardScreen> createState() => _LaundryDashboardScreenState();
}

class _LaundryDashboardScreenState extends State<LaundryDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.loadDashboardData();
    });
  }

  void _navigateToStatus(String? status, String title) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LaundryStatusItemsScreen(
          controller: widget.controller,
          statusFilter: status,
          statusTitle: title,
        ),
      ),
    ).then((_) {
      widget.controller.loadDashboardData();
    });
  }

  void _navigateToBatchCreate() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LaundryBatchCreateScreen(
          controller: widget.controller,
        ),
      ),
    ).then((_) {
      widget.controller.loadDashboardData();
    });
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
        title: Row(
          children: [
            const Text(
              'Laundry Manager',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: WardrobeTheme.textPrimary,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: WardrobeTheme.electricViolet.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: WardrobeTheme.electricViolet.withValues(alpha: 0.35),
                  width: 1.0,
                ),
              ),
              child: const Text(
                'PHASE 4',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: WardrobeTheme.softViolet,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: WardrobeTheme.textSecondary, size: 20),
            tooltip: 'Refresh Metrics',
            onPressed: () => widget.controller.loadDashboardData(),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          if (widget.controller.isLoading && widget.controller.stats.totalGarments == 0) {
            return const Center(
              child: CircularProgressIndicator(color: WardrobeTheme.electricViolet),
            );
          }

          final stats = widget.controller.stats;
          final activeBatches = widget.controller.activeBatches;

          return RefreshIndicator(
            color: WardrobeTheme.electricViolet,
            backgroundColor: WardrobeTheme.spatialSurface,
            onRefresh: widget.controller.loadDashboardData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Overview Banner
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: WardrobeTheme.spatialSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: WardrobeTheme.borderViolet),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: WardrobeTheme.electricCyan.withValues(alpha: 0.15),
                            border: Border.all(color: WardrobeTheme.borderCyan, width: 1.0),
                          ),
                          child: const Icon(
                            Icons.local_laundry_service_outlined,
                            color: WardrobeTheme.electricCyan,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Garment Lifecycle Tracking',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: WardrobeTheme.textPrimary,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Track clean, worn, and wash cycles. Create batches and preserve individual overrides.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: WardrobeTheme.textSecondary,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Status Grid Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'GARMENTS BY LAUNDRY STATUS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: WardrobeTheme.textSecondary,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        '${stats.totalGarments} TOTAL',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: WardrobeTheme.softViolet,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // 2x3 Grid of Status Cards
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.25,
                    children: [
                      LaundryStatusCard(
                        title: 'Worn / Hamper',
                        subtitle: 'Ready for washing',
                        count: stats.wornCount,
                        icon: Icons.checkroom_rounded,
                        accentColor: WardrobeTheme.statusWarning,
                        onTap: () => _navigateToStatus('WORN', 'Worn / In Hamper'),
                      ),
                      LaundryStatusCard(
                        title: 'In Washing',
                        subtitle: 'Wash cycle active',
                        count: stats.washingCount,
                        icon: Icons.local_laundry_service_rounded,
                        accentColor: WardrobeTheme.electricCyan,
                        onTap: () => _navigateToStatus('WASHING', 'In Washing'),
                      ),
                      LaundryStatusCard(
                        title: 'Drying',
                        subtitle: 'Drying & line air',
                        count: stats.dryingCount,
                        icon: Icons.air_rounded,
                        accentColor: WardrobeTheme.electricViolet,
                        onTap: () => _navigateToStatus('DRYING', 'Drying'),
                      ),
                      LaundryStatusCard(
                        title: 'Clean & Ready',
                        subtitle: 'Available to wear',
                        count: stats.cleanCount,
                        icon: Icons.verified_rounded,
                        accentColor: WardrobeTheme.statusSuccess,
                        onTap: () => _navigateToStatus('CLEAN', 'Clean & Ready'),
                      ),
                      LaundryStatusCard(
                        title: 'Stored',
                        subtitle: 'Put away in closet',
                        count: stats.storedCount,
                        icon: Icons.inventory_2_outlined,
                        accentColor: WardrobeTheme.softViolet,
                        onTap: () => _navigateToStatus('STORED', 'Stored / Put Away'),
                      ),
                      LaundryStatusCard(
                        title: 'Status Not Assigned',
                        subtitle: 'Requires verification',
                        count: stats.unassignedCount,
                        icon: Icons.help_outline_rounded,
                        accentColor: WardrobeTheme.textMuted,
                        onTap: () => _navigateToStatus('UNASSIGNED', 'Status Not Assigned'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Action Button: Create Laundry Batch
                  ElevatedButton.icon(
                    onPressed: _navigateToBatchCreate,
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    label: const Text('Start New Laundry Batch', style: TextStyle(fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: WardrobeTheme.electricViolet,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Active Batches Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ACTIVE LAUNDRY BATCHES',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: WardrobeTheme.textSecondary,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: WardrobeTheme.electricCyan.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${activeBatches.length} ACTIVE',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: WardrobeTheme.electricCyan,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  if (activeBatches.isEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: WardrobeTheme.spatialSurface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: WardrobeTheme.borderSubtle),
                      ),
                      child: const Center(
                        child: Text(
                          'No active wash batches right now. Group worn clothes into a batch when doing laundry.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: WardrobeTheme.textMuted),
                        ),
                      ),
                    ),
                  ] else ...[
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: activeBatches.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, idx) {
                        final b = activeBatches[idx];
                        return LaundryBatchCard(
                          batch: b,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => LaundryBatchDetailScreen(
                                  controller: widget.controller,
                                  batchId: b.id,
                                ),
                              ),
                            ).then((_) {
                              widget.controller.loadDashboardData();
                            });
                          },
                        );
                      },
                    ),
                  ],

                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
