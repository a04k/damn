import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/schedule_event.dart';
import '../services/data_service.dart';

/// Schedule events provider using DataService
final scheduleEventsProvider = FutureProvider<List<ScheduleEvent>>((ref) async {
  final scheduleEvents = await DataService.getScheduleEvents();
  final tasks = await DataService.getTasks();

  final taskEvents = tasks.map((t) {
    return ScheduleEvent(
      id: 'task_${t.id}',
      title: t.title,
      startTime: t.dueDate,
      endTime: t.dueDate.add(const Duration(hours: 1)),
      location: '',
      instructor: '',
      courseId: t.subject,
      description: t.description,
      type: t.type.toLowerCase() == 'personal' ? 'personal' :
           (t.type.toLowerCase().contains('exam') ? 'exam' : 'assignment'),
    );
  }).toList();

  return [...scheduleEvents, ...taskEvents];
});

/// Upcoming events provider
final upcomingEventsProvider = FutureProvider<List<ScheduleEvent>>((ref) async {
  return DataService.getUpcomingEvents(days: 7);
});

/// Events for a specific date
final eventsForDateProvider = FutureProvider.family<List<ScheduleEvent>, DateTime>((ref, date) async {
  final allEvents = await ref.watch(scheduleEventsProvider.future);
  return allEvents.where((event) {
    return event.startTime.year == date.year &&
           event.startTime.month == date.month &&
           event.startTime.day == date.day;
  }).toList();
});

/// Schedule controller for creating events
final scheduleControllerProvider = StateNotifierProvider<ScheduleController, AsyncValue<void>>((ref) {
  return ScheduleController(ref);
});

class ScheduleController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  ScheduleController(this._ref) : super(const AsyncValue.data(null));

  Future<void> createEvent({
    required String title,
    required DateTime startTime,
    required DateTime endTime,
    String? description,
    String? location,
  }) async {
    state = const AsyncValue.loading();
    try {
      final success = await DataService.createScheduleEvent(
        title: title,
        startTime: startTime,
        endTime: endTime,
        description: description,
        location: location,
      );
      
      if (success) {
        _ref.invalidate(scheduleEventsProvider);
        _ref.invalidate(upcomingEventsProvider);
      }
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}