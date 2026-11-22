import 'package:flutter/material.dart';
import '../../domain/entities/outfit_plan.dart';
import '../controllers/calendar_controller.dart';
import '../controllers/outfit_controller.dart';
import '../theme/wardrobe_theme.dart';

class ActualWearScreen extends StatefulWidget {
  final CalendarController controller;
  final OutfitPlan? plan;
  final DateTime? date;
  final OutfitController? outfitController;

  const ActualWearScreen({
    super.key,
    required this.controller,
    this.plan,
    this.date,
    this.outfitController,
  });

  @override
  State<ActualWearScreen> createState() => _ActualWearScreenState();
}

class _ActualWearScreenState extends State<ActualWearScreen> {
  late DateTime _wearDate;
  String? _selectedOutfitId;
  String? _selectedOutfitName;
  late TextEditingController _notesController;
  bool _woreDifferentOutfit = false;

  @override
  void initState() {
    super.initState();
    _wearDate = widget.date ??
        (widget.plan != null
            ? DateTime.tryParse(widget.plan!.plannedDate) ?? DateTime.now()
            : DateTime.now());
    _selectedOutfitId = widget.plan?.outfitId;
    _selectedOutfitName = widget.plan?.outfitName;
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _confirmWear() async {
    final outfitId = _selectedOutfitId;
    if (outfitId == null || outfitId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an outfit to confirm wear')),
      );
      return;
    }

    final planId = !_woreDifferentOutfit ? widget.plan?.id : null;

    final wear = await widget.controller.recordActualWear(
      outfitId: outfitId,
      actualWornDate: _wearDate,
      planId: planId,
      notes: _notesController.text.trim(),
    );

    if (!mounted) return;

    if (wear != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Confirmed wear for "${wear.outfitName}". Garments updated to Worn.'),
          backgroundColor: WardrobeTheme.statusSuccess,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.controller.errorMessage ?? 'Failed to confirm wear'),
          backgroundColor: WardrobeTheme.statusCritical,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPlan = widget.plan != null;
    final plan = widget.plan;

    return Scaffold(
      backgroundColor: WardrobeTheme.voidBg,
      appBar: AppBar(
        backgroundColor: WardrobeTheme.voidBg,
        elevation: 0,
        title: const Text(
          'Confirm Actual Wear',
          style: TextStyle(color: WardrobeTheme.textPrimary, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Workflow explanation card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: WardrobeTheme.electricCyan.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: WardrobeTheme.borderCyan),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: WardrobeTheme.electricCyan, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Confirming wear transitions all constituent garments to Worn and increments wear counts in your digital wardrobe.',
                      style: TextStyle(color: WardrobeTheme.textSecondary, fontSize: 12, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Date
            const Text(
              'Date Worn',
              style: TextStyle(color: WardrobeTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: WardrobeTheme.spatialSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: WardrobeTheme.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event_available_rounded, color: WardrobeTheme.electricCyan, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    '${_wearDate.year}-${_wearDate.month.toString().padLeft(2, '0')}-${_wearDate.day.toString().padLeft(2, '0')}',
                    style: const TextStyle(color: WardrobeTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // If there's a planned look, show it with Workflow A vs Workflow B toggle
            if (hasPlan && !_woreDifferentOutfit) ...[
              const Text(
                'Planned Look (Workflow A)',
                style: TextStyle(color: WardrobeTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
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
                    Text(
                      plan!.outfitName,
                      style: const TextStyle(color: WardrobeTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Occasion: ${plan.occasion}',
                      style: const TextStyle(color: WardrobeTheme.textMuted, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: plan.outfit.items.map((it) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: WardrobeTheme.railBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            it.name,
                            style: const TextStyle(color: WardrobeTheme.textSecondary, fontSize: 11),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _woreDifferentOutfit = true;
                    _selectedOutfitId = null;
                    _selectedOutfitName = null;
                  });
                },
                icon: const Icon(Icons.swap_horiz_rounded, size: 16, color: WardrobeTheme.softViolet),
                label: const Text(
                  'I wore a different outfit instead (Workflow B)',
                  style: TextStyle(color: WardrobeTheme.softViolet, fontSize: 12),
                ),
              ),
            ] else ...[
              // Workflow B: Picking a different or unplanned outfit
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Worn Outfit',
                    style: TextStyle(color: WardrobeTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  if (hasPlan)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _woreDifferentOutfit = false;
                          _selectedOutfitId = plan!.outfitId;
                          _selectedOutfitName = plan.outfitName;
                        });
                      },
                      child: const Text('Back to planned look', style: TextStyle(color: WardrobeTheme.softViolet, fontSize: 12)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (widget.outfitController?.savedOutfits.isNotEmpty ?? false)
                Container(
                  decoration: BoxDecoration(
                    color: WardrobeTheme.spatialSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: WardrobeTheme.border),
                  ),
                  child: Column(
                    children: widget.outfitController!.savedOutfits.map((outfit) {
                      final isSelected = _selectedOutfitId == outfit.id;
                      return ListTile(
                        title: Text(
                          outfit.name,
                          style: TextStyle(
                            color: isSelected ? WardrobeTheme.electricCyan : WardrobeTheme.textPrimary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          '${outfit.occasion} • ${outfit.items.length} items',
                          style: const TextStyle(color: WardrobeTheme.textMuted, fontSize: 12),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded, color: WardrobeTheme.electricCyan)
                            : null,
                        onTap: () {
                          setState(() {
                            _selectedOutfitId = outfit.id;
                            _selectedOutfitName = outfit.name;
                          });
                        },
                      );
                    }).toList(),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: WardrobeTheme.spatialSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: WardrobeTheme.border),
                  ),
                  child: Text(
                    _selectedOutfitName ?? 'Custom Outfit',
                    style: const TextStyle(color: WardrobeTheme.textPrimary, fontSize: 14),
                  ),
                ),
            ],

            const SizedBox(height: 20),

            // Notes
            const Text(
              'Wear Notes (Optional)',
              style: TextStyle(color: WardrobeTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 2,
              style: const TextStyle(color: WardrobeTheme.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'e.g. Worn to conference, received compliments',
                hintStyle: const TextStyle(color: WardrobeTheme.textMuted, fontSize: 13),
                filled: true,
                fillColor: WardrobeTheme.spatialSurface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: WardrobeTheme.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: WardrobeTheme.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: WardrobeTheme.borderCyan)),
              ),
            ),

            const SizedBox(height: 28),

            // Confirm Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: widget.controller.isLoading ? null : _confirmWear,
                icon: const Icon(Icons.check_rounded, size: 18),
                label: widget.controller.isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Confirm Actual Wear', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: WardrobeTheme.electricCyan,
                  foregroundColor: WardrobeTheme.deepVoidBg,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
