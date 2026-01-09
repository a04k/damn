import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/app_session_provider.dart';
import '../providers/task_provider.dart';
import '../providers/course_provider.dart';
import '../providers/schedule_provider.dart';
import '../models/user.dart';

import '../widgets/loading_shimmer.dart';

/// Student Home Screen - Clean, functional design
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final coursesAsync = ref.watch(enrolledCoursesProvider);
    final taskState = ref.watch(taskStateProvider);
    final scheduleAsync = ref.watch(scheduleEventsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(currentUserProvider);
          ref.read(taskStateProvider.notifier).fetchTasks(force: true);
          await Future.wait([
            ref.refresh(enrolledCoursesProvider.future),
            ref.refresh(scheduleEventsProvider.future),
          ]);
        },
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: _buildHeader(context, userAsync.valueOrNull),
            ),

            // Quick Stats
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.menu_book,
                        label: 'Courses',
                        value: coursesAsync.when(
                          data: (c) => c.length.toString(),
                          loading: () => '-',
                          error: (_, __) => '!',
                        ),
                        color: const Color(0xFF3B82F6),
                        onTap: () => context.go('/my-courses'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.assignment_outlined,
                        label: 'Tasks',
                        value: taskState.pendingTasks.length.toString(),
                        color: const Color(0xFFF59E0B),
                        onTap: () => context.go('/tasks'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.event,
                        label: 'Today',
                        value: scheduleAsync.when(
                          data: (e) {
                            final today = DateTime.now();
                            return e.where((ev) => 
                              ev.startTime.day == today.day &&
                              ev.startTime.month == today.month
                            ).length.toString();
                          },
                          loading: () => '-',
                          error: (_, __) => '!',
                        ),
                        color: const Color(0xFF10B981),
                        onTap: () => context.go('/schedule'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Next Class Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Next Class',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 12),
                    scheduleAsync.when(
                      data: (events) {
                        final now = DateTime.now();
                        // Only show actual course lectures (not exams, not tasks)
                        final upcoming = events.where((e) =>
                          e.startTime.isAfter(now) &&
                          e.type == 'lecture' &&
                          e.courseId != null &&
                          e.courseId!.isNotEmpty
                        ).toList()
                          ..sort((a, b) => a.startTime.compareTo(b.startTime));

                        if (upcoming.isEmpty) {
                          return _buildEmptyCard('No upcoming classes today');
                        }

                        final next = upcoming.first;
                        return _NextClassCard(
                          title: next.title,
                          time: DateFormat('h:mm a').format(next.startTime),
                          location: next.location ?? 'TBD',
                          onTap: () => context.go('/schedule'),
                        );
                      },
                      loading: () => const LoadingShimmer(height: 80),
                      error: (_, __) => _buildEmptyCard('Failed to load schedule'),
                    ),
                  ],
                ),
              ),
            ),

            // My Courses Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'My Courses',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/my-courses'),
                      child: const Text('See All'),
                    ),
                  ],
                ),
              ),
            ),

            // Course Cards
            SliverToBoxAdapter(
              child: SizedBox(
                height: 140,
                child: coursesAsync.when(
                  data: (courses) {
                    if (courses.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'No courses enrolled',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: courses.length,
                      itemBuilder: (context, index) {
                        final course = courses[index];
                        return _CourseChip(
                          code: course.code,
                          name: course.name,
                          onTap: () => context.go('/course/${course.id}'),
                        );
                      },
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: LoadingShimmer(height: 120),
                  ),
                  error: (_, __) => const SizedBox(),
                ),
              ),
            ),

            // Pending Tasks Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Pending Tasks',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.go('/tasks'),
                          child: const Text('See All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Builder(
                      builder: (context) {
                        final tasks = taskState.pendingTasks;
                        if (tasks.isEmpty) {
                          return _buildEmptyCard('No pending tasks');
                        }

                        return Column(
                          children: tasks.take(3).map((task) => _TaskItem(
                            title: task.title,
                            dueDate: task.dueDate,
                            type: task.taskType.name,
                            onTap: () => context.go('/tasks'),
                          )).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, User? user) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      decoration: const BoxDecoration(
        color: Color(0xFF002147),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back,',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user?.name ?? 'Student',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Row(
            children: [
              _HeaderButton(
                icon: Icons.notifications_outlined,
                onTap: () => context.go('/notifications'),
              ),
              const SizedBox(width: 12),
              _HeaderButton(
                icon: Icons.person_outline,
                onTap: () => context.go('/profile'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Color(0xFF9CA3AF)),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NextClassCard extends StatelessWidget {
  final String title;
  final String time;
  final String location;
  final VoidCallback onTap;

  const _NextClassCard({
    required this.title,
    required this.time,
    required this.location,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.schedule, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$time • $location',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF10B981)),
          ],
        ),
      ),
    );
  }
}

class _CourseChip extends StatelessWidget {
  final String code;
  final String name;
  final VoidCallback onTap;

  const _CourseChip({
    required this.code,
    required this.name,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                code,
                style: const TextStyle(
                  color: Color(0xFF3B82F6),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1F2937),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskItem extends StatelessWidget {
  final String title;
  final DateTime? dueDate;
  final String type;
  final VoidCallback onTap;

  const _TaskItem({
    required this.title,
    this.dueDate,
    required this.type,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isOverdue = dueDate != null && dueDate!.isBefore(DateTime.now());

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isOverdue ? const Color(0xFFFECACA) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: isOverdue ? const Color(0xFFEF4444) : const Color(0xFFFBBF24),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  if (dueDate != null)
                    Text(
                      'Due: ${DateFormat('MMM d').format(dueDate!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isOverdue ? const Color(0xFFEF4444) : const Color(0xFF6B7280),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                type.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
