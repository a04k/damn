import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/course_provider.dart';
import '../providers/app_session_provider.dart';
import '../providers/app_mode_provider.dart';
import '../models/course.dart';
import '../models/user.dart';

class CoursesListScreen extends ConsumerWidget {
  const CoursesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appMode = ref.watch(appModeControllerProvider);
    final isProfessor = appMode == AppMode.professor;
    
    // Use different providers based on user mode
    final coursesAsync = isProfessor 
        ? ref.watch(professorCoursesProvider)
        : ref.watch(enrolledCoursesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: Text(isProfessor ? 'My Teaching Courses' : 'My Courses'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        actions: [
          if (isProfessor)
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => context.go('/add-content'),
              tooltip: 'Add Content',
            ),
        ],
      ),
      body: coursesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: ${error.toString()}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (isProfessor) {
                    ref.refresh(professorCoursesProvider);
                  } else {
                    ref.refresh(enrolledCoursesProvider);
                  }
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (courses) {
          if (courses.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isProfessor ? Icons.school_outlined : Icons.class_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isProfessor
                          ? 'No courses assigned yet'
                          : 'No courses enrolled yet',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isProfessor
                          ? 'Contact admin to assign courses to your account'
                          : 'Enroll in courses to see them here',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              return _CourseCard(
                course: course,
                isProfessor: isProfessor,
                onTap: () => context.go('/course/${course.id}'),
                onAddContent: isProfessor ? () => context.go('/add-content') : null,
              );
            },
          );
        },
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final Course course;
  final bool isProfessor;
  final VoidCallback onTap;
  final VoidCallback? onAddContent;

  const _CourseCard({
    required this.course,
    required this.isProfessor,
    required this.onTap,
    this.onAddContent,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isProfessor 
                          ? const Color(0xFFF0FDF4)  // Green for professor
                          : const Color(0xFFEFF4FF), // Blue for student
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      course.code,
                      style: TextStyle(
                        color: isProfessor
                            ? const Color(0xFF16A34A)
                            : const Color(0xFF2E6AFF),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        '${course.creditHours} Credits',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                      if (isProfessor && onAddContent != null) ...[
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: onAddContent,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.add,
                              size: 16,
                              color: Color(0xFF6366F1),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                course.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              if (course.professors.isNotEmpty)
                Row(
                  children: [
                    Icon(
                      isProfessor ? Icons.group_outlined : Icons.person_outline,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isProfessor ? 'Instructor' : course.professors.join(', '),
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              if (course.schedule.isNotEmpty) ...[
                Divider(color: Colors.grey.shade200),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${course.schedule.first.day} ${course.schedule.first.time}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                    if (course.schedule.length > 1)
                      Text(
                        ' +${course.schedule.length - 1} more',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                  ],
                ),
              ],
              // Professor-specific: show enrolled students count hint
              if (isProfessor) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_outline, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        'View enrolled students',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
