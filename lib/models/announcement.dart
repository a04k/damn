enum AnnouncementType { exam, assignment, general, event }

class Announcement {
  final String id;
  final String title;
  final String message;
  final DateTime date;
  final AnnouncementType type;
  final bool isRead;
  final String? courseCode;
  final String? courseName;

  Announcement({
    required this.id,
    required this.title,
    required this.message,
    required this.date,
    required this.type,
    this.isRead = false,
    this.courseCode,
    this.courseName,
  });

  Announcement copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? date,
    AnnouncementType? type,
    bool? isRead,
    String? courseCode,
    String? courseName,
  }) {
    return Announcement(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      date: date ?? this.date,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      courseCode: courseCode ?? this.courseCode,
      courseName: courseName ?? this.courseName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'date': date.toIso8601String(),
      'type': type.name,
      'isRead': isRead,
      'courseCode': courseCode,
      'courseName': courseName,
    };
  }

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      date: json['date'] != null 
          ? DateTime.parse(json['date']) 
          : (json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now()),
      type: AnnouncementType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AnnouncementType.general,
      ),
      isRead: json['isRead'] ?? false,
      courseCode: json['courseCode'] ?? json['course']?['code'],
      courseName: json['courseName'] ?? json['course']?['name'],
    );
  }
}