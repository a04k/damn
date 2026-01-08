import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';

class AssignmentsScreen extends ConsumerStatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  ConsumerState<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends ConsumerState<AssignmentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignments'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/home'),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: tasksAsync.when(
        data: (tasks) {
          // Filter assignments (non-personal)
          // We treat anything NOT 'PERSONAL' as course work (Assignment, Lab, Exam)
          final assignments = tasks.where((t) => t.type != 'PERSONAL').toList();
          
          final pending = assignments.where((t) => t.status != TaskStatus.completed).toList();
          // Sort by due date
          pending.sort((a, b) => a.dueDate.compareTo(b.dueDate));
          
          final completed = assignments.where((t) => t.status == TaskStatus.completed).toList();
          completed.sort((a, b) => b.dueDate.compareTo(a.dueDate)); // Most recent first

          return TabBarView(
            controller: _tabController,
            children: [
              _buildTaskList(pending, isPending: true),
              _buildTaskList(completed, isPending: false),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading assignments: $e'),
              ElevatedButton(
                onPressed: () => ref.refresh(tasksProvider),
                child: const Text('Retry'),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskList(List<Task> tasks, {required bool isPending}) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              isPending ? 'No pending assignments' : 'No completed assignments', 
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getTypeColor(task.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getTypeIcon(task.type),
                  color: _getTypeColor(task.type),
                  size: 24,
                ),
              ),
              title: Text(
                task.title, 
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  decoration: !isPending ? TextDecoration.lineThrough : null,
                  color: !isPending ? Colors.grey : Colors.black,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.book, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(task.subject, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: _getDueDateColor(task.dueDate, task.status)),
                      const SizedBox(width: 4),
                      Text(
                        'Due: ${DateFormat('MMM d, h:mm a').format(task.dueDate)}', 
                        style: TextStyle(
                          color: _getDueDateColor(task.dueDate, task.status),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: isPending 
                ? Transform.scale(
                    scale: 1.2,
                    child: Checkbox(
                      value: false, 
                      onChanged: (val) {
                         // Optimistically update via controller
                        ref.read(taskControllerProvider.notifier).toggleTaskStatus(task.id);
                      },
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                  )
                : const Icon(Icons.check_circle, color: Colors.green),
            ),
          ),
        );
      },
    );
  }
  
  Color _getTypeColor(String type) {
    switch (type.toUpperCase()) {
      case 'EXAM': return Colors.red;
      case 'LAB': return Colors.blue;
      case 'ASSIGNMENT': return Colors.orange;
      default: return Colors.deepPurple;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toUpperCase()) {
      case 'EXAM': return Icons.quiz;
      case 'LAB': return Icons.science;
      case 'ASSIGNMENT': return Icons.assignment;
      default: return Icons.task;
    }
  }

  Color _getDueDateColor(DateTime due, TaskStatus status) {
    if (status == TaskStatus.completed) return Colors.grey;
    if (due.isBefore(DateTime.now())) return Colors.red;
    if (due.isBefore(DateTime.now().add(const Duration(days: 2)))) return Colors.orange[800]!;
    return Colors.grey[700]!;
  }
}
