import 'package:flutter/material.dart';
import '../../../core/models/task_model.dart';
import '../../../core/services/simulation_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../widgets/task_tile.dart';
import 'create_task_screen.dart';

enum TaskFilter { all, pending, completed, highPriority }

/// TasksScreen demonstrates:
/// - Collections: Lists, filtering with where(), transformation with map()
/// - Navigation: Navigator.push to CreateTaskScreen and receiving returned data
/// - State Management with StatefulWidget and setState
/// - Responsive feedback via SnackBar
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final List<Task> _tasks = [
    Task(
      id: 'task_001',
      title: 'Initialize Phase 14 Flutter Application Shell',
      category: 'ENGINEERING // MOBILE',
      priority: TaskPriority.high,
      isCompleted: true,
    ),
    Task(
      id: 'task_002',
      title: 'Audit Linux build environment (Flutter, Dart, Java)',
      category: 'DEVOPS // ENV',
      priority: TaskPriority.high,
      isCompleted: true,
    ),
    Task(
      id: 'task_003',
      title: 'Synthesize FLUTTER_LEARNING_NOTES.md educational guide',
      category: 'DOCUMENTATION // EDUCATION',
      priority: TaskPriority.medium,
      isCompleted: false,
    ),
    Task(
      id: 'task_004',
      title: 'Verify cross-platform state sync with FastAPI backend',
      category: 'INTEGRATION // API',
      priority: TaskPriority.medium,
      isCompleted: false,
    ),
    Task(
      id: 'task_005',
      title: 'Draft Phase 14.1 implementation report',
      category: 'OPERATIONS // REPORT',
      priority: TaskPriority.low,
      isCompleted: false,
    ),
  ];

  TaskFilter _activeFilter = TaskFilter.all;

  void _toggleTask(Task task, bool? value) {
    setState(() {
      task.isCompleted = value ?? false;
    });
  }

  /// Navigate to CreateTaskScreen and await the returned Task object
  Future<void> _navigateToCreateTask() async {
    final Task? newTask = await Navigator.push<Task>(
      context,
      MaterialPageRoute(builder: (context) => const CreateTaskScreen()),
    );

    // If the user submitted a valid task, append it to our state list
    if (newTask != null && mounted) {
      setState(() {
        _tasks.insert(0, newTask);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Objective "${newTask.title}" added to active timeline.',
            style: const TextStyle(fontSize: 12.5),
          ),
          backgroundColor: AppColors.tessTeal,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Demonstrating Collection Operations in Dart:
  /// Filtering `_tasks` based on the currently active filter enum.
  List<Task> get _filteredTasks {
    switch (_activeFilter) {
      case TaskFilter.pending:
        return _tasks.where((t) => !t.isCompleted).toList();
      case TaskFilter.completed:
        return _tasks.where((t) => t.isCompleted).toList();
      case TaskFilter.highPriority:
        return _tasks.where((t) => t.priority == TaskPriority.high).toList();
      case TaskFilter.all:
        return _tasks;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    final completedCount = _tasks.where((t) => t.isCompleted).length;
    final progress = SimulationService.calculateCompletionRate(_tasks);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'AGENT TASK MATRIX',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_task_rounded, color: AppColors.tessTeal),
            tooltip: 'Add Objective',
            onPressed: _navigateToCreateTask,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress Header Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: AppRadius.card,
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Sprint Progress',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        '$completedCount of ${_tasks.length} Completed',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.tessTeal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: AppRadius.pill,
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSecondary,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.vibrantMint),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Collection Filter Chips Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All (${_tasks.length})', TaskFilter.all, isDark),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'Pending (${_tasks.where((t) => !t.isCompleted).length})',
                    TaskFilter.pending,
                    isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'Completed ($completedCount)',
                    TaskFilter.completed,
                    isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'High Priority (${_tasks.where((t) => t.priority == TaskPriority.high).length})',
                    TaskFilter.highPriority,
                    isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Section Header
            Row(
              children: [
                const Icon(Icons.check_circle_outline, color: AppColors.tessTeal, size: 18),
                const SizedBox(width: 6),
                Text(
                  'ACTIVE OBJECTIVES',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  'Showing ${_filteredTasks.length} items',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Render Task List with Keys
            if (_filteredTasks.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 32.0),
                child: Center(
                  child: Text(
                    'No objectives match this filter.',
                    style: TextStyle(color: textMuted, fontSize: 12.5),
                  ),
                ),
              )
            else
              ..._filteredTasks.map((task) {
                return TaskTile(
                  key: ValueKey(task.id),
                  title: task.title,
                  category: task.category,
                  priority: task.priority,
                  isCompleted: task.isCompleted,
                  onToggle: (val) => _toggleTask(task, val),
                );
              }),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateTask,
        backgroundColor: AppColors.tessTeal,
        foregroundColor: Colors.white,
        tooltip: 'Dispatch Objective',
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildFilterChip(String label, TaskFilter filter, bool isDark) {
    final isSelected = _activeFilter == filter;
    final chipBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _activeFilter = filter);
      },
      labelStyle: TextStyle(
        fontSize: 11.5,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected
            ? Colors.white
            : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
      ),
      selectedColor: AppColors.tessTeal,
      backgroundColor: chipBg,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.pill,
        side: BorderSide(
          color: isSelected ? AppColors.tessTeal : borderColor,
        ),
      ),
    );
  }
}
