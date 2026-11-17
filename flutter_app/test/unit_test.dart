import 'package:flutter_test/flutter_test.dart';
import 'package:tess/core/models/prediction_model.dart';
import 'package:tess/core/models/task_model.dart';
import 'package:tess/core/models/user_profile_model.dart';
import 'package:tess/core/services/simulation_service.dart';

void main() {
  group('Module 1 & 2: Dart Fundamentals & OOP Models', () {
    test('Task model instantiates with named constructor and adheres to defaults', () {
      final task = Task.create(
        title: 'Learn Dart Extension Methods',
        category: 'ENGINEERING',
        priority: TaskPriority.high,
      );

      expect(task.title, 'Learn Dart Extension Methods');
      expect(task.category, 'ENGINEERING');
      expect(task.priority, TaskPriority.high);
      expect(task.priority.code, 'P1');
      expect(task.priority.label, 'High Priority');
      expect(task.isCompleted, false);

      // Test Encapsulation & Setter
      task.isCompleted = true;
      expect(task.isCompleted, true);

      task.toggleCompletion();
      expect(task.isCompleted, false);
    });

    test('Prediction model evaluates trajectories and string interpolation', () {
      final prediction = Prediction(
        id: 'pred_test',
        title: 'Deep Work Sprint',
        description: 'Focus blocks verified.',
        probabilityPercentage: 92.4,
        projectedOutcome: '+3 hours flow',
        trajectory: TrajectoryType.optimal,
      );

      expect(prediction.formattedProbability, '92% OPTIMAL');
      expect(prediction.trajectory.requiresIntervention, false);
    });

    test('UserProfile handles sound null safety with null-coalescing operators', () {
      final user = UserProfile(
        id: 'usr_001',
        fullName: 'Bhavanam J',
        email: 'commander@tess.ai',
      );

      // Callsign defaults to fallback when null
      expect(user.callsign, isNull);
      expect(user.effectiveCallsign, 'Commander Bhavanam J');
      expect(user.skillTags.contains('COMMANDER'), true);
    });
  });

  group('Module 3: Collection Operations', () {
    test('Filters, maps, and calculates metrics over task collections', () {
      final tasks = [
        Task(id: '1', title: 'Task 1', category: 'DEV', priority: TaskPriority.high, isCompleted: true),
        Task(id: '2', title: 'Task 2', category: 'DEV', priority: TaskPriority.low, isCompleted: false),
        Task(id: '3', title: 'Task 3', category: 'UI', priority: TaskPriority.high, isCompleted: false),
      ];

      expect(SimulationService.countHighPriorityTasks(tasks), 2);
      expect(SimulationService.calculateCompletionRate(tasks), closeTo(0.333, 0.01));

      // Test where & map
      final titles = tasks.where((t) => t.isCompleted).map((t) => t.title).toList();
      expect(titles, ['Task 1']);
    });
  });

  group('Module 4: Asynchronous Programming & Services', () {
    final service = SimulationService();

    test('fetchPredictions resolves future with data', () async {
      SimulationService.shouldSimulateError = false;
      final predictions = await service.fetchPredictions();

      expect(predictions.isNotEmpty, true);
      expect(predictions.length, 3);
      expect(predictions.first.trajectory, TrajectoryType.optimal);
    });

    test('fetchPredictions throws expected error when simulated error is active', () async {
      SimulationService.shouldSimulateError = true;
      try {
        await expectLater(
          service.fetchPredictions(),
          throwsA(isA<Exception>()),
        );
      } finally {
        SimulationService.shouldSimulateError = false;
      }
    });
  });
}
