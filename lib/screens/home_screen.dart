import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_mode_provider.dart';
import '../providers/announcement_provider.dart';
import '../providers/task_provider.dart';
import '../providers/course_provider.dart';
import '../models/task.dart';
import '../widgets/loading_shimmer.dart';
import '../widgets/info_card.dart';
import '../widgets/quick_action.dart';
import '../widgets/schedule_event_card.dart';
import '../providers/schedule_provider.dart';
import 'package:intl/intl.dart';
import '../storage_services.dart';
import '../providers/app_session_provider.dart';
import '../models/user.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Schedule the refresh after the first frame to avoid calling
    // `ref.refresh` during the build phase which can trigger the
    // "markNeedsBuild during build" error for other widgets.
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshData());
  }

  Future<void> _refreshData() async {
    // Invalidate current user provider to force re-read
    ref.invalidate(currentUserProvider);
    
    await Future.wait([
      ref.refresh(announcementsProvider.future),
      ref.refresh(pendingTasksProvider.future),
      ref.refresh(enrolledCoursesProvider.future),
      ref.refresh(scheduleEventsProvider.future),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final pendingTasksAsync = ref.watch(pendingTasksProvider);
    final enrolledCoursesAsync = ref.watch(enrolledCoursesProvider);
    final userAsync = ref.watch(currentUserProvider);
    
    final bool isDoctor = userAsync.maybeWhen(
      data: (user) => user != null && user.mode == AppMode.professor,
      orElse: () => false,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine grid columns based on width
        int gridColumns = 2;
        if (constraints.maxWidth > 450) {
          gridColumns = 3;
        } else {
          gridColumns = 1;
        }

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: _refreshData,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Padding for header (only on home screen)
                        const SizedBox(height: 80), // Header height

                        // Info Cards
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            children: [
                              Expanded(
                                child: pendingTasksAsync.when(
                                  data: (tasks) => InfoCard(
                                    title: "Today's Work",
                                    subtitle: '${tasks.length} pending tasks',
                                    progress: tasks.isEmpty
                                        ? 0.0
                                        : (tasks
                                                    .where((t) =>
                                                        t.status !=
                                                        TaskStatus.completed)
                                                    .length /
                                                (tasks.length))
                                            .clamp(0.0, 1.0),
                                    height: 120,
                                    icon: const Icon(
                                      Icons.task_alt,
                                      size: 16,
                                      color: Color(0xFFF97316), // orange-500
                                    ),
                                    backgroundColor:
                                        const Color(0xFFFFF7ED), // orange-50
                                    onTap: () => context.go('/tasks'),
                                  ),
                                  loading: () => const LoadingShimmer(height: 120),
                                  error: (error, stack) => Container(
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(child: Text('Error: $error')),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ref.watch(scheduleEventsProvider).when(
                                  data: (events) {
                                    final now = DateTime.now();
                                    // Filter for future events today that are not exams
                                    final upcomingLectures = events.where((e) => 
                                      e.startTime.isAfter(now) && 
                                      e.startTime.day == now.day &&
                                      !e.title.toLowerCase().contains('exam')
                                    ).toList();
                                    
                                    // Sort by start time just in case
                                    upcomingLectures.sort((a, b) => a.startTime.compareTo(b.startTime));
                                    
                                    final nextLecture = upcomingLectures.isNotEmpty ? upcomingLectures.first : null;
                                    
                                    return InfoCard(
                                      title: 'Next Lecture',
                                      subtitle: nextLecture?.title ?? "No more lectures today",
                                      time: nextLecture != null ? DateFormat('h:mm a').format(nextLecture.startTime) : null,
                                      height: 120,
                                      icon: const Icon(
                                        Icons.school,
                                        size: 16,
                                        color: Color(0xFF16A34A), // green-600
                                      ),
                                      backgroundColor: const Color(0xFFF0FDF4), // green-50
                                      onTap: () => context.go('/schedule'),
                                    );
                                  },
                                  loading: () => const LoadingShimmer(height: 120),
                                  error: (error, stack) => Container(
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(child: Text('Error: $error')),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Actions Section
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            'Actions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24), // Restored padding
                          child: GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: gridColumns,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.1, // Taller cards for better presence
                            children: [
                              if (!isDoctor) 
                              QuickAction(
                                title: 'Assignments',
                                icon: const Icon(
                                  Icons.task,
                                  size: 22,
                                  color: Color(0xFF9333EA), // purple-600
                                ),
                                backgroundColor: const Color(0xFFF3E8FF), // purple-50
                                onTap: () => context.go('/assignments'),
                              ),
                              QuickAction(
                                title: 'Schedule',
                                icon: const Icon(
                                  Icons.calendar_today,
                                  size: 22,
                                  color: Color(0xFF3B82F6), // blue-600
                                ),
                                backgroundColor: const Color(0xFFEFF6FF), // blue-50
                                onTap: () => context.go('/schedule'),
                              ),
                              QuickAction(
                                title: 'Courses',
                                icon: const Icon(
                                  Icons.menu_book,
                                  size: 22,
                                  color: Color(0xFF16A34A), // green-600
                                ),
                                backgroundColor: const Color(0xFFF0FDF4), // green-50
                                onTap: () => isDoctor
                                    ? context.go('/dr-course/1')
                                    : context.go('/my-courses'),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Upcoming Exams Section
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            'Upcoming Exams',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: ref.watch(scheduleEventsProvider).when(
                            data: (events) {
                              final exams = events
                                  .where((e) => e.title.toLowerCase().contains('exam'))
                                  .toList();
                              
                              if (exams.isEmpty) {
                                return Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF9FAFB),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFE5E7EB)),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(Icons.assignment_outlined, size: 48, color: Colors.grey.shade400),
                                      const SizedBox(height: 12),
                                      Text(
                                        'No upcoming exams',
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: exams.length,
                                itemBuilder: (context, index) {
                                  final exam = exams[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: ScheduleEventCard(
                                      event: exam,
                                      onTap: () => context.go('/schedule'),
                                    ),
                                  );
                                },
                              );
                            },
                            loading: () => const LoadingShimmer(height: 200),
                            error: (error, stack) => Center(child: Text('Error: $error')),
                          ),
                        ),

                        // Bottom padding for floating elements
                        const SizedBox(height: 120), // Account for FAB and bottom nav
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

}
