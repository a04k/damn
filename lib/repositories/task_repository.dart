import '../models/task.dart';
import 'api_task_database.dart';

abstract class TaskRepository {
  Future<List<Task>> getTasks();
  Future<List<Task>> getPendingTasks();
  Future<List<Task>> getCompletedTasks();
  Future<Task?> getTaskById(String id);
  Future<void> addTask(Task task);
  Future<void> updateTask(Task task);
  Future<void> deleteTask(String id);
  Future<void> toggleTaskStatus(String id);
  Stream<List<Task>> watchTasks();
}

/// Task Repository that uses API for cross-platform compatibility
class MockTaskRepository implements TaskRepository {
  
  /// Convert ApiTask to models/Task
  Task _convertToModelTask(ApiTask apiTask) {
    TaskPriority taskPriority;
    switch (apiTask.priority.toLowerCase()) {
      case 'high':
        taskPriority = TaskPriority.high;
        break;
      case 'medium':
        taskPriority = TaskPriority.medium;
        break;
      default:
        taskPriority = TaskPriority.low;
    }
    
    return Task(
      id: apiTask.id,
      title: apiTask.title,
      subject: apiTask.course,
      dueDate: DateTime.now().add(const Duration(days: 7)),
      status: apiTask.completed ? TaskStatus.completed : TaskStatus.pending,
      priority: taskPriority,
      description: apiTask.description ?? '',
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<List<Task>> getTasks() async {
    final apiTasks = await ApiTaskDatabase.getAllTasks();
    return apiTasks.map((t) => _convertToModelTask(t)).toList();
  }

  @override
  Future<List<Task>> getPendingTasks() async {
    final apiTasks = await ApiTaskDatabase.getAllTasks();
    return apiTasks
        .where((t) => !t.completed)
        .map((t) => _convertToModelTask(t))
        .toList();
  }

  @override
  Future<List<Task>> getCompletedTasks() async {
    final apiTasks = await ApiTaskDatabase.getAllTasks();
    return apiTasks
        .where((t) => t.completed)
        .map((t) => _convertToModelTask(t))
        .toList();
  }

  @override
  Future<Task?> getTaskById(String id) async {
    final apiTasks = await ApiTaskDatabase.getAllTasks();
    try {
      final task = apiTasks.firstWhere((t) => t.id == id);
      return _convertToModelTask(task);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> addTask(Task task) async {
    await ApiTaskDatabase.addTask(
      title: task.title,
      course: task.subject,
      priority: task.priority.name,
      description: task.description,
    );
  }

  @override
  Future<void> updateTask(Task task) async {
    await ApiTaskDatabase.updateTask(task.id, {
      'title': task.title,
      'course': task.subject,
      'priority': task.priority.name,
      'completed': task.status == TaskStatus.completed,
      'description': task.description,
    });
  }

  @override
  Future<void> deleteTask(String id) async {
    await ApiTaskDatabase.deleteTask(id);
  }

  @override
  Future<void> toggleTaskStatus(String id) async {
    await ApiTaskDatabase.toggleComplete(id);
  }

  @override
  Stream<List<Task>> watchTasks() async* {
    yield await getTasks();
  }
}