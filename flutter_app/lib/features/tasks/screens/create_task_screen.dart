import 'package:flutter/material.dart';
import '../../../core/models/task_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/tess_button.dart';
import '../../../shared/widgets/tess_card.dart';

/// CreateTaskScreen demonstrates Module 7: Forms and Navigation in Flutter:
/// - Form widget with GlobalKey<FormState>
/// - Form validation logic (empty checks, length requirements)
/// - TextEditingController for managing text inputs
/// - FocusNode for managing input focus transitions
/// - Returning data back to the calling screen via Navigator.pop(context, result)
class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  // 1. Form Key to access FormState methods (validate(), save(), reset())
  final _formKey = GlobalKey<FormState>();

  // 2. Controllers for capturing text field values
  final _titleController = TextEditingController();
  final _categoryController = TextEditingController();

  // 3. FocusNodes for programmatic focus shifting
  final _titleFocusNode = FocusNode();
  final _categoryFocusNode = FocusNode();

  // Form field state
  TaskPriority _selectedPriority = TaskPriority.medium;

  @override
  void dispose() {
    // Crucial Flutter Engineering Rule: Always dispose controllers & FocusNodes!
    _titleController.dispose();
    _categoryController.dispose();
    _titleFocusNode.dispose();
    _categoryFocusNode.dispose();
    super.dispose();
  }

  void _submitForm() {
    // Validate all form fields using the GlobalKey
    if (_formKey.currentState?.validate() ?? false) {
      // Create new Task instance using the named constructor
      final newTask = Task.create(
        title: _titleController.text.trim(),
        category: _categoryController.text.trim().toUpperCase(),
        priority: _selectedPriority,
      );

      // Return the newly constructed Task to the parent screen and pop the route
      Navigator.pop(context, newTask);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'DISPATCH NEW OBJECTIVE',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Intro Instruction Card
              TessCard(
                borderColor: AppColors.violet.withValues(alpha: 0.3),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.cyan, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'New objectives are integrated into TESS Future Engine to calculate timeline trajectories.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Title Field
              const Text(
                'OBJECTIVE TITLE',
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                focusNode: _titleFocusNode,
                textInputAction: TextInputAction.next,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'e.g. Implement Neural Cache Layer',
                  hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  filled: true,
                  fillColor: AppColors.bgSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: const BorderSide(color: AppColors.violet),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an objective title';
                  }
                  if (value.trim().length < 5) {
                    return 'Title must be at least 5 characters long';
                  }
                  return null;
                },
                onFieldSubmitted: (_) {
                  // Shift focus to the next field when the user presses Enter/Next
                  FocusScope.of(context).requestFocus(_categoryFocusNode);
                },
              ),
              const SizedBox(height: 16),

              // Category Field
              const Text(
                'SYSTEM CATEGORY',
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _categoryController,
                focusNode: _categoryFocusNode,
                textInputAction: TextInputAction.done,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'e.g. CORE // ARCHITECTURE',
                  hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  filled: true,
                  fillColor: AppColors.bgSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: const BorderSide(color: AppColors.violet),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please assign a system category';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _submitForm(),
              ),
              const SizedBox(height: 16),

              // Priority Selector using Segmented Choice Chips
              const Text(
                'PRIORITY VECTOR',
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: TaskPriority.values.map((priority) {
                  final isSelected = _selectedPriority == priority;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedPriority = priority;
                          });
                        },
                        borderRadius: BorderRadius.circular(8.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.violet.withValues(alpha: 0.25)
                                : AppColors.bgSurface,
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(
                              color: isSelected ? AppColors.violet : AppColors.border,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '${priority.code} • ${priority.name.toUpperCase()}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                                color: isSelected
                                    ? AppColors.textPrimary
                                    : AppColors.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // Submission Button
              TessButton(
                label: 'Commit Objective to Timeline',
                icon: Icons.check_circle_outline,
                onPressed: _submitForm,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

