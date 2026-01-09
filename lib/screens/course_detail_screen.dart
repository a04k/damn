import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/course_provider.dart';
import '../models/course.dart';
import '../models/task.dart';
import 'assignment_detail_screen.dart';
import 'create_exam_screen.dart';
import 'exam_runner_screen.dart';
import '../providers/app_session_provider.dart';

class CourseDetailScreen extends ConsumerStatefulWidget {
  final String courseId;

  const CourseDetailScreen({
    super.key,
    required this.courseId,
  });

  @override
  ConsumerState<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends ConsumerState<CourseDetailScreen> {
  // 0: Content, 1: Assignments, 2: Exams
  int _selectedSegment = 1;

  @override
  Widget build(BuildContext context) {
    final courseAsync = ref.watch(courseByIdProvider(widget.courseId));

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: courseAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text(e.toString())),
        data: (course) {
          if (course == null) {
            return const Center(child: Text("Course not found"));
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  // ---------- Header Card ----------
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF2749F0),
                          Color(0xFF1A3AE0),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // small placeholders (kept for visual parity with screenshot)
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: () {
                                if (context.canPop()) {
                                  context.pop();
                                } else {
                                  context.go('/home');
                                }
                              },
                            ),
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              width: 60,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.85),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          course.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.8,
                          child: Text(
                            course.description,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                            height: 1, color: Colors.white.withOpacity(0.18)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Credit Hours',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.85),
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${course.creditHours}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  )
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Professor(s)',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.85),
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    course.professors.isNotEmpty
                                        ? course.professors.join(', ')
                                        : '-',
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // ---------- Class Schedule Title ----------
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Class Schedule',
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ---------- Schedule Cards ----------
                  Column(
                    children: course.schedule.map((s) {
                      // expecting schedule item fields: day, time, location
                      final String day = s.day;
                      final String time = s.time;
                      final String location = s.location;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF4FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.schedule,
                                  size: 18,
                                  color: Color(0xFF2E6AFF),
                                ),
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    day,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$time • $location',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 8),

                            // CLICKABLE ROOM LINK (navigates to /navigate_screen)
                            Flexible(
                              child: GestureDetector(
                                onTap: () {
                                  // pass the room name to navigate screen via extra
                                  context.push('/navigate_screen',
                                      extra: location);
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.location_on_outlined,
                                        size: 18),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        location,
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.w600,
                                          decoration: TextDecoration.underline,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 18),

                  // ---------- Segmented Control ----------
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _segmentButton('Content', 0),
                          _segmentButton('Assignments', 1),
                          _segmentButton('Exams', 2),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ---------- Selected Section ----------
                  if (_selectedSegment == 0) ...[
                    _buildContentSection(course),
                  ] else if (_selectedSegment == 1) ...[
                    _buildAssignmentsSection(course),
                  ] else ...[
                    _buildExamsSection(course),
                  ],

                  const SizedBox(height: 40),
                  const SizedBox(height: 100), // Bottom padding for navigation bar
                ],
              ),
            ),
          ),
        ),
      );
    },
  ),
    );
  }

  // ---------- helper: segmented buttons ----------
  Widget _segmentButton(String label, int index) {
    final bool selected = _selectedSegment == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedSegment = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black87 : Colors.grey.shade700,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // ---------- Content section ----------
  Widget _buildContentSection(Course course) {
    if (course.content.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 28),
          child: Text('No content yet',
              style: TextStyle(color: Colors.grey.shade600)),
        ),
      );
    }

    return Column(
      children: course.content.map((c) {
        return InkWell(
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) => FractionallySizedBox(
                  heightFactor: 0.9,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.topic,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Week ${c.week}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  'Description',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  c.description,
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                if (c.attachments.isNotEmpty) ...[
                                  const Text(
                                    'Attachments',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...c.attachments.map((url) => InkWell(
                                        onTap: () async {
                                          final uri = Uri.parse(url);
                                          if (await canLaunchUrl(uri)) {
                                            await launchUrl(uri);
                                          }
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.only(bottom: 8.0),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.attach_file,
                                                  color: Colors.blue),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  url.split('/').last,
                                                  style: const TextStyle(
                                                    color: Colors.blue,
                                                    decoration: TextDecoration.underline,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )),
                                  const SizedBox(height: 32),
                                ],
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () => context.pop(),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2E6AFF),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text('Close'),
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF4FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                        child: Text('W${c.week}',
                            style:
                                const TextStyle(fontWeight: FontWeight.w700))),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.topic,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Text(c.description,
                            style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                ],
              ),
            ));
      }).toList(),
    );
  }

  // ---------- Assignments section ----------
  Widget _buildAssignmentsSection(Course course) {
    if (course.assignments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Center(
            child: Text('No assignments yet',
                style: TextStyle(color: Colors.grey.shade600))),
      );
    }

    return Column(
      children: course.assignments.map((a) {
        final isGraded = a.status == 'GRADED' || a.grade != null;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          color: isGraded ? Colors.green[50] : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: isGraded ? BorderSide(color: Colors.green[200]!) : BorderSide.none,
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AssignmentDetailScreen(
                    task: Task(
                      id: a.id,
                      title: a.title,
                      subject: course.name,
                      dueDate: a.dueDate,
                      status: a.status == 'GRADED' 
                          ? TaskStatus.graded 
                          : a.isSubmitted ? TaskStatus.submitted : TaskStatus.pending,
                      submission: (a.grade != null || a.status == 'GRADED') 
                          ? {'grade': a.grade, 'points': a.grade} 
                          : null,
                      priority: TaskPriority.medium,
                      description: a.description,
                      createdAt: DateTime.now(),
                      taskType: TaskType.assignment,
                      attachments: a.attachments,
                    ),
                  ),
                ),
              );
            },

            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // title + points pill
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          a.title,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (a.status == 'GRADED' && a.grade != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.green[200]!),
                          ),
                          child: Text('${a.grade} pts',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: Colors.green[700])),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF4FF),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: const Color(0xFF2E6AFF).withOpacity(0.15)),
                          ),
                          child: Text('${a.maxScore} pts',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: Color(0xFF2E6AFF))),
                        )
                    ],
                  ),

                  const SizedBox(height: 8),

                  // description
                  Text(
                    a.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),

                  const SizedBox(height: 12),

                  // due date row
                  Row(
                    children: [
                      const Icon(Icons.calendar_month_outlined, size: 16),
                      const SizedBox(width: 8),
                      Text('Due: ${_formatDate(a.dueDate)}',
                          style: TextStyle(color: Colors.grey.shade600)),
                      const Spacer(),
                      Icon(Icons.chevron_right, color: Colors.grey[400]),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ---------- Exams section ----------
  Widget _buildExamsSection(Course course) {
    // Check if current user is a professor using the session state directly or currentUserProvider
    final sessionState = ref.watch(appSessionControllerProvider);
    final isProfessor = sessionState is AppSessionAuthenticated && sessionState.user.isProfessor;
    
    // If empty and not professor, show empty state
    if (course.exams.isEmpty && !isProfessor) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Center(
            child: Text('No exams scheduled',
                style: TextStyle(color: Colors.grey.shade600))),
      );
    }

    return Column(
      children: [
        if (isProfessor)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateExamScreen(courseId: widget.courseId),
                    ),
                  );
                  if (result == true) {
                    ref.invalidate(courseByIdProvider(widget.courseId));
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Exam'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E6AFF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
          
        ...course.exams.map((e) {
          final isSubmitted = e.isSubmitted;
          final isGraded = e.status == 'GRADED';
          
          return InkWell(
            onTap: () {
              if (isProfessor) {
                 context.push(
                    '/grading/${e.id}',
                    extra: {
                      'title': e.title,
                      'maxPoints': 100 // We might want to pass real max points if available in Exam model
                    }
                 );
              } else {
                if (isSubmitted) {
                    String msg = 'You have already submitted this exam.';
                    if (e.status == 'GRADED' && e.grade != null) {
                       msg += ' Grade: ${e.grade}';
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(msg)),
                    );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ExamRunnerScreen(taskId: e.id, courseId: widget.courseId)),
                  );
                }
              }
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSubmitted ? Colors.green[50] : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSubmitted ? Colors.green[200]! : Colors.grey.shade200
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(e.title,
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                      if (isSubmitted)
                        Chip(
                          label: Text(isGraded ? 'Graded' : 'Submitted'),
                          backgroundColor: Colors.green[100],
                          labelStyle: TextStyle(color: Colors.green[900], fontSize: 12),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Date: ${_formatDate(e.date)}',
                      style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 6),
                  Text('Format: ${e.format}',
                      style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 6),
                  Text('Grading: ${e.gradingBreakdown}',
                      style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            ),
          );
        }),
        
        if (course.exams.isEmpty && isProfessor)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                'No exams scheduled yet',
                 style: TextStyle(color: Colors.grey.shade500),
              ),
            ),
          ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
