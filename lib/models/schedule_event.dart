class ScheduleEvent {
  final String id;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final String location;
  final String instructor;
  final String? courseId;
  final String? description;
  final String type;

  ScheduleEvent({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.instructor,
    this.courseId,
    this.description,
    this.type = 'lecture',
  });

  ScheduleEvent copyWith({
    String? id,
    String? title,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    String? instructor,
    String? courseId,
    String? description,
    String? type,
  }) {
    return ScheduleEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      instructor: instructor ?? this.instructor,
      courseId: courseId ?? this.courseId,
      description: description ?? this.description,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'location': location,
      'instructor': instructor,
      'courseId': courseId,
      'description': description,
      'type': type,
    };
  }

  factory ScheduleEvent.fromJson(Map<String, dynamic> json) {
    return ScheduleEvent(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Event',
      startTime: json['startTime'] != null ? DateTime.parse(json['startTime']) : DateTime.now(),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : DateTime.now().add(const Duration(hours: 1)),
      location: json['location']?.toString() ?? '',
      instructor: json['instructor']?.toString() ?? '',
      courseId: json['courseId']?.toString(),
      description: json['description']?.toString(),
      type: json['type'] ?? 'lecture',
    );
  }
}