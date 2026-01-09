import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/course_provider.dart';
import '../providers/app_mode_provider.dart';
import '../models/course.dart';
import '../models/user.dart';

/// Simple, clean courses list screen for both students and professors
class CoursesListScreen extends ConsumerWidget {
  const CoursesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appMode = ref.watch(appModeControllerProvider);
    final isProfessor = appMode == AppMode.professor;
    
    final coursesAsync = isProfessor 
        ? ref.watch(professorCoursesProvider)
        : ref.watch(enrolledCoursesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(isProfessor ? 'My Courses' : 'Enrolled Courses'),
        backgroundColor: const Color(0xFF002147),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (isProfessor) {
            return ref.refresh(professorCoursesProvider.future);
          } else {
            return ref.refresh(enrolledCoursesProvider.future);
          }
        },
        child: coursesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildError(error.toString(), () {
            if (isProfessor) {
              ref.refresh(professorCoursesProvider);
            } else {
              ref.refresh(enrolledCoursesProvider);
            }
          }),
          data: (courses) {
            if (courses.isEmpty) {
              return _buildEmpty(isProfessor);
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: courses.length,
              itemBuilder: (context, index) {
                final course = courses[index];
                return _CourseCard(
                  course: course,
                  onTap: () => context.go('/course/${course.id}'),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmpty(bool isProfessor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 72,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 20),
            Text(
              isProfessor ? 'No courses assigned' : 'No courses enrolled',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isProfessor
                  ? 'Contact admin to assign courses.'
                  : 'Select courses during onboarding.',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String message, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF002147),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback onTap;

  const _CourseCard({
    required this.course,
    required this.onTap,
  });

  Color get _categoryColor {
    switch (course.category) {
      case CourseCategory.comp:
        return const Color(0xFF3B82F6);
      case CourseCategory.math:
        return const Color(0xFF8B5CF6);
      case CourseCategory.chem:
        return const Color(0xFFEF4444);
      case CourseCategory.phys:
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Course code badge
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _categoryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    course.code.length >= 2 ? course.code.substring(0, 2) : course.code,
                    style: TextStyle(
                      color: _categoryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Course info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.code,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _categoryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      course.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (course.professors.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        course.professors.join(', '),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              // Credits badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${course.creditHours}cr',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
            ],
          ),
        ),
      ),
    );
  }
}
