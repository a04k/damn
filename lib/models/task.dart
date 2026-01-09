enum TaskPriority { high, medium, low }

enum TaskStatus { pending, completed, submitted, graded }

enum TaskType { assignment, exam, lab, personal }

class Task {
  final String id;
  final String title;
  final String subject;
  final DateTime? dueDate;
  final TaskStatus status;
  final TaskPriority priority;
  final String? description;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final TaskType taskType;
  final List<String> attachments;
  final List<dynamic>? questions;
  final Map<String, dynamic>? settings;
  final bool published;
  final Map<String, dynamic>? answers;
  final Map<String, dynamic>? submission;
  final String? courseId;
  final int maxPoints;

  Task({
    required this.id,
    required this.title,
    required this.subject,
    this.dueDate,
    required this.status,
    required this.priority,
    this.description,
    required this.createdAt,
    this.updatedAt,
    this.taskType = TaskType.personal,
    this.attachments = const [],
    this.submission,
    this.questions,
    this.settings,
    this.published = true,
    this.answers,
    this.courseId,
    this.maxPoints = 100,
  });

  String? get grade {
    if (submission == null) return null;
    if (submission!['grade'] != null) return submission!['grade'].toString();
    if (submission!['points'] != null) return submission!['points'].toString();
    return null;
  }

  Task copyWith({
    String? id,
    String? title,
    String? subject,
    DateTime? dueDate,
    TaskStatus? status,
    TaskPriority? priority,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    TaskType? taskType,
    List<String>? attachments,
    Map<String, dynamic>? submission,
    List<dynamic>? questions,
    Map<String, dynamic>? settings,
    bool? published,
    Map<String, dynamic>? answers,
    String? courseId,
    int? maxPoints,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      taskType: taskType ?? this.taskType,
      attachments: attachments ?? this.attachments,
      submission: submission ?? this.submission,
      questions: questions ?? this.questions,
      settings: settings ?? this.settings,
      published: published ?? this.published,
      answers: answers ?? this.answers,
      courseId: courseId ?? this.courseId,
      maxPoints: maxPoints ?? this.maxPoints,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subject': subject,
      'dueDate': dueDate?.toIso8601String(),
      'status': status.name.toUpperCase(),
      'priority': priority.name.toUpperCase(),
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'taskType': taskType.name.toUpperCase(),
      'attachments': attachments,
      'submission': submission,
      'questions': questions,
      'settings': settings,
      'published': published,
      'answers': answers,
      'maxPoints': maxPoints,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    // Parse priority
    TaskPriority priority;
    switch ((json['priority'] ?? 'MEDIUM').toString().toUpperCase()) {
      case 'HIGH':
      case 'URGENT':
        priority = TaskPriority.high;
        break;
      case 'LOW':
        priority = TaskPriority.low;
        break;
      default:
        priority = TaskPriority.medium;
    }

    // Parse status
    final statusStr = (json['status'] ?? 'PENDING').toString().toUpperCase();
    TaskStatus status;
    if (statusStr == 'COMPLETED') {
      status = TaskStatus.completed;
    } else if (statusStr == 'SUBMITTED') {
      status = TaskStatus.submitted;
    } else if (statusStr == 'GRADED') {
      status = TaskStatus.graded;
    } else {
      status = TaskStatus.pending;
    }

    // Parse type
    TaskType taskType;
    switch ((json['taskType'] ?? json['type'] ?? 'PERSONAL').toString().toUpperCase()) {
      case 'ASSIGNMENT':
        taskType = TaskType.assignment;
        break;
      case 'EXAM':
        taskType = TaskType.exam;
        break;
      case 'LAB':
        taskType = TaskType.lab;
        break;
      default:
        taskType = TaskType.personal;
    }

    // Parse attachments (handle potential dynamic/list structure)
    List<String> attachments = [];
    if (json['attachments'] != null) {
      if (json['attachments'] is List) {
        attachments = (json['attachments'] as List).map((e) => e.toString()).toList();
      }
    }

    // Parse submission from list if available (backend returns 'submissions' array)
    Map<String, dynamic>? submission;
    if (json['submission'] != null) {
      submission = json['submission'] as Map<String, dynamic>;
    } else if (json['submissions'] != null && (json['submissions'] as List).isNotEmpty) {
      submission = (json['submissions'] as List).first as Map<String, dynamic>;
    }

    // Override status if submission exists
    if (submission != null) {
        final subStatus = (submission['status'] ?? '').toString().toUpperCase();
        if (subStatus == 'GRADED') {
          status = TaskStatus.graded;
        } else if (subStatus == 'SUBMITTED' && status != TaskStatus.graded) {
          status = TaskStatus.submitted;
        }
    }

    return Task(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subject: json['course']?['name'] ?? json['courseName'] ?? 'General',
      dueDate: json['dueDate'] != null ? DateTime.tryParse(json['dueDate'].toString()) : null,
      status: status,
      priority: priority,
      description: json['description']?.toString(),
      maxPoints: json['maxPoints'] as int? ?? 100,
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.tryParse(json['updatedAt'].toString()) 
          : null,
      taskType: taskType,
      attachments: attachments,
      submission: submission,
      questions: json['questions'] as List<dynamic>?,
      settings: json['settings'] as Map<String, dynamic>?,
      published: json['published'] == true,
      answers: json['answers'] as Map<String, dynamic>?,
      courseId: json['course']?['id']?.toString() ?? json['courseId']?.toString(),
    );
  }
}