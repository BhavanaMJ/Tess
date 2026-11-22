import 'package:flutter/material.dart';
import '../../domain/entities/laundry_batch.dart';
import '../../domain/entities/laundry_status.dart';
import '../controllers/laundry_controller.dart';
import '../theme/wardrobe_theme.dart';
import '../widgets/garment_image_placeholder.dart';
import '../widgets/laundry_status_selector_sheet.dart';

class LaundryBatchDetailScreen extends StatefulWidget {
  final LaundryController controller;
  final String batchId;

  const LaundryBatchDetailScreen({
    super.key,
    required this.controller,
    required this.batchId,
  });

  @override
  State<LaundryBatchDetailScreen> createState() => _LaundryBatchDetailScreenState();
}

class _LaundryBatchDetailScreenState extends State<LaundryBatchDetailScreen> {
  LaundryBatch? _batch;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBatch();
  }

  void _loadBatch() {
    final b = widget.controller.batches.cast<LaundryBatch?>().firstWhere(
      (item) => item?.id == widget.batchId,
      orElse: () => null,
    );
    setState(() {
      _batch = b;
      _isLoading = false;
    });
  }

  Future<void> _advanceBatch() async {
    if (_batch == null) return;

    String nextStatus;
    if (_batch!.status == 'CREATED') {
      nextStatus = 'WASHING';
    } else if (_batch!.status == 'WASHING') {
      nextStatus = 'DRYING';
    } else if (_batch!.status == 'DRYING') {
      nextStatus = 'COMPLETED';
    } else {
      return;
    }

    final res = await widget.controller.advanceBatch(widget.batchId, nextStatus);
    if (!mounted) return;

    if (res != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: WardrobeTheme.elevatedSurface,
          content: Text(res['message']?.toString() ?? 'Batch advanced to $nextStatus'),
        ),
      );
      _loadBatch();
    }
  }

  void _overrideGarmentStatus(String garmentId, String garmentName, String? currentStatusStr) {
    showModalBottomSheet(
      context: context,
      backgroundColor: WardrobeTheme.elevatedSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => LaundryStatusSelectorSheet(
        garmentName: garmentName,
        currentStatus: LaundryStatus.fromString(currentStatusStr),
        onSelected: (newStatus) async {
          await widget.controller.updateGarmentStatus(
            garmentId,
            newStatus,
            notes: 'Individual override within ${_batch?.batchNumber}',
          );
          if (mounted) {
            _loadBatch();
          }
        },
      ),
    );
  }

  Widget _buildStep(String label, bool isCompleted, bool isCurrent) {
    Color color = isCompleted || isCurrent
        ? WardrobeTheme.electricViolet
        : WardrobeTheme.textMuted;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCurrent
                  ? WardrobeTheme.electricViolet
                  : (isCompleted ? WardrobeTheme.statusSuccess : WardrobeTheme.spatialSurface),
              border: Border.all(
                color: isCurrent || isCompleted ? WardrobeTheme.electricViolet : WardrobeTheme.border,
                width: 1.5,
              ),
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : Text(
                      label[0],
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final b = _batch;

    return Scaffold(
      backgroundColor: WardrobeTheme.voidBg,
      appBar: AppBar(
        backgroundColor: WardrobeTheme.voidBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: WardrobeTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          b?.batchNumber ?? 'Batch Detail',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: WardrobeTheme.textPrimary,
          ),
        ),
      ),
      body: _isLoading || b == null
          ? const Center(child: CircularProgressIndicator(color: WardrobeTheme.electricViolet))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Batch Metadata Header
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
                              b.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: WardrobeTheme.textPrimary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: WardrobeTheme.electricViolet.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                b.status,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: WardrobeTheme.softViolet,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (b.notes != null && b.notes!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            b.notes!,
                            style: const TextStyle(fontSize: 12, color: WardrobeTheme.textSecondary),
                          ),
                        ],

                        const SizedBox(height: 16),

                        // Lifecycle Stepper
                        Row(
                          children: [
                            _buildStep('Created', b.status != 'CREATED', b.status == 'CREATED'),
                            _buildStep('Washing', b.status == 'DRYING' || b.status == 'COMPLETED', b.status == 'WASHING'),
                            _buildStep('Drying', b.status == 'COMPLETED', b.status == 'DRYING'),
                            _buildStep('Done', b.status == 'COMPLETED', b.status == 'COMPLETED'),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Garments in Batch Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'MEMBER GARMENTS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: WardrobeTheme.textSecondary,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        '${b.items.length} GARMENTS',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: WardrobeTheme.softViolet,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Member Garment Cards with individual status pill & override button
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: b.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, idx) {
                      final item = b.items[idx];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: WardrobeTheme.spatialSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: WardrobeTheme.borderSubtle),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                width: 44,
                                height: 44,
                                color: WardrobeTheme.studioBackground,
                                child: GarmentImagePlaceholder(
                                  imageUrl: item.thumbnailRef,
                                  category: item.garmentCategory ?? 'Tops',
                                  width: 44,
                                  height: 44,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.garmentName ?? 'Garment ${item.garmentId}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: WardrobeTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Text(
                                        item.garmentId,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: WardrobeTheme.textMuted,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: WardrobeTheme.electricViolet.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          item.currentLaundryStatus ?? 'UNSET',
                                          style: const TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: WardrobeTheme.softViolet,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Override Status Button
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: WardrobeTheme.electricCyan, size: 20),
                              tooltip: 'Override Individual Status',
                              onPressed: () => _overrideGarmentStatus(
                                item.garmentId,
                                item.garmentName ?? item.garmentId,
                                item.currentLaundryStatus,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 28),

                  // Next Action Button
                  if (b.status == 'CREATED')
                    ElevatedButton.icon(
                      onPressed: _advanceBatch,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Start Washing Batch'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: WardrobeTheme.electricCyan,
                        foregroundColor: WardrobeTheme.voidBg,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    )
                  else if (b.status == 'WASHING')
                    ElevatedButton.icon(
                      onPressed: _advanceBatch,
                      icon: const Icon(Icons.air_rounded),
                      label: const Text('Move Batch to Drying'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: WardrobeTheme.electricViolet,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    )
                  else if (b.status == 'DRYING')
                    ElevatedButton.icon(
                      onPressed: _advanceBatch,
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      label: const Text('Complete Laundry & Mark Clean'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: WardrobeTheme.statusSuccess,
                        foregroundColor: WardrobeTheme.voidBg,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    )
                  else if (b.status == 'COMPLETED')
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: WardrobeTheme.statusSuccess.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: WardrobeTheme.statusSuccess.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.verified_rounded, color: WardrobeTheme.statusSuccess, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Laundry Lifecycle Completed',
                            style: TextStyle(
                              color: WardrobeTheme.statusSuccess,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
