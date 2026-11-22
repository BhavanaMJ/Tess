import 'package:flutter/material.dart';
import '../../domain/entities/calendar_intelligence.dart';
import '../../domain/entities/outfit.dart';
import '../../domain/entities/outfit_plan.dart';
import '../controllers/calendar_controller.dart';
import '../controllers/outfit_controller.dart';
import '../theme/wardrobe_theme.dart';
import '../widgets/repeated_outfit_warning.dart';

class OutfitPlanScreen extends StatefulWidget {
  final CalendarController controller;
  final OutfitPlan? existingPlan;
  final DateTime? initialDate;
  final OutfitController? outfitController;

  const OutfitPlanScreen({
    super.key,
    required this.controller,
    this.existingPlan,
    this.initialDate,
    this.outfitController,
  });

  @override
  State<OutfitPlanScreen> createState() => _OutfitPlanScreenState();
}

class _OutfitPlanScreenState extends State<OutfitPlanScreen> {
  late DateTime _selectedDate;
  String? _selectedOutfitId;
  String? _selectedOutfitName;
  late TextEditingController _occasionController;
  late TextEditingController _notesController;
  RepetitionCheck? _repetitionCheck;
  List<Outfit> _availableOutfits = [];

  final List<String> _occasions = const [
    'Work',
    'Casual',
    'Evening',
    'Formal',
    'Sports',
    'Party',
    'Travel',
    'Date Night',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.existingPlan != null
        ? DateTime.tryParse(widget.existingPlan!.plannedDate) ?? DateTime.now()
        : widget.initialDate ?? DateTime.now();

    _selectedOutfitId = widget.existingPlan?.outfitId;
    _selectedOutfitName = widget.existingPlan?.outfitName;
    _occasionController = TextEditingController(text: widget.existingPlan?.occasion ?? 'Work');
    _notesController = TextEditingController(text: widget.existingPlan?.notes ?? '');

    _loadAvailableOutfits();
    if (_selectedOutfitId != null) {
      _checkRepetition(_selectedOutfitId!);
    }
  }

  @override
  void dispose() {
    _occasionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _loadAvailableOutfits() {
    if (widget.outfitController != null) {
      _availableOutfits = widget.outfitController!.savedOutfits;
    }
  }

  Future<void> _checkRepetition(String outfitId) async {
    final rep = await widget.controller.checkRepetition(
      outfitId: outfitId,
      date: _selectedDate,
    );
    if (!mounted) return;
    setState(() {
      _repetitionCheck = rep.isRepeated ? rep : null;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: WardrobeTheme.electricViolet,
              surface: WardrobeTheme.spatialSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      if (_selectedOutfitId != null) {
        _checkRepetition(_selectedOutfitId!);
      }
    }
  }

  Future<void> _savePlan() async {
    final outfitId = _selectedOutfitId;
    if (outfitId == null || outfitId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an outfit to plan')),
      );
      return;
    }

    if (widget.existingPlan != null) {
      await widget.controller.updatePlan(
        planId: widget.existingPlan!.id,
        plannedDate: _selectedDate,
        occasion: _occasionController.text.trim(),
        notes: _notesController.text.trim(),
      );
    } else {
      await widget.controller.createPlan(
        outfitId: outfitId,
        plannedDate: _selectedDate,
        occasion: _occasionController.text.trim(),
        notes: _notesController.text.trim(),
      );
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WardrobeTheme.voidBg,
      appBar: AppBar(
        backgroundColor: WardrobeTheme.voidBg,
        elevation: 0,
        title: Text(
          widget.existingPlan != null ? 'Edit Outfit Plan' : 'Plan an Outfit',
          style: const TextStyle(color: WardrobeTheme.textPrimary, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Picker Card
            const Text(
              'Planned Date',
              style: TextStyle(color: WardrobeTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: WardrobeTheme.spatialSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: WardrobeTheme.borderViolet),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded, color: WardrobeTheme.softViolet, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                      style: const TextStyle(color: WardrobeTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_drop_down_rounded, color: WardrobeTheme.textMuted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Outfit Selection
            const Text(
              'Select Outfit',
              style: TextStyle(color: WardrobeTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),

            if (_availableOutfits.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: WardrobeTheme.spatialSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: WardrobeTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedOutfitName ?? 'Custom Outfit',
                      style: const TextStyle(color: WardrobeTheme.textPrimary, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Saved looks from Outfit Studio will appear here for 1-tap selection.',
                      style: TextStyle(color: WardrobeTheme.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: WardrobeTheme.spatialSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: WardrobeTheme.border),
                ),
                child: Column(
                  children: _availableOutfits.map((outfit) {
                    final isSelected = _selectedOutfitId == outfit.id;
                    return ListTile(
                      title: Text(
                        outfit.name,
                        style: TextStyle(
                          color: isSelected ? WardrobeTheme.softViolet : WardrobeTheme.textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        '${outfit.occasion} • ${outfit.items.length} garments',
                        style: const TextStyle(color: WardrobeTheme.textMuted, fontSize: 12),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle_rounded, color: WardrobeTheme.electricViolet)
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedOutfitId = outfit.id;
                          _selectedOutfitName = outfit.name;
                        });
                        _checkRepetition(outfit.id);
                      },
                    );
                  }).toList(),
                ),
              ),

            // Repetition Warning banner if detected
            if (_repetitionCheck != null) ...[
              const SizedBox(height: 16),
              RepeatedOutfitWarning(
                message: _repetitionCheck!.message ?? 'You wore this outfit recently.',
                onDismiss: () => setState(() => _repetitionCheck = null),
              ),
            ],

            const SizedBox(height: 20),

            // Occasion Chips
            const Text(
              'Occasion',
              style: TextStyle(color: WardrobeTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _occasions.map((occ) {
                final isSelected = _occasionController.text == occ;
                return ChoiceChip(
                  label: Text(occ),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _occasionController.text = occ);
                  },
                  selectedColor: WardrobeTheme.electricViolet,
                  backgroundColor: WardrobeTheme.spatialSurface,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : WardrobeTheme.textSecondary,
                    fontSize: 12,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // Notes field
            const Text(
              'Notes (Optional)',
              style: TextStyle(color: WardrobeTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              style: const TextStyle(color: WardrobeTheme.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'e.g. Morning team sync, umbrella needed if cloudy',
                hintStyle: const TextStyle(color: WardrobeTheme.textMuted, fontSize: 13),
                filled: true,
                fillColor: WardrobeTheme.spatialSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: WardrobeTheme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: WardrobeTheme.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: WardrobeTheme.borderViolet),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Strict Non-mutation notice
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: WardrobeTheme.railBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: WardrobeTheme.borderSubtle),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: WardrobeTheme.textMuted),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Saving a plan represents intent only. Laundry status and wear counts will only update when you explicitly confirm wear.',
                      style: TextStyle(color: WardrobeTheme.textMuted, fontSize: 11, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: widget.controller.isLoading ? null : _savePlan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: WardrobeTheme.electricViolet,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: widget.controller.isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(
                        widget.existingPlan != null ? 'Update Plan' : 'Save Outfit Plan',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
