enum CourseCategory { comp, math, chem, phys, hist, eng }

enum EnrollmentStatus { enrolled, wishlist, available, completed }

class Course {
  final String id;
  final String code;
  final String name;
  final CourseCategory category;
  final int creditHours;
  final List<String> professors;
  final String description;
  final List<CourseSchedule> schedule;
  final List<CourseContent> content;
  final List<Assignment> assignments;
  final List<Exam> exams;
  final EnrollmentStatus enrollmentStatus;
  final Map<String, dynamic>? stats;
  final bool isPrimary; // View-specific field for professors

  Course({
    required this.id,
    required this.code,
    required this.name,
    required this.category,
    required this.creditHours,
    required this.professors,
    required this.description,
    required this.schedule,
    required this.content,
    required this.assignments,
    required this.exams,
    this.enrollmentStatus = EnrollmentStatus.available,
    this.stats,
    this.isPrimary = false,
  });

  Course copyWith({
    String? id,
    String? code,
    String? name,
    CourseCategory? category,
    int? creditHours,
    List<String>? professors,
    String? description,
    List<CourseSchedule>? schedule,
    List<CourseContent>? content,
    List<Assignment>? assignments,
    List<Exam>? exams,
    EnrollmentStatus? enrollmentStatus,
    bool? isPrimary,
  }) {
    return Course(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      category: category ?? this.category,
      creditHours: creditHours ?? this.creditHours,
      professors: professors ?? this.professors,
      description: description ?? this.description,
      schedule: schedule ?? this.schedule,
      content: content ?? this.content,
      assignments: assignments ?? this.assignments,
      exams: exams ?? this.exams,
      enrollmentStatus: enrollmentStatus ?? this.enrollmentStatus,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'category': category.name,
      'creditHours': creditHours,
      'professors': professors,
      'description': description,
      'schedule': schedule.map((e) => e.toJson()).toList(),
      'content': content.map((e) => e.toJson()).toList(),
      'assignments': assignments.map((e) => e.toJson()).toList(),
      'exams': exams.map((e) => e.toJson()).toList(),
      'enrollmentStatus': enrollmentStatus.name,
      'stats': stats,
      'isPrimary': isPrimary,
    };
  }

