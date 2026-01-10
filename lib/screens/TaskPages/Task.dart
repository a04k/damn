import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'AddTask.dart';
import 'Taskdetails.dart';
import '../assignment_detail_screen.dart';
import '../exam_runner_screen.dart';
import '../../providers/task_provider.dart';
import '../../providers/app_mode_provider.dart';
import '../../models/task.dart';
import '../../models/user.dart';

class TasksPage extends ConsumerWidget {
  const TasksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check if professor mode
    final appMode = ref.watch(appModeControllerProvider);
    final isProfessor = appMode == AppMode.professor;
    final pageTitle = isProfessor ? 'Notes' : 'Tasks';
    
    // Use direct provider (not async) for instant updates
    final taskState = ref.watch(taskStateProvider);
    final tasks = List<Task>.from(taskState.tasks);
    // Sort by nearest deadline (tasks with due dates first)
    tasks.sort((a, b) {
      if (a.dueDate == null && b.dueDate == null) return 0;
      if (a.dueDate == null) return 1;
      if (b.dueDate == null) return -1;
      return a.dueDate!.compareTo(b.dueDate!);
    });
    final isLoading = taskState.isLoading;
    final error = taskState.error;

    // Separate personal and course tasks
    final personalTasks = tasks.where((t) => t.taskType == TaskType.personal).toList();
    final courseTasks = tasks.where((t) => t.taskType != TaskType.personal).toList();
    
