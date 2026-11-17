import '../models/prediction_model.dart';
import '../models/task_model.dart';

/// Simulated Cognitive Engine Service for TESS.
/// Demonstrates:
/// - Asynchronous programming: Future<T>, async, await
/// - Error handling: try, catch, rethrow, custom exceptions
/// - Collection operations: where, map, reduce, fold
/// - Realistic data pipelines without live backend dependencies (for Phase 14.2)
class SimulationService {
  // Toggle to simulate simulated network/engine failure for teaching error states
  static bool shouldSimulateError = false;

  /// Fetch future trajectory predictions asynchronously.
  /// Simulates neural model calculation latency with Future.delayed.
  Future<List<Prediction>> fetchPredictions() async {
    try {
      // Simulate 1.2 second neural engine processing latency
      await Future.delayed(const Duration(milliseconds: 1200));

      if (shouldSimulateError) {
        throw Exception('Neural Core Connection Timeout: Telemetry Stream Interrupted.');
      }

      // Return simulated predictions
      return [
        Prediction(
          id: 'pred_001',
          title: 'Optimal Deep Work Sprint',
          description:
              'Maintain 90-minute focused coding sprints with zero context switching. High probability of Phase 14 milestone completion.',
          probabilityPercentage: 88.0,
          projectedOutcome: '+4.5 hours reclaimed productivity',
          trajectory: TrajectoryType.optimal,
        ),
        Prediction(
          id: 'pred_002',
          title: 'Context Fragmentation Risk',
          description:
              'Attending unscheduled sync calls during peak afternoon focus will derail current flow state and delay code reviews.',
          probabilityPercentage: 42.0,
          projectedOutcome: 'Deadline push +24h',
          trajectory: TrajectoryType.risk,
          interventionNote: 'Action Recommended: Auto-reschedule calls outside deep work block.',
        ),
        Prediction(
          id: 'pred_003',
          title: 'Standard Nominal Trajectory',
          description:
              'Current velocity maintains steady baseline completion across all active milestones.',
          probabilityPercentage: 65.0,
          projectedOutcome: 'Milestones on schedule',
          trajectory: TrajectoryType.nominal,
        ),
      ];
    } catch (e) {
      // Log or transform exception
      rethrow;
    }
  }

  /// Fetch initial tasks list asynchronously
  Future<List<Task>> fetchInitialTasks() async {
    await Future.delayed(const Duration(milliseconds: 800));

    return [
      Task(
        id: 'task_001',
        title: 'Master Dart OOP & Null Safety Fundamentals',
        category: 'ENGINEERING // DART',
        priority: TaskPriority.high,
        isCompleted: true,
      ),
      Task(
        id: 'task_002',
        title: 'Implement Interactive Asynchronous FutureBuilder',
        category: 'ENGINEERING // FLUTTER',
        priority: TaskPriority.high,
        isCompleted: false,
      ),
      Task(
        id: 'task_003',
        title: 'Construct Validated Task Creation Form with FocusNodes',
        category: 'UI // FORMS',
        priority: TaskPriority.medium,
        isCompleted: false,
      ),
      Task(
        id: 'task_004',
        title: 'Verify Responsive Layout Adaptability across Screen Sizes',
        category: 'TESTING // RESPONSIVE',
        priority: TaskPriority.low,
        isCompleted: false,
      ),
    ];
  }

  /// Demonstrating Collection Operations:
  /// - `where`: Filters tasks by completion status or priority
  /// - `map`: Transforms tasks into display titles
  /// - `fold`: Computes aggregate metrics (e.g. high-priority task count)
  static int countHighPriorityTasks(List<Task> tasks) {
    return tasks
        .where((task) => task.priority == TaskPriority.high)
        .length;
  }

  static double calculateCompletionRate(List<Task> tasks) {
    if (tasks.isEmpty) return 0.0;
    final completedCount = tasks.where((t) => t.isCompleted).length;
    return completedCount / tasks.length;
  }
}

