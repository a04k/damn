import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../services/data_service.dart';

/// Tasks provider using the unified DataService
final tasksProvider = FutureProvider<List<Task>>((ref) async {
  return DataService.getTasks();
});

final pendingTasksProvider = FutureProvider<List<Task>>((ref) async {
  return DataService.getPendingTasks();
});

final completedTasksProvider = FutureProvider<List<Task>>((ref) async {
  final tasks = await DataService.getTasks();
  return tasks.where((t) => t.status == TaskStatus.completed).toList();
});

final taskControllerProvider = StateNotifierProvider<TaskController, AsyncValue<void>>((ref) {
  return TaskController(ref);
});

class TaskController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  TaskController(this._ref) : super(const AsyncValue.data(null));

  Future<void> addTask(Task task) async {
    state = const AsyncValue.loading();
    try {
      final result = await DataService.createTask(
        title: task.title,
        description: task.description,
        priority: task.priority.name.toUpperCase(),
        dueDate: task.dueDate,
        type: 'PERSONAL',
      );
      
      if (result == null) throw Exception('Failed to create task');
      // Refresh tasks
      _ref.invalidate(tasksProvider);
      _ref.invalidate(pendingTasksProvider);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> toggleTaskStatus(String id) async {
    state = const AsyncValue.loading();
    try {
      await DataService.toggleTaskComplete(id);
      // Refresh tasks
      _ref.invalidate(tasksProvider);
      _ref.invalidate(pendingTasksProvider);
      _ref.invalidate(completedTasksProvider);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteTask(String id) async {
    state = const AsyncValue.loading();
    try {
      await DataService.deleteTask(id);
      // Refresh tasks
      _ref.invalidate(tasksProvider);
      _ref.invalidate(pendingTasksProvider);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateTask(Task task) async {
    state = const AsyncValue.loading();
    try {
      final success = await DataService.updateTask(
        id: task.id,
        title: task.title,
        description: task.description,
        priority: task.priority.name.toUpperCase(),
        dueDate: task.dueDate,
      );
      
      if (!success) throw Exception('Failed to update task');
      
      _ref.invalidate(tasksProvider);
      _ref.invalidate(pendingTasksProvider);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> createTask(Task task) => addTask(task);
}

final taskFilterProvider = StateProvider<TaskFilter>((ref) {
  return TaskFilter();
});

class TaskFilter {
  final TaskStatus? status;
  final TaskPriority? priority;
  final DateTime? dueDate;
  final String searchTerm;

  TaskFilter({
    this.status,
    this.priority,
    this.dueDate,
    this.searchTerm = '',
  });

  TaskFilter copyWith({
    TaskStatus? status,
    TaskPriority? priority,
    DateTime? dueDate,
    String? searchTerm,
  }) {
    return TaskFilter(
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      searchTerm: searchTerm ?? this.searchTerm,
    );
  }
}