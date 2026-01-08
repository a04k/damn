import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'AddTask.dart';
import 'Taskdetails.dart';
import '../../providers/task_provider.dart';
import '../../models/task.dart';

class TasksPage extends ConsumerStatefulWidget {
  const TasksPage({super.key});

  @override
  ConsumerState<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends ConsumerState<TasksPage> {
  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(tasksProvider),
          ),
        ],
      ),
      body: tasksAsync.when(
        data: (tasks) {
          // Filter personal tasks
          final personalTasks = tasks.where((t) => t.type == 'PERSONAL').toList();
          
          if (personalTasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.task_alt, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('No personal tasks', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _addTask,
                    icon: const Icon(Icons.add),
                    label: const Text('Create Task'),
                  ),
                ],
              ),
            );
          }

          // Sort: Pending first, then completed. Then by due date.
          personalTasks.sort((a, b) {
            if (a.status != b.status) {
              return a.status == TaskStatus.pending ? -1 : 1;
            }
            return a.dueDate.compareTo(b.dueDate);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: personalTasks.length,
            itemBuilder: (context, index) {
              final task = personalTasks[index];
              return Dismissible(
                key: Key(task.id),
                background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 16), child: const Icon(Icons.delete, color: Colors.white)),
                direction: DismissDirection.endToStart,
                onDismissed: (_) {
                  ref.read(taskControllerProvider.notifier).deleteTask(task.id);
                },
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Checkbox(
                      value: task.status == TaskStatus.completed,
                      onChanged: (val) {
                        ref.read(taskControllerProvider.notifier).toggleTaskStatus(task.id);
                      },
                    ),
                    title: Text(
                      task.title,
                      style: TextStyle(
                        decoration: task.status == TaskStatus.completed ? TextDecoration.lineThrough : null,
                        color: task.status == TaskStatus.completed ? Colors.grey : Colors.black,
                      ),
                    ),
                    subtitle: task.description != null && task.description!.isNotEmpty 
                      ? Text(task.description!, maxLines: 1, overflow: TextOverflow.ellipsis) 
                      : null,
                    trailing: _buildPriorityBadge(task.priority),
                    onTap: () async {
                      final updatedTask = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TaskDetailsPage(task: task),
                        ),
                      );
                      
                      if (updatedTask != null && updatedTask is Task) {
                        ref.read(taskControllerProvider.notifier).updateTask(updatedTask);
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTask,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _addTask() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddTaskPage()),
    );

    if (result != null && result is Map) {
      // Map AddTask result to Task creation
      final task = Task(
         id: '', // Generated by backend
         title: result['title'] ?? '',
         description: result['description'],
         priority: _parsePriority(result['priority']),
         dueDate: DateTime.now().add(const Duration(days: 1)), // Default or from result?
         status: TaskStatus.pending,
         createdAt: DateTime.now(),
         subject: 'Personal',
         type: 'PERSONAL',
      );
      
      // We pass 'title' etc to controller.createTask which calls DataService
      // DataService.createTask args: title, description, priority, etc.
      
      // Need to extract dueDate if AddTask provides it.
      // Assuming AddTask returns a Map with typical fields.
      
      ref.read(taskControllerProvider.notifier).createTask(
        task // Pass task object? No, controller expects Task object in 'createTask' (line 85 of provider) which calls addTask(task) (line 28)
             // Wait, TaskController.addTask calls DataService.createTask with fields.
             // So I should pass a Task object.
      );
    }
  }
  
  TaskPriority _parsePriority(String? p) {
    switch (p?.toLowerCase()) {
      case 'high': return TaskPriority.high;
      case 'low': return TaskPriority.low;
      default: return TaskPriority.medium;
    }
  }

  Widget _buildPriorityBadge(TaskPriority p) {
    Color c;
    String text;
    switch (p) {
      case TaskPriority.high: c = Colors.red; text = 'HIGH'; break;
      case TaskPriority.low: c = Colors.green; text = 'LOW'; break;
      default: c = Colors.orange; text = 'MED'; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: c.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
