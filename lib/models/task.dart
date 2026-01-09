enum TaskPriority { high, medium, low }

enum TaskStatus { pending, completed }

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
  });

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
    final status = statusStr == 'COMPLETED' ? TaskStatus.completed : TaskStatus.pending;

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

    return Task(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subject: json['course']?['name'] ?? json['courseName'] ?? 'General',
      dueDate: json['dueDate'] != null ? DateTime.tryParse(json['dueDate'].toString()) : null,
      status: status,
      priority: priority,
      description: json['description']?.toString(),
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.tryParse(json['updatedAt'].toString()) 
          : null,
      taskType: taskType,
    );
  }
}