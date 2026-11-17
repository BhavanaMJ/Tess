import 'package:flutter/material.dart';
import '../../../core/models/task_model.dart';
import '../../../core/services/simulation_service.dart';
import '../../../core/theme/app_colors.dart';
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
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
          backgroundColor: AppColors.bgSurface,
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
    final completedCount = _tasks.where((t) => t.isCompleted).length;
    final progress = SimulationService.calculateCompletionRate(_tasks);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AGENT TASK MATRIX',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_task_rounded, color: AppColors.cyan),
            tooltip: 'Dispatch Objective',
            onPressed: _navigateToCreateTask,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress Header Card
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(14.0),
                border: Border.all(color: AppColors.violet.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Sprint Progress',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '$completedCount of ${_tasks.length} Completed',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.cyan,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6.0),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppColors.bgVoid,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.violet),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Collection Filter Chips Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All (${_tasks.length})', TaskFilter.all),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'Pending (${_tasks.where((t) => !t.isCompleted).length})',
                    TaskFilter.pending,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'Completed ($completedCount)',
                    TaskFilter.completed,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'High Priority (${_tasks.where((t) => t.priority == TaskPriority.high).length})',
                    TaskFilter.highPriority,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Section Header
            Row(
              children: [
                const Icon(Icons.check_circle_outline, color: AppColors.violetLight, size: 18),
                const SizedBox(width: 6),
                const Text(
                  'ACTIVE OBJECTIVES',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: AppColors.textPrimary,
                    fontFamily: 'monospace',
                  ),
                ),
                const Spacer(),
                Text(
                  'Showing ${_filteredTasks.length} items',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textMuted,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Render Task List with Keys
            if (_filteredTasks.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 32.0),
                child: const Center(
                  child: Text(
                    'No objectives match this filter.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ),
              )
            else
              ..._filteredTasks.map((task) {
                return TaskTile(
                  key: ValueKey(task.id), // Key helps Flutter track identity across list updates
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
        backgroundColor: AppColors.violet,
        foregroundColor: Colors.white,
        tooltip: 'New Objective',
        onPressed: _navigateToCreateTask,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterChip(String label, TaskFilter filter) {
    final isSelected = _activeFilter == filter;
    return InkWell(
      onTap: () {
        setState(() {
          _activeFilter = filter;
        });
      },
      borderRadius: BorderRadius.circular(16.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.violet.withValues(alpha: 0.25)
              : AppColors.bgSurface,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: isSelected ? AppColors.violet : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontFamily: 'monospace',
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppColors.textPrimary : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