  factory Course.fromJson(Map<String, dynamic> json) {
    // Handle both camelCase and snake_case from different sources
    final creditHrs = json['creditHours'] ?? json['credit_hours'] ?? 3;
    
    // Parse category safely
    CourseCategory cat = CourseCategory.comp;
    final catStr = json['category']?.toString();
    if (catStr != null) {
      cat = CourseCategory.values.firstWhere(
        (e) => e.name == catStr,
        orElse: () => CourseCategory.comp,
      );
    }
    
    // Parse lists safely
    List<CourseSchedule> scheduleList = [];
    if (json['schedule'] != null && json['schedule'] is List) {
      scheduleList = (json['schedule'] as List)
          .map((e) => CourseSchedule.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    
    List<CourseContent> contentList = [];
    if (json['content'] != null && json['content'] is List) {
      contentList = (json['content'] as List)
          .map((e) => CourseContent.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    
    List<Assignment> assignmentList = [];
    if (json['assignments'] != null && json['assignments'] is List) {
      assignmentList = (json['assignments'] as List)
          .map((e) => Assignment.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    
    List<Exam> examList = [];
    if (json['exams'] != null && json['exams'] is List) {
      examList = (json['exams'] as List)
          .map((e) => Exam.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    
    // Parse professors safely
    List<String> profs = [];
    if (json['professors'] != null && json['professors'] is List) {
      profs = (json['professors'] as List).map((p) {
        if (p is Map) {
          return p['name']?.toString() ?? 'Unknown';
        }
        return p?.toString() ?? 'Unknown';
      }).toList();
    }
    
    return Course(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: cat,
      creditHours: creditHrs is int ? creditHrs : int.tryParse(creditHrs.toString()) ?? 3,
      professors: profs,
      description: json['description']?.toString() ?? '',
      schedule: scheduleList,
      content: contentList,
      assignments: assignmentList,
      exams: examList,
      enrollmentStatus: json['enrollmentStatus'] != null
          ? EnrollmentStatus.values.firstWhere(
              (e) => e.name == json['enrollmentStatus'],
              orElse: () => EnrollmentStatus.available)
          : EnrollmentStatus.available,
      stats: json['stats'],
      isPrimary: json['isPrimary'] == true,
    );
  }
}

class CourseSchedule {
  final String day;
  final String time; // example: "10:00 - 12:00"
  final String location; // example: "Room 201"

  CourseSchedule({
    required this.day,
    required this.time,
    required this.location,
  });

  /// Parse start time
  DateTime? get startTime {
    try {
      final parts = time.split('-');
      return DateTime.parse("2024-01-01 ${parts[0].trim()}:00");
    } catch (_) {
      return null;
    }
  }

  /// Parse end time
  DateTime? get endTime {
    try {
      final parts = time.split('-');
      return DateTime.parse("2024-01-01 ${parts[1].trim()}:00");
    } catch (_) {
      return null;
    }
  }

  /// Room = location
  String get room => location;

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'time': time,
      'location': location,
    };
  }

  factory CourseSchedule.fromJson(Map<String, dynamic> json) {
    return CourseSchedule(
      day: json['day']?.toString() ?? 'TBD',
      time: json['time']?.toString() ?? 'TBD',
      location: json['location']?.toString() ?? 'TBD',
    );
  }
}

class CourseContent {
  final int week;
  final String topic;
  final String description;
  final List<String> attachments;

  CourseContent({
    required this.week,
    required this.topic,
    required this.description,
    this.attachments = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'week': week,
      'topic': topic,
      'description': description,
      'attachments': attachments,
    };
  }

  factory CourseContent.fromJson(Map<String, dynamic> json) {
    return CourseContent(
      week: json['week'] is int ? json['week'] : int.tryParse(json['week']?.toString() ?? '0') ?? 0,
      topic: json['topic']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      attachments: (json['attachments'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

class Assignment {
  final String id;
  final String title;
  final DateTime dueDate;
  final int maxScore;
  final String description;
  final bool isSubmitted;
  final List<String> attachments;
  final double? grade;
  final String? status;

  Assignment({
    required this.id,
    required this.title,
    required this.dueDate,
    required this.maxScore,
    required this.description,
    this.isSubmitted = false,
    this.attachments = const [],
    this.grade,
    this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'dueDate': dueDate.toIso8601String(),
      'maxScore': maxScore,
      'description': description,
      'isSubmitted': isSubmitted,
      'attachments': attachments,
      'grade': grade,
      'status': status,
    };
  }

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      dueDate: json['dueDate'] != null ? DateTime.tryParse(json['dueDate'].toString()) ?? DateTime.now() : DateTime.now(),
      maxScore: json['maxScore'] is int ? json['maxScore'] : int.tryParse(json['maxScore']?.toString() ?? '100') ?? 100,
      description: json['description']?.toString() ?? '',
      isSubmitted: json['isSubmitted'] == true,
      attachments: (json['attachments'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      grade: json['grade'] != null ? double.tryParse(json['grade'].toString()) : null,
      status: json['status']?.toString(),
    );
  }

  get points => null;
}

class Exam {
  final String id;
  final String title;
  final DateTime date;
  final String format;
  final String gradingBreakdown;
  final List<String> attachments;
  final bool isSubmitted;
  final String? status;
  final String? grade;

  Exam({
    required this.id,
    required this.title,
    required this.date,
    required this.format,
    required this.gradingBreakdown,
    this.attachments = const [],
    this.isSubmitted = false,
    this.status,
    this.grade,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date.toIso8601String(),
      'format': format,
      'gradingBreakdown': gradingBreakdown,
      'attachments': attachments,
      'isSubmitted': isSubmitted,
      'status': status,
    };
  }

  factory Exam.fromJson(Map<String, dynamic> json) {
    return Exam(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      date: json['date'] != null ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now() : DateTime.now(),
      format: json['format']?.toString() ?? '',
      gradingBreakdown: json['gradingBreakdown']?.toString() ?? '',
      attachments: (json['attachments'] as List?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      isSubmitted: json['isSubmitted'] ?? false,
      status: json['status']?.toString(),
      grade: (json['grade'] ?? json['points'] ?? json['submission']?['grade'] ?? json['submission']?['points'])?.toString(),
    );
  }
}