    // Separate pending and completed
    final pendingPersonal = personalTasks.where((t) => t.status == TaskStatus.pending).toList();
    final completedPersonal = personalTasks.where((t) => t.status == TaskStatus.completed || t.status == TaskStatus.submitted || t.status == TaskStatus.graded).toList();
    final pendingCourse = courseTasks.where((t) => t.status == TaskStatus.pending).toList();
    final completedCourse = courseTasks.where((t) => t.status == TaskStatus.completed || t.status == TaskStatus.submitted || t.status == TaskStatus.graded).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(pageTitle),
        backgroundColor: const Color(0xFF002147),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
        actions: [
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(taskStateProvider.notifier).fetchTasks(force: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Error Banner
              if (error != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          error,
                          style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => ref.read(taskStateProvider.notifier).clearError(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),

              // Stats Cards
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Pending Tasks',
                      value: (pendingPersonal.length + pendingCourse.length).toString(),
                      color: const Color(0xFF3B82F6),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Completed',
                      value: (completedPersonal.length + completedCourse.length).toString(),
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Add New Task/Note Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => _addTask(context, ref),
                  icon: const Icon(Icons.add),
                  label: Text(isProfessor ? 'Add New Note' : 'Add New Task', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF002147),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Pending Section
              Text(
                isProfessor ? 'Pending Notes' : 'Pending Tasks',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
              ),
              const SizedBox(height: 12),
              
              if (pendingPersonal.isEmpty && pendingCourse.isEmpty)
                _buildEmptyState(isProfessor ? 'No pending notes' : 'No pending tasks')
              else ...[
                ...pendingCourse.map((task) => _TaskCard(
                  key: ValueKey(task.id),
                  task: task,
                  isPersonal: false,
                  onToggle: () => ref.read(taskStateProvider.notifier).toggleTaskStatus(task.id),
                  onDelete: null,
                  onEdit: null,
                )),
                ...pendingPersonal.map((task) => _TaskCard(
                  key: ValueKey(task.id),
                  task: task,
                  isPersonal: true,
                  onToggle: () => ref.read(taskStateProvider.notifier).toggleTaskStatus(task.id),
                  onDelete: () => ref.read(taskStateProvider.notifier).deleteTask(task.id),
                  onEdit: () => _editTask(context, ref, task),
                )),
              ],
              
              const SizedBox(height: 32),
              
              // Completed Section
              Text(
                isProfessor ? 'Completed Notes' : 'Completed Tasks',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
              ),
              const SizedBox(height: 12),
              
              if (completedPersonal.isEmpty && completedCourse.isEmpty)
                _buildEmptyState(isProfessor ? 'No completed notes' : 'No completed tasks')
              else ...[
                ...completedCourse.map((task) => _TaskCard(
                  key: ValueKey(task.id),
                  task: task,
                  isPersonal: false,
                  onToggle: () => ref.read(taskStateProvider.notifier).toggleTaskStatus(task.id),
                  onDelete: null,
                  onEdit: null,
                )),
                ...completedPersonal.map((task) => _TaskCard(
                  key: ValueKey(task.id),
                  task: task,
                  isPersonal: true,
                  onToggle: () => ref.read(taskStateProvider.notifier).toggleTaskStatus(task.id),
                  onDelete: () => ref.read(taskStateProvider.notifier).deleteTask(task.id),
                  onEdit: null,
                )),
              ],
              
              const SizedBox(height: 100), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
        ),
      ),
    );
  }

  Future<void> _addTask(BuildContext context, WidgetRef ref) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddTaskPage()),
    );

    if (result != null && result is Map) {
      final task = Task(
        id: '',
        title: result['title'] ?? '',
        description: result['description'],
        priority: _parsePriority(result['priority']),
        dueDate: result['dueDate'] as DateTime?,
        status: TaskStatus.pending,
        createdAt: DateTime.now(),
        subject: 'Personal',
        taskType: TaskType.personal,
      );
      
      ref.read(taskStateProvider.notifier).addTask(task);
    }
  }

  Future<void> _editTask(BuildContext context, WidgetRef ref, Task task) async {
    final updatedTask = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TaskDetailsPage(task: task)),
    );

    if (updatedTask != null && updatedTask is Task) {
      ref.read(taskStateProvider.notifier).updateTask(updatedTask);
    }
  }

  TaskPriority _parsePriority(String? p) {
    switch (p?.toLowerCase()) {
      case 'high': return TaskPriority.high;
      case 'low': return TaskPriority.low;
      default: return TaskPriority.medium;
    }
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends ConsumerWidget {
  final Task task;
  final bool isPersonal;
  final VoidCallback onToggle;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const _TaskCard({
    super.key,
    required this.task,
    required this.isPersonal,
    required this.onToggle,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCompleted = task.status == TaskStatus.completed || task.status == TaskStatus.submitted || task.status == TaskStatus.graded;
    final typeColor = _getTypeColor(task.taskType);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Transform.scale(
          scale: 1.2,
          child: Checkbox(
            value: isCompleted,
            onChanged: (val) {
              // Prevent unchecking submitted/completed assignments or exams
              if (val == false && 
                  (task.taskType == TaskType.assignment || task.taskType == TaskType.exam) && 
                  (task.status == TaskStatus.submitted || task.status == TaskStatus.graded || task.status == TaskStatus.completed)) {
                 ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Marking cannot be removed from submitted tasks.')),
                 );
                 return;
              }

              if (val == true && 
                  task.taskType == TaskType.assignment && 
                  task.status != TaskStatus.submitted && 
                  task.status != TaskStatus.completed) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please submit your assignment to mark it as complete.'),
                    backgroundColor: Colors.orange,
                  ),
                );
                // Navigate to assignment details
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AssignmentDetailScreen(task: task)),
                );
                return;
              }
              onToggle();
            },
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            activeColor: const Color(0xFF10B981),
          ),
        ),
        onTap: () {
          if (task.taskType == TaskType.assignment) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AssignmentDetailScreen(task: task)),
            ).then((_) => ref.read(taskStateProvider.notifier).fetchTasks(force: true));
          } else if (task.taskType == TaskType.exam) {
            if (task.status == TaskStatus.submitted || task.status == TaskStatus.graded || task.status == TaskStatus.completed) {
               ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('You have already submitted this exam.')),
               );
            } else {
               Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(builder: (context) => ExamRunnerScreen(
                  taskId: task.id, 
                  courseId: task.courseId ?? '', 
                )),
              ).then((_) {
                 ref.read(taskStateProvider.notifier).fetchTasks(force: true);
              });
            }
          } else {
            if (isPersonal && onEdit != null) {
              onEdit!();
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TaskDetailsPage(task: task)),
              ).then((_) => ref.read(taskStateProvider.notifier).fetchTasks(force: true));
            }
          }
        },
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: isCompleted ? TextDecoration.lineThrough : null,
            color: isCompleted ? Colors.grey : const Color(0xFF1F2937),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              task.subject,
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
            if (task.dueDate != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(task.priority).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      task.priority.name,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _getPriorityColor(task.priority),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: _getDueDateColor(task.dueDate!, task.status),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _getDueDateText(task.dueDate!),
                    style: TextStyle(
                      fontSize: 12,
                      color: _getDueDateColor(task.dueDate!, task.status),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
            if (task.status == TaskStatus.graded && task.submission != null)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Text(
                  'Grade: ${task.submission!['grade'] ?? task.submission!['points'] ?? 'Graded'}',
                  style: TextStyle(
                    color: Colors.green[800],
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        trailing: isPersonal && (onDelete != null || onEdit != null)
            ? PopupMenuButton(
                itemBuilder: (context) => [
                  if (onEdit != null)
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  if (onDelete != null)
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
                onSelected: (value) {
                  if (value == 'delete') onDelete?.call();
                  if (value == 'edit') onEdit?.call();
                },
              )
            : !isPersonal
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      task.taskType.name,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: typeColor,
                      ),
                    ),
                  )
                : null,
      ),
    );
  }

  Color _getTypeColor(TaskType type) {
    switch (type) {
      case TaskType.exam: return Colors.red;
      case TaskType.assignment: return Colors.orange;
      case TaskType.lab: return Colors.blue;
      default: return const Color(0xFF6B7280);
    }
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high: return Colors.red;
      case TaskPriority.medium: return Colors.orange;
      case TaskPriority.low: return Colors.green;
    }
  }

  Color _getDueDateColor(DateTime due, TaskStatus status) {
    if (status == TaskStatus.completed || status == TaskStatus.submitted) return Colors.grey;
    if (due.isBefore(DateTime.now())) return Colors.red;
    if (due.isBefore(DateTime.now().add(const Duration(days: 2)))) return Colors.orange[800]!;
    return const Color(0xFF6B7280);
  }

  String _getDueDateText(DateTime date) {
    final now = DateTime.now();
    if (date.isBefore(now)) return 'Overdue';
    
    final diff = date.difference(now);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Tomorrow';
    if (diff.inDays < 7) return '${diff.inDays} days';
    
    return '${date.month}/${date.day}';
  }

  Future<void> _showUnsubmitDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsubmit Assignment?'),
        content: const Text('To unsubmit, please open the assignment details.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Go to Details'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AssignmentDetailScreen(task: task)),
      );
    }
  }
}
