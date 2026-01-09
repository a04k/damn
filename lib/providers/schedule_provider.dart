import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/schedule_event.dart';
import '../services/data_service.dart';

/// Schedule events provider - ONLY course schedules, NO tasks
/// Includes deduplication and creation logic
final scheduleEventsProvider = AsyncNotifierProvider<ScheduleNotifier, List<ScheduleEvent>>(ScheduleNotifier.new);

class ScheduleNotifier extends AsyncNotifier<List<ScheduleEvent>> {
  @override
  Future<List<ScheduleEvent>> build() async {
    final events = await DataService.getScheduleEvents();
    
    // Deduplicate by event ID
    final uniqueEvents = <String, ScheduleEvent>{};
    for (final event in events) {
      uniqueEvents[event.id] = event;
    }
    
    return uniqueEvents.values.toList();
  }

  Future<void> createEvent({
    required String title,
    required DateTime startTime,
    required DateTime endTime,
    String? description,
    String? location,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final success = await DataService.createScheduleEvent(
        title: title,
        startTime: startTime,
        endTime: endTime,
        description: description,
        location: location,
      );
      
      if (!success) throw Exception('Failed to create event');
      
      // Invalidate upcoming events too
      ref.invalidate(upcomingEventsProvider);
      
      // Return fresh List
      return _fetchEvents();
    });
  }

  Future<List<ScheduleEvent>> _fetchEvents() async {
    final events = await DataService.getScheduleEvents();
    final uniqueEvents = <String, ScheduleEvent>{};
    for (final event in events) {
      uniqueEvents[event.id] = event;
    }
    return uniqueEvents.values.toList();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build());
  }
}

/// Upcoming events provider
final upcomingEventsProvider = FutureProvider<List<ScheduleEvent>>((ref) async {
  final events = await DataService.getUpcomingEvents(days: 7);
  
  // Deduplicate
  final uniqueEvents = <String, ScheduleEvent>{};
  for (final event in events) {
    uniqueEvents[event.id] = event;
  }
  
  return uniqueEvents.values.toList();
});

/// Events for a specific date
final eventsForDateProvider = FutureProvider.family<List<ScheduleEvent>, DateTime>((ref, date) async {
  final allEvents = await ref.watch(scheduleEventsProvider.future);
  
  return allEvents.where((event) {
    return event.startTime.year == date.year &&
           event.startTime.month == date.month &&
           event.startTime.day == date.day;
  }).toList()
    ..sort((a, b) => a.startTime.compareTo(b.startTime));
});

// Removed separate ScheduleController as logic is now in ScheduleNotifier