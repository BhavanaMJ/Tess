import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

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
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
        border: Border(
          top: BorderSide(color: AppColors.cyan, width: 1.5),
        ),
      ),
      padding: EdgeInsets.only(
        top: 16.0,
        left: 20.0,
        right: 20.0,
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
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2.0),
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                const Text(
                  'ENCODE PERSONAL MEMORY',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: AppColors.cyan,
                  ),
                ),
                const SizedBox(height: 6.0),
                const Text(
                  'Store a fact, preference, or operating directive into TESS persistent context continuity.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                ),
                const SizedBox(height: 16.0),
                // Category Selector
                const Text(
                  'CATEGORY',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10.0,
                    color: AppColors.textMuted,
                    letterSpacing: 1.0,
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
                        fontFamily: 'monospace',
                        fontSize: 11.0,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                      selectedColor: AppColors.violet,
                      backgroundColor: AppColors.bgSurface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        side: BorderSide(
                          color: isSelected ? AppColors.violet : AppColors.border,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16.0),
                // Content Input
                const Text(
                  'DIRECTIVE / FACT CONTENT',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10.0,
                    color: AppColors.textMuted,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8.0),
                TextFormField(
                  controller: _contentController,
                  maxLines: 4,
                  minLines: 2,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14.0),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter memory content';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'e.g. Commander prioritizes focused deep work before 12:00...',
                    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13.0),
                    filled: true,
                    fillColor: AppColors.bgSurface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: const BorderSide(color: AppColors.cyan),
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                // Importance Selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'IMPORTANCE RATING',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10.0,
                        color: AppColors.textMuted,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Text(
                      'Level $_importance / 5',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11.0,
                        color: AppColors.amber,
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
                  activeColor: AppColors.amber,
                  inactiveColor: AppColors.border,
                  onChanged: (val) {
                    setState(() => _importance = val.round());
                  },
                ),
                const SizedBox(height: 16.0),
                // Submit Button
                ElevatedButton(
                  onPressed: _isSaving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cyan,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20.0,
                          height: 20.0,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        )
                      : const Text(
                          'COMMIT TO MEMORY BANK',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
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
