import 'package:flutter/material.dart';
import '../controllers/insights_controller.dart';
import '../theme/wardrobe_theme.dart';

class StyleMemoryScreen extends StatefulWidget {
  final InsightsController controller;

  const StyleMemoryScreen({
    super.key,
    required this.controller,
  });

  @override
  State<StyleMemoryScreen> createState() => _StyleMemoryScreenState();
}

class _StyleMemoryScreenState extends State<StyleMemoryScreen> {
  final _personaController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final mem = widget.controller.styleMemory;
    if (mem != null) {
      _personaController.text = mem.stylePersona;
      _notesController.text = mem.notes ?? '';
    }
  }

  @override
  void dispose() {
    _personaController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _savePreferences() async {
    setState(() => _isSaving = true);
    final success = await widget.controller.updateStyleMemory(
      stylePersona: _personaController.text.trim(),
      notes: _notesController.text.trim(),
    );
    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Style preferences updated!' : 'Failed to update preferences'),
          backgroundColor: WardrobeTheme.spatialSurface,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final mem = widget.controller.styleMemory;

        return Scaffold(
          backgroundColor: WardrobeTheme.voidBg,
          appBar: AppBar(
            backgroundColor: WardrobeTheme.deepVoidBg,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              color: WardrobeTheme.textPrimary,
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text(
              'Personal Style Memory',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: WardrobeTheme.textPrimary,
              ),
            ),
          ),
          body: mem == null
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(WardrobeTheme.statusSuccess),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Persona Card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: WardrobeTheme.spatialSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: WardrobeTheme.statusSuccess.withOpacity(0.3)),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            WardrobeTheme.spatialSurface,
                            WardrobeTheme.statusSuccess.withOpacity(0.06),
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: WardrobeTheme.statusSuccess.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.psychology_rounded,
                                  color: WardrobeTheme.statusSuccess,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Style Persona',
                                      style: TextStyle(fontSize: 11, color: WardrobeTheme.textMuted),
                                    ),
                                    Text(
                                      mem.stylePersona,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: WardrobeTheme.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            mem.interactionSummary,
                            style: const TextStyle(
                              fontSize: 13,
                              color: WardrobeTheme.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Top Empirical Colors & Categories
                    _buildSectionHeader('EMPIRICAL WEAR TASTE'),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: WardrobeTheme.spatialSurface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: WardrobeTheme.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Most Worn Colors',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: WardrobeTheme.textSecondary),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: mem.topWornColors.map((c) {
                              return Chip(
                                label: Text(c, style: const TextStyle(fontSize: 11, color: WardrobeTheme.textPrimary)),
                                backgroundColor: WardrobeTheme.elevatedSurface,
                                side: const BorderSide(color: WardrobeTheme.border),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Most Worn Categories',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: WardrobeTheme.textSecondary),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: mem.topWornCategories.map((c) {
                              return Chip(
                                label: Text(c, style: const TextStyle(fontSize: 11, color: WardrobeTheme.textPrimary)),
                                backgroundColor: WardrobeTheme.elevatedSurface,
                                side: const BorderSide(color: WardrobeTheme.border),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Persona & Notes Edit
                    _buildSectionHeader('CUSTOMIZE STYLE MEMORY'),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: WardrobeTheme.spatialSurface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: WardrobeTheme.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Persona Name',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: WardrobeTheme.textSecondary),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _personaController,
                            style: const TextStyle(color: WardrobeTheme.textPrimary, fontSize: 14),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: WardrobeTheme.elevatedSurface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: WardrobeTheme.border),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Style Notes & Rules',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: WardrobeTheme.textSecondary),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _notesController,
                            maxLines: 3,
                            style: const TextStyle(color: WardrobeTheme.textPrimary, fontSize: 14),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: WardrobeTheme.elevatedSurface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: WardrobeTheme.border),
                              ),
                              hintText: 'e.g. Always pair monochrome neutrals, avoid pastels',
                              hintStyle: const TextStyle(color: WardrobeTheme.textMuted, fontSize: 13),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _savePreferences,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: WardrobeTheme.statusSuccess,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text(
                                      'Save Preferences',
                                      style: TextStyle(fontWeight: FontWeight.w800),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: WardrobeTheme.textSecondary,
      ),
    );
  }
}

