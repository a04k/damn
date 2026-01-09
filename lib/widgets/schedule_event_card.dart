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

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Time indicator
              Container(
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                  color: _getEventColor(),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              
              // Event content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(event.startTime),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.location,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            event.instructor,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getEventColor().withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _getEventTypeLabel(),
                            style: TextStyle(
                              fontSize: 10,
                              color: _getEventColor(),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Arrow icon
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getEventColor() {
    final type = event.type.toLowerCase();
    final title = event.title.toLowerCase();
    
    // Check for exam
    if (type == 'exam' || title.contains('exam') || title.contains('midterm') || title.contains('final')) {
      return Colors.red;
    }
    // Check for assignment
    if (type == 'assignment' || title.contains('assignment') || title.contains('due:') || title.contains('submit')) {
      return Colors.orange;
    }
    if (type == 'lab') {
      return Colors.purple;
    }
    if (type == 'lecture' || event.courseId != null) {
      return Colors.blue;
    }
    if (type == 'task') {
      return Colors.teal;
    }
    return Colors.green;
  }

  String _getEventTypeLabel() {
    final type = event.type.toLowerCase();
    final title = event.title.toLowerCase();
    
    // Check for exam
    if (type == 'exam' || title.contains('exam') || title.contains('midterm') || title.contains('final')) {
      return 'Exam';
    }
    // Check for assignment - also check title keywords
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