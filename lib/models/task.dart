enum TaskPriority { high, medium, low }

enum TaskStatus { pending, completed }

class Task {
  final String id;
  final String title;
  final String subject;
  final DateTime dueDate;
  final TaskStatus status;
  final TaskPriority priority;
  final String? description;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String type; // ASSIGNMENT, EXAM, LAB, PERSONAL

  Task({
    required this.id,
    required this.title,
    required this.subject,
    required this.dueDate,
    required this.status,
    required this.priority,
    this.description,
    required this.createdAt,
    this.updatedAt,
    this.type = 'PERSONAL',
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
    String? type,
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
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subject': subject,
      'dueDate': dueDate.toIso8601String(),
      'status': status.name,
      'priority': priority.name,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'type': type,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      subject: json['subject'],
      dueDate: DateTime.parse(json['dueDate']),
      status: TaskStatus.values.firstWhere((e) => e.name == json['status']),
      priority: TaskPriority.values.firstWhere((e) => e.name == json['priority']),
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      type: json['type'] ?? 'PERSONAL',
    );
  }
}