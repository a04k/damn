import 'package:flutter/material.dart';
import '../models/schedule_event.dart';
import 'package:intl/intl.dart';

class ScheduleEventCard extends StatelessWidget {
  final ScheduleEvent event;
  final VoidCallback? onTap;

  const ScheduleEventCard({
    super.key,
    required this.event,
    this.onTap,
  });

  static const Color _navyColor = Color(0xFF002147);
  static const Color _goldColor = Color(0xFFFDC800);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon container
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getEventColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getEventIcon(),
                    color: _getEventColor(),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                
                // Event content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              event.title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: _navyColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getEventColor().withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _getEventTypeLabel(),
                              style: TextStyle(
                                fontSize: 11,
                                color: _getEventColor(),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule_outlined,
                            size: 14,
                            color: Color(0xFF6B7280),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatTime(event.startTime),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: Color(0xFF6B7280),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              event.location,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B7280),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (event.instructor.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.person_outline,
                              size: 14,
                              color: Color(0xFF6B7280),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                event.instructor,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF6B7280),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Arrow
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFFD1D5DB),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getEventIcon() {
    final type = event.type.toLowerCase();
    final title = event.title.toLowerCase();
    
    if (type == 'exam' || title.contains('exam') || title.contains('midterm') || title.contains('final')) {
      return Icons.assignment_outlined;
    }
    if (type == 'assignment' || title.contains('assignment') || title.contains('due:') || title.contains('submit')) {
      return Icons.edit_document;
    }
    if (type == 'lab') {
      return Icons.science_outlined;
    }
    if (type == 'lecture' || event.courseId != null) {
      return Icons.menu_book_outlined;
    }
    if (type == 'task') {
      return Icons.check_circle_outline;
    }
    return Icons.event_outlined;
  }

  Color _getEventColor() {
    final type = event.type.toLowerCase();
    final title = event.title.toLowerCase();
    
    // Exam - red
    if (type == 'exam' || title.contains('exam') || title.contains('midterm') || title.contains('final')) {
      return const Color(0xFFDC2626);
    }
    // Assignment - orange/gold
    if (type == 'assignment' || title.contains('assignment') || title.contains('due:') || title.contains('submit')) {
      return const Color(0xFFF59E0B);
    }
    if (type == 'lab') {
      return const Color(0xFF8B5CF6);
    }
    // Lecture - navy
    if (type == 'lecture' || event.courseId != null) {
      return _navyColor;
    }
    if (type == 'task') {
      return const Color(0xFF10B981);
    }
    return const Color(0xFF3B82F6);
  }

  String _getEventTypeLabel() {
    final type = event.type.toLowerCase();
    final title = event.title.toLowerCase();
    
    if (type == 'exam' || title.contains('exam') || title.contains('midterm') || title.contains('final')) {
      return 'Exam';
    }
    if (type == 'assignment' || title.contains('assignment') || title.contains('due:') || title.contains('submit')) {
      return 'Assignment';
    }
    if (type == 'lab') {
      return 'Lab';
    }
    if (type == 'lecture') {
      return 'Lecture';
    }
    if (type == 'task') {
      return 'Task';
    }
    return 'Event';
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime);
  }
}