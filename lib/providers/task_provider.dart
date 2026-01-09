import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../services/data_service.dart';
import 'app_session_provider.dart';

/// Task state with optimistic updates
class TaskState {
  final List<Task> tasks;
  final bool isLoading;
  final String? error;
  final DateTime lastFetched;

  TaskState({
    this.tasks = const [],
    this.isLoading = false,
    this.error,
    DateTime? lastFetched,
  }) : lastFetched = lastFetched ?? DateTime.fromMillisecondsSinceEpoch(0);

  TaskState copyWith({
    List<Task>? tasks,
    bool? isLoading,
    String? error,
    DateTime? lastFetched,
  }) {
    return TaskState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastFetched: lastFetched ?? this.lastFetched,
    );
  }

  List<Task> get pendingTasks => tasks.where((t) => t.status == TaskStatus.pending).toList();
  List<Task> get completedTasks => tasks.where((t) => t.status == TaskStatus.completed).toList();
  List<Task> get personalTasks => tasks.where((t) => t.taskType == TaskType.personal).toList();
  List<Task> get courseTasks => tasks.where((t) => t.taskType != TaskType.personal).toList();
}

/// Main task state provider with caching and optimistic updates
final taskStateProvider = StateNotifierProvider<TaskStateNotifier, TaskState>((ref) {
  // Watch user to auto-refresh tasks on user switch
  final userAsync = ref.watch(currentUserProvider);
  return TaskStateNotifier(ref, userAsync.valueOrNull?.id);
});

class TaskStateNotifier extends StateNotifier<TaskState> {
  // ignore: unused_field - may be used for future features
  static const _cacheTimeout = Duration(minutes: 5);
  final String? userId;

  TaskStateNotifier(Ref ref, this.userId) : super(TaskState()) {
    // Initial fetch only if user is logged in
    if (userId != null) {
      fetchTasks();
    }
  }

  bool get _shouldRefresh {
    return DateTime.now().difference(state.lastFetched) > _cacheTimeout;
  }

  /// Fetch tasks from API (with caching)
  Future<void> fetchTasks({bool force = false}) async {
    if (!force && !_shouldRefresh && state.tasks.isNotEmpty) {
      return; // Use cache
    }

    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final tasks = await DataService.getTasks();
      state = state.copyWith(
        tasks: tasks,
        isLoading: false,
        lastFetched: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Toggle task completion with OPTIMISTIC UPDATE
  Future<void> toggleTaskStatus(String id) async {
    // Find the task
    final taskIndex = state.tasks.indexWhere((t) => t.id == id);
    if (taskIndex == -1) return;

    final oldTask = state.tasks[taskIndex];
    final newStatus = oldTask.status == TaskStatus.completed 
        ? TaskStatus.pending 
        : TaskStatus.completed;

    // OPTIMISTIC UPDATE - Update UI immediately
    final updatedTask = oldTask.copyWith(status: newStatus);
    final updatedTasks = List<Task>.from(state.tasks);
    updatedTasks[taskIndex] = updatedTask;
    state = state.copyWith(tasks: updatedTasks);

    // Sync with backend in background
    try {
      await DataService.toggleTaskComplete(id);
      // Success - no need to do anything, UI already updated
    } catch (e) {
      // ROLLBACK on failure
      final rollbackTasks = List<Task>.from(state.tasks);
      rollbackTasks[taskIndex] = oldTask;
      state = state.copyWith(tasks: rollbackTasks, error: 'Failed to update task');
    }
  }

  /// Add a new task with optimistic update
  Future<void> addTask(Task task) async {
    // Generate temporary ID for optimistic update
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempTask = Task(
      id: tempId,
      title: task.title,
      description: task.description,
      subject: task.subject,
      dueDate: task.dueDate,
      status: TaskStatus.pending,
      priority: task.priority,
      createdAt: DateTime.now(),
      taskType: task.taskType,
    );

    // OPTIMISTIC UPDATE
    state = state.copyWith(tasks: [tempTask, ...state.tasks]);

    try {
      final result = await DataService.createTask(
        title: task.title,
        description: task.description,
        priority: task.priority.name.toUpperCase(),
        dueDate: task.dueDate,
        type: task.taskType.name.toUpperCase(),
      );

      if (result != null) {
        // Replace temp task with real one
        final updatedTasks = state.tasks.map((t) {
          return t.id == tempId ? result : t;
        }).toList();
        state = state.copyWith(tasks: updatedTasks);
      } else {
        // Remove temp task on failure
        state = state.copyWith(
          tasks: state.tasks.where((t) => t.id != tempId).toList(),
          error: 'Failed to create task',
        );
      }
    } catch (e) {
      // Remove temp task on failure
      state = state.copyWith(
        tasks: state.tasks.where((t) => t.id != tempId).toList(),
        error: e.toString(),
      );
    }
  }

  /// Delete task with optimistic update
  Future<void> deleteTask(String id) async {
    final taskIndex = state.tasks.indexWhere((t) => t.id == id);
    if (taskIndex == -1) return;

    final deletedTask = state.tasks[taskIndex];

    // OPTIMISTIC UPDATE
    state = state.copyWith(
      tasks: state.tasks.where((t) => t.id != id).toList(),
    );

    try {
      await DataService.deleteTask(id);
    } catch (e) {
      // ROLLBACK
      final rollbackTasks = List<Task>.from(state.tasks);
      rollbackTasks.insert(taskIndex, deletedTask);
      state = state.copyWith(tasks: rollbackTasks, error: 'Failed to delete task');
    }
  }

  /// Update task with optimistic update
  Future<void> updateTask(Task task) async {
    final taskIndex = state.tasks.indexWhere((t) => t.id == task.id);
    if (taskIndex == -1) return;

    final oldTask = state.tasks[taskIndex];

    // OPTIMISTIC UPDATE
    final updatedTasks = List<Task>.from(state.tasks);
    updatedTasks[taskIndex] = task;
    state = state.copyWith(tasks: updatedTasks);

    try {
      final success = await DataService.updateTask(
        id: task.id,
        title: task.title,
        description: task.description,
        priority: task.priority.name.toUpperCase(),
        dueDate: task.dueDate,
      );

      if (!success) {
        throw Exception('Update failed');
      }
    } catch (e) {
      // ROLLBACK
      final rollbackTasks = List<Task>.from(state.tasks);
      rollbackTasks[taskIndex] = oldTask;
      state = state.copyWith(tasks: rollbackTasks, error: 'Failed to update task');
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Convenience providers for backward compatibility
final tasksProvider = Provider<List<Task>>((ref) {
  return ref.watch(taskStateProvider).tasks;
});

final pendingTasksProvider = Provider<List<Task>>((ref) {
  return ref.watch(taskStateProvider).pendingTasks;
});

final completedTasksProvider = Provider<List<Task>>((ref) {
  return ref.watch(taskStateProvider).completedTasks;
});

final taskLoadingProvider = Provider<bool>((ref) {
  return ref.watch(taskStateProvider).isLoading;
});

final taskErrorProvider = Provider<String?>((ref) {
  return ref.watch(taskStateProvider).error;
});

// Legacy controller for backward compatibility
final taskControllerProvider = Provider<TaskStateNotifier>((ref) {
  return ref.watch(taskStateProvider.notifier);
});

// Task filter provider for backward compatibility
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