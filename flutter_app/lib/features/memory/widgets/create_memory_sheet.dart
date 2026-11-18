import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';

/// Bottom sheet dialog allowing manual encoding of personal memory into TESS
class CreateMemorySheet extends StatefulWidget {
  final Future<void> Function({
    required String category,
    required String content,
    required int importance,
  }) onSave;

  const CreateMemorySheet({
    super.key,
    required this.onSave,
  });

  @override
  State<CreateMemorySheet> createState() => _CreateMemorySheetState();
}

class _CreateMemorySheetState extends State<CreateMemorySheet> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  String _selectedCategory = 'WORK';
  int _importance = 3;
  bool _isSaving = false;

  final List<String> _categories = [
    'WORK',
    'PERSONAL',
    'PREFERENCE',
    'HEALTH',
    'PROJECT',
  ];

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;

    setState(() => _isSaving = true);
    try {
      await widget.onSave(
        category: _selectedCategory,
        content: _contentController.text.trim(),
        importance: _importance,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to encode memory: $e'),
            backgroundColor: AppColors.accentDanger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sheetBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final inputBg = isDark ? AppColors.darkSurfaceElevated : AppColors.lightSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
        border: Border(
          top: BorderSide(color: AppColors.tessTeal.withOpacity(0.3), width: 1.5),
        ),
      ),
      padding: EdgeInsets.only(
        top: AppSpacing.md,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20.0,
      ),
      child: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36.0,
                    height: 4.0,
                    decoration: BoxDecoration(
                      color: borderColor,
                      borderRadius: AppRadius.pill,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Remember a Note or Preference',
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  'Store a fact, preference, or operating directive into TESS persistent context continuity.',
                  style: TextStyle(color: textSecondary, fontSize: 13.0),
                ),
                const SizedBox(height: AppSpacing.md),
                // Category Selector
                Text(
                  'CATEGORY',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: textMuted,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8.0),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: _categories.map((category) {
                    final isSelected = _selectedCategory == category;
                    return ChoiceChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedCategory = category);
                        }
                      },
                      labelStyle: TextStyle(
                        fontSize: 11.0,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                      ),
                      selectedColor: AppColors.tessTeal,
                      backgroundColor: inputBg,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.pill,
                        side: BorderSide(
                          color: isSelected ? AppColors.tessTeal : borderColor,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.md),
                // Content Input
                Text(
                  'DIRECTIVE / FACT CONTENT',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: textMuted,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8.0),
                TextFormField(
                  controller: _contentController,
                  maxLines: 4,
                  minLines: 2,
                  style: TextStyle(color: textPrimary, fontSize: 14.0),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter memory content';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'e.g. Commander prioritizes focused deep work before 12:00...',
                    hintStyle: TextStyle(color: textMuted, fontSize: 13.0),
                    filled: true,
                    fillColor: inputBg,
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.card,
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: AppRadius.card,
                      borderSide: BorderSide(color: AppColors.tessTeal),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                // Importance Selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'IMPORTANCE RATING',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: textMuted,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      'Level $_importance / 5',
                      style: const TextStyle(
                        fontSize: 12.0,
                        color: AppColors.accentWarning,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _importance.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  activeColor: AppColors.accentWarning,
                  inactiveColor: borderColor,
                  onChanged: (val) {
                    setState(() => _importance = val.round());
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                // Submit Button
                ElevatedButton(
                  onPressed: _isSaving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.tessTeal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14.0),
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.pill,
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20.0,
                          height: 20.0,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Save to Memory Bank',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.0,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
