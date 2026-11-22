import 'package:flutter/material.dart';
import '../../domain/entities/garment.dart';
import '../../domain/entities/laundry_history_entry.dart';
import '../controllers/laundry_controller.dart';
import '../theme/wardrobe_theme.dart';
import '../widgets/garment_image_placeholder.dart';
import '../widgets/garment_status_indicator.dart';
import '../widgets/laundry_history_timeline.dart';
import '../widgets/laundry_status_selector_sheet.dart';

class GarmentLaundryHistoryScreen extends StatefulWidget {
  final Garment garment;
  final LaundryController controller;

  const GarmentLaundryHistoryScreen({
    super.key,
    required this.garment,
    required this.controller,
  });

  @override
  State<GarmentLaundryHistoryScreen> createState() =>
      _GarmentLaundryHistoryScreenState();
}

class _GarmentLaundryHistoryScreenState
    extends State<GarmentLaundryHistoryScreen> {
  late Garment _garment;
  List<LaundryHistoryEntry> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _garment = widget.garment;
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final list = await widget.controller.loadGarmentHistory(_garment.id);
    if (mounted) {
      setState(() {
        _history = list;
        _isLoading = false;
      });
    }
  }

  void _showStatusSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: WardrobeTheme.elevatedSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => LaundryStatusSelectorSheet(
        garmentName: _garment.name,
        currentStatus: _garment.laundryStatus,
        onSelected: (newStatus) async {
          final ok = await widget.controller
              .updateGarmentStatus(_garment.id, newStatus);
          if (ok && mounted) {
            setState(() {
              _garment = _garment.copyWith(laundryStatus: newStatus);
            });
            _loadHistory();
          }
        },
      ),
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Never';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
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
          'Laundry History',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: WardrobeTheme.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Garment Summary Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: WardrobeTheme.spatialSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: WardrobeTheme.borderViolet),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 64,
                      height: 64,
                      color: WardrobeTheme.studioBackground,
                      child: GarmentImagePlaceholder(
                        imageUrl: _garment.displayImageRef,
                        category: _garment.mainCategory,
                        width: 64,
                        height: 64,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _garment.id,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: WardrobeTheme.textMuted,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(width: 6),
                            GarmentStatusIndicator(
                                status: _garment.laundryStatus, compact: true),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _garment.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: WardrobeTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_garment.mainCategory} • ${_garment.primaryColor}',
                          style: const TextStyle(
                              fontSize: 12, color: WardrobeTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.swap_horiz_rounded,
                        color: WardrobeTheme.electricViolet),
                    tooltip: 'Change Status',
                    onPressed: _showStatusSelector,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Telemetry Counters
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: WardrobeTheme.spatialSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: WardrobeTheme.borderSubtle),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('TOTAL WEARS',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: WardrobeTheme.textMuted)),
                        const SizedBox(height: 4),
                        Text('${_garment.wearCount}',
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: WardrobeTheme.statusWarning)),
                        const SizedBox(height: 2),
                        Text('Last: ${_formatDate(_garment.lastWornDate)}',
                            style: const TextStyle(
                                fontSize: 10,
                                color: WardrobeTheme.textSecondary)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: WardrobeTheme.spatialSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: WardrobeTheme.borderSubtle),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('TOTAL WASHES',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: WardrobeTheme.textMuted)),
                        const SizedBox(height: 4),
                        Text('${_garment.washCount}',
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: WardrobeTheme.electricCyan)),
                        const SizedBox(height: 2),
                        Text('Last: ${_formatDate(_garment.lastWashedDate)}',
                            style: const TextStyle(
                                fontSize: 10,
                                color: WardrobeTheme.textSecondary)),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // History Timeline Section
            const Text(
              'LIFECYCLE TIMELINE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: WardrobeTheme.textSecondary,
                letterSpacing: 0.8,
              ),
            ),

            const SizedBox(height: 12),

            _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: WardrobeTheme.electricViolet))
                : LaundryHistoryTimeline(history: _history),
          ],
        ),
      ),
    );
  }
}
