import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import '../providers/schedule_provider.dart';
import '../models/schedule_event.dart';
import '../widgets/schedule_event_card.dart';
import '../widgets/loading_shimmer.dart';
import 'event_detail_screen.dart';
import 'package:intl/intl.dart';
import '../providers/app_session_provider.dart';
import '../storage_services.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String _viewMode = 'week'; // 'day', 'week', 'month'
  DateTime _selectedWeekDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  Future<void> _refreshSchedule() async {
    await ref.refresh(scheduleEventsProvider.future);
    await ref.refresh(upcomingEventsProvider.future);
  }

  List<ScheduleEvent> _getEventsForDay(DateTime day) {
    // This would typically come from the repository
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(scheduleEventsProvider);
    final upcomingEventsAsync = ref.watch(upcomingEventsProvider);
    final eventsForDayAsync = ref.watch(eventsForDateProvider(_selectedWeekDay));

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              children: [
                // Custom header
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/home');
                          }
                        },
                      ),
                      const Text(
                        'Schedule',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      const Spacer(),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          setState(() {
                            _viewMode = value;
                            switch (value) {
                              case 'week':
                                _calendarFormat = CalendarFormat.week;
                                break;
                              case 'month':
                                _calendarFormat = CalendarFormat.month;
                                break;
                            }
                          });
                        },
                        itemBuilder: (context) => [
                          
                          const PopupMenuItem(
                            value: 'week',
                            child: Text('Week View'),
                          ),
                          const PopupMenuItem(
                            value: 'month',
                            child: Text('Month View'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Content
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refreshSchedule,
                    child: eventsAsync.when(
              data: (events) {
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      // Calendar View Toggle Buttons
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: SegmentedButton<String>(
                                segments: const [
                                  
                                  ButtonSegment(
                                    value: 'week',
                                    label: Text('Week'),
                                    icon: Icon(Icons.view_week),
                                  ),
                                  ButtonSegment(
                                    value: 'month',
                                    label: Text('Month'),
                                    icon: Icon(Icons.calendar_month),
                                  ),
                                ],
                                selected: {_viewMode},
                                onSelectionChanged: (Set<String> newSelection) {
                                  setState(() {
                                    _viewMode = newSelection.first;
                                    switch (_viewMode) {
                                      
                                      case 'week':
                                        _calendarFormat = CalendarFormat.week;
                                        break;
                                      case 'month':
                                        _calendarFormat = CalendarFormat.month;
                                        break;
                                    }
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
    
                      // Calendar
                      // Day selector row and current time banner
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 1),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Weekday chips
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: _buildWeekDayChips(context),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Current time banner
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: LinearGradient(
                                  colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primary.withOpacity(0.8)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Current Time', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white)),
                                  const SizedBox(height: 8),
                                  Text(
                                    DateFormat('h:mm a').format(DateTime.now()),
                                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('EEEE, MMMM d, y').format(DateTime.now()),
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Next Lecture card
                            eventsForDayAsync.when(
                              data: (eventsForDay) {
                                final now = DateTime.now();
                                final upcoming = eventsForDay.where((e) => e.startTime.isAfter(now)).toList();
                                upcoming.sort((a, b) => a.startTime.compareTo(b.startTime));
                                final next = upcoming.isNotEmpty ? upcoming.first : null;
                                if (next == null) {
                                  return const SizedBox.shrink();
                                }
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 8),
                                    Text('Next Lecture', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 8),
                                    ScheduleEventCard(
                                      event: next,
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(builder: (context) => EventDetailScreen(eventId: next.id)),
                                        );
                                      },
                                    ),
                                  ],
                                );
                              },
                              loading: () => const SizedBox.shrink(),
                              error: (_, __) => const SizedBox.shrink(),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                      // Calendar (kept after the banners)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TableCalendar<ScheduleEvent>(
                          firstDay: DateTime.utc(2020, 1, 1),
                          lastDay: DateTime.utc(2030, 12, 31),
                          focusedDay: _focusedDay,
                          calendarFormat: _calendarFormat,
                          selectedDayPredicate: (day) {
                            return isSameDay(_selectedDay, day);
                          },
                          eventLoader: (day) {
                            return events.where((e) => isSameDay(e.startTime, day)).toList();
                          },
                          onDaySelected: (selectedDay, focusedDay) {
                            if (!isSameDay(_selectedDay, selectedDay)) {
                              setState(() {
                                _selectedDay = selectedDay;
                                _focusedDay = focusedDay;
                                _selectedWeekDay = selectedDay; // Sync with chips
                              });
                            }
                          },
                          calendarBuilders: CalendarBuilders(
                            headerTitleBuilder: (context, day) {
                              return Center(
                                child: Text(
                                  DateFormat.yMMMM().format(day),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              );
                            },
                            defaultBuilder: (context, day, focusedDay) {
                              return _buildCalendarDay(context, day, isSelected: false, isToday: false);
                            },
                            selectedBuilder: (context, day, focusedDay) {
                              return _buildCalendarDay(context, day, isSelected: true, isToday: false);
                            },
                            todayBuilder: (context, day, focusedDay) {
                              return _buildCalendarDay(context, day, isSelected: false, isToday: true);
                            },
                          ),
                          calendarStyle: const CalendarStyle(
                            outsideDaysVisible: false,
                            weekendTextStyle: TextStyle(color: Colors.red),
                            holidayTextStyle: TextStyle(color: Colors.red),
                          ),
                          headerStyle: const HeaderStyle(
                            formatButtonVisible: false,
                            titleCentered: true,
                          ),
                        ),
                      ),
    
                      const SizedBox(height: 16),
    
                      // Upcoming Events
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('EEEE, MMM d').format(_selectedWeekDay),
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            eventsForDayAsync.when(
                              data: (dayEvents) {
                                if (dayEvents.isEmpty) {
                                  return Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Center(
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.event_available,
                                            size: 48,
                                            color: Colors.grey,
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'No events scheduled for this day',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }
    
                                return Column(
                                  children: dayEvents.map((event) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: ScheduleEventCard(
                                      event: event,
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => EventDetailScreen(
                                              eventId: event.id,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  )).toList(),
                                );
                              },
                              loading: () => const Column(
                                children: [
                                  TaskCardShimmer(),
                                  TaskCardShimmer(),
                                  TaskCardShimmer(),
                                ],
                              ),
                              error: (error, stack) => Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      size: 48,
                                      color: Colors.red.shade400,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Error loading events',
                                      style: TextStyle(
                                        color: Colors.red.shade600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      error.toString(),
                                      style: TextStyle(
                                        color: Colors.red.shade500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 12),
                                    ElevatedButton(
                                      onPressed: _refreshSchedule,
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 100), // Bottom padding for navigation bar
                    ],
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading schedule',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.red.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.red.shade500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refreshSchedule,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
                  ),
                ),
                ],
              ),
          ),
        ),
      ),
    );
  }

  Widget? _buildCalendarDay(BuildContext context, DateTime day, {required bool isSelected, required bool isToday}) {
    final events = ref.watch(scheduleEventsProvider);
    return events.when(
      data: (allEvents) {
        final dayEvents = allEvents.where((e) => isSameDay(e.startTime, day));
        final hasExam = dayEvents.any((e) => e.title.toLowerCase().contains('exam'));

        if (hasExam) {
          return Container(
            margin: const EdgeInsets.all(4.0),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
              border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
            ),
            child: Text(
              '${day.day}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          );
        }

        if (isSelected) {
          return Container(
            margin: const EdgeInsets.all(4.0),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${day.day}',
              style: const TextStyle(color: Colors.white),
            ),
          );
        }

        if (isToday) {
          return Container(
            margin: const EdgeInsets.all(4.0),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).colorScheme.primary, width: 1),
            ),
            child: Text(
              '${day.day}',
              style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
            ),
          );
        }

        return null; // Use default style
      },
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
    );
  }

  List<Widget> _buildWeekDayChips(BuildContext context) {
    final today = DateTime.now();
    
    // Days needed: 6 days starting from today, excluding Friday
    final List<DateTime> weekDays = [];
    DateTime current = today;
    while (weekDays.length < 6) {
      if (current.weekday != DateTime.friday) {
        weekDays.add(current);
      }
      current = current.add(const Duration(days: 1));
    }

    return weekDays.map((day) {
      final isSelected = isSameDay(_selectedWeekDay, day);
      return Expanded(
        child: GestureDetector(
          onTap: () {
            setState(() {
              _selectedWeekDay = day;
              _selectedDay = day;
            });
          },
          child: AspectRatio(
            aspectRatio: 1.0,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected ? Theme.of(context).colorScheme.primary : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? Theme.of(context).colorScheme.primary : const Color(0xFFE5E7EB),
                ),
                boxShadow: isSelected
                    ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 6))]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE').format(day),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('d').format(day),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }
}