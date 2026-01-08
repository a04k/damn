import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/announcement.dart';

abstract class AnnouncementRepository {
  Future<List<Announcement>> getAnnouncements();
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();
  Future<void> addAnnouncement(Announcement announcement);
}

class ApiAnnouncementRepository implements AnnouncementRepository {
  static const String _baseUrl = 'http://localhost:3000/api';

  @override
  Future<List<Announcement>> getAnnouncements() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/announcements'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> list = data['announcements'];
        return list.map((json) => Announcement(
          id: json['id'],
          title: json['title'],
          message: json['message'] ?? '',
          date: DateTime.parse(json['date']),
          type: _parseType(json['type']),
          isRead: json['is_read'] == 1,
        )).toList();
      }
      return [];
    } catch (e) {
      print('Error getting announcements: $e');
      return [];
    }
  }

  AnnouncementType _parseType(String? type) {
    switch (type) {
      case 'exam': return AnnouncementType.exam;
      case 'assignment': return AnnouncementType.assignment;
      case 'event': return AnnouncementType.event;
      default: return AnnouncementType.general;
    }
  }

  @override
  Future<void> markAsRead(String id) async {
    try {
      await http.patch(Uri.parse('$_baseUrl/announcements/$id/read'));
    } catch (e) {
      print('Error marking as read: $e');
    }
  }

  @override
  Future<void> markAllAsRead() async {
    // Implement mark all as read API if needed
  }

  @override
  Future<void> addAnnouncement(Announcement announcement) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/announcements'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': announcement.title,
          'message': announcement.message,
          'type': announcement.type.name,
        }),
      );
    } catch (e) {
      print('Error adding announcement: $e');
    }
  }
}