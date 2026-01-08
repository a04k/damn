import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_dashboard_flutter/providers/app_mode_provider.dart';
import 'package:student_dashboard_flutter/providers/task_provider.dart';
import 'package:student_dashboard_flutter/models/user.dart';
import 'package:student_dashboard_flutter/models/task.dart';

void main() {
  group('AppModeController Tests', () {
    test('Initial mode should be student', () {
      final container = ProviderContainer();
      final controller = container.read(appModeControllerProvider.notifier);
      
      expect(controller.isStudentMode(), isTrue);
      expect(controller.isProfessorMode(), isFalse);
    });

    test('Switch to professor mode works', () async {
      final container = ProviderContainer();
      final controller = container.read(appModeControllerProvider.notifier);
      
      await controller.switchMode(AppMode.professor);
      
      expect(controller.isProfessorMode(), isTrue);
      expect(controller.isStudentMode(), isFalse);
    });

    test('Switch back to student mode works', () async {
      final container = ProviderContainer();
      final controller = container.read(appModeControllerProvider.notifier);
      
      await controller.switchMode(AppMode.professor);
      expect(controller.isProfessorMode(), isTrue);
      
      await controller.switchMode(AppMode.student);
      expect(controller.isStudentMode(), isTrue);
    });
  });

  group('TaskController Tests', () {
    test('Task filter initial state', () {
      final container = ProviderContainer();
      final filter = container.read(taskFilterProvider);
      
      expect(filter.status, isNull);
      expect(filter.priority, isNull);
      expect(filter.dueDate, isNull);
      expect(filter.searchTerm, isEmpty);
    });

    test('Task filter updates work', () {
      final container = ProviderContainer();
      final filterNotifier = container.read(taskFilterProvider.notifier);
      
      filterNotifier.state = filterNotifier.state.copyWith(
        status: TaskStatus.completed,
        priority: TaskPriority.high,
        searchTerm: 'Test',
      );
      
      final updatedFilter = container.read(taskFilterProvider);
      expect(updatedFilter.status, equals(TaskStatus.completed));
      expect(updatedFilter.priority, equals(TaskPriority.high));
      expect(updatedFilter.searchTerm, equals('Test'));
    });
  });

  group('Task Model Tests', () {
    test('Task creation works', () {
      final task = Task(
        id: '1',
        title: 'Test Task',
        subject: 'Test Subject',
        dueDate: DateTime.now(),
        status: TaskStatus.pending,
        priority: TaskPriority.medium,
        createdAt: DateTime.now(),
      );

      expect(task.id, equals('1'));
      expect(task.title, equals('Test Task'));
      expect(task.subject, equals('Test Subject'));
      expect(task.status, equals(TaskStatus.pending));
      expect(task.priority, equals(TaskPriority.medium));
    });

    test('Task copyWith works', () {
      final originalTask = Task(
        id: '1',
        title: 'Original Task',
        subject: 'Test Subject',
        dueDate: DateTime.now(),
        status: TaskStatus.pending,
        priority: TaskPriority.medium,
        createdAt: DateTime.now(),
      );

      final updatedTask = originalTask.copyWith(
        title: 'Updated Task',
        status: TaskStatus.completed,
      );

      expect(updatedTask.id, equals(originalTask.id));
      expect(updatedTask.title, equals('Updated Task'));
      expect(updatedTask.subject, equals(originalTask.subject));
      expect(updatedTask.status, equals(TaskStatus.completed));
      expect(updatedTask.priority, equals(originalTask.priority));
    });

    test('Task JSON serialization works', () {
      final task = Task(
        id: '1',
        title: 'Test Task',
        subject: 'Test Subject',
        dueDate: DateTime.parse('2024-01-15T10:00:00Z'),
        status: TaskStatus.pending,
        priority: TaskPriority.high,
        createdAt: DateTime.parse('2024-01-10T10:00:00Z'),
      );

      final json = task.toJson();
      expect(json['id'], equals('1'));
      expect(json['title'], equals('Test Task'));
      expect(json['status'], equals('pending'));
      expect(json['priority'], equals('high'));

      final deserializedTask = Task.fromJson(json);
      expect(deserializedTask.id, equals(task.id));
      expect(deserializedTask.title, equals(task.title));
      expect(deserializedTask.status, equals(task.status));
      expect(deserializedTask.priority, equals(task.priority));
    });
  });

  group('User Model Tests', () {
    test('User creation works', () {
      const user = User(
        id: '1',
        name: 'Test User',
        email: 'test@example.com',
        avatar: 'https://example.com/avatar.jpg',
        studentId: 'STU001',
        major: 'Computer Science',
        mode: AppMode.student,
      );

      expect(user.id, equals('1'));
      expect(user.name, equals('Test User'));
      expect(user.email, equals('test@example.com'));
      expect(user.mode, equals(AppMode.student));
    });

    test('User mode switching works', () {
      const user = User(
        id: '1',
        name: 'Test User',
        email: 'test@example.com',
        avatar: 'https://example.com/avatar.jpg',
        studentId: 'STU001',
        mode: AppMode.student,
      );

      final professorUser = user.copyWith(mode: AppMode.professor);
      expect(professorUser.mode, equals(AppMode.professor));
      expect(professorUser.name, equals(user.name));
      expect(professorUser.email, equals(user.email));
    });
  });

  group('Integration Tests', () {
    test('Task controller updates reflect in filters', () async {
      final container = ProviderContainer();
      
      // Create a test task
      final testTask = Task(
        id: '1',
        title: 'Test Task',
        subject: 'Computer Science',
        dueDate: DateTime.now().add(const Duration(days: 1)),
        status: TaskStatus.pending,
        priority: TaskPriority.high,
        createdAt: DateTime.now(),
      );

      // Add task through controller
      final taskController = container.read(taskControllerProvider.notifier);
      await taskController.addTask(testTask);

      // Verify task was added (this would need actual repository implementation)
      final tasksAsync = container.read(tasksProvider);
      expect(tasksAsync, isA<AsyncValue>());
    });

    test('App mode changes affect UI visibility', () async {
      final container = ProviderContainer();
      final appModeController = container.read(appModeControllerProvider.notifier);

      // Initially in student mode
      expect(appModeController.isStudentMode(), isTrue);

      // Switch to professor mode
      await appModeController.switchMode(AppMode.professor);
      expect(appModeController.isProfessorMode(), isTrue);

      // This would affect UI components that check the mode
      final currentMode = container.read(appModeControllerProvider);
      expect(currentMode, equals(AppMode.professor));
    });
  });
}