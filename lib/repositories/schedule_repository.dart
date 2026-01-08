import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/schedule_event.dart';

abstract class ScheduleRepository {
  Future<List<ScheduleEvent>> getEvents();
  Future<List<ScheduleEvent>> getEventsForDate(DateTime date);
  Future<List<ScheduleEvent>> getUpcomingEvents({int days = 7});
  Future<ScheduleEvent?> getEventById(String id);
}

class ApiScheduleRepository implements ScheduleRepository {
  static const String _baseUrl = 'http://localhost:3000/api';

  @override
  Future<List<ScheduleEvent>> getEvents() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/schedule'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> list = data['events'];
        return list.map((json) => ScheduleEvent(
          id: json['id'],
          title: json['title'],
          startTime: DateTime.parse(json['start_time']),
          endTime: DateTime.parse(json['end_time']),
          location: json['location'],
          instructor: json['instructor'],
          courseId: json['course_id'],
          description: json['description'],
          type: json['type'] ?? 'lecture',
        )).toList();
      }
      return [];
    } catch (e) {
      print('Error getting schedule: $e');
      return [];
    }
  }

  @override
  Future<List<ScheduleEvent>> getEventsForDate(DateTime date) async {
    final allEvents = await getEvents();
    return allEvents.where((event) {
      return event.startTime.year == date.year &&
             event.startTime.month == date.month &&
             event.startTime.day == date.day;
    }).toList();
  }

  @override
  Future<List<ScheduleEvent>> getUpcomingEvents({int days = 7}) async {
    final allEvents = await getEvents();
    final now = DateTime.now();
    final future = now.add(Duration(days: days));
    return allEvents.where((event) {
      return event.startTime.isAfter(now) && event.startTime.isBefore(future);
    }).toList();
  }

  @override
  Future<ScheduleEvent?> getEventById(String id) async {
    final allEvents = await getEvents();
    try {
      return allEvents.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }
}