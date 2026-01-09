import 'dart:convert';
import 'package:http/http.dart' as http;

/// Notification model
class AppNotification {
  final int id;
  final String userEmail;
  final String title;
  final String message;
  final String type;
  final String? referenceType;
  final String? referenceId;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userEmail,
    required this.title,
    required this.message,
    required this.type,
    this.referenceType,
    this.referenceId,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      userEmail: json['user_email']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString() ?? 'general',
      referenceType: json['reference_type']?.toString(),
      referenceId: json['reference_id']?.toString(),
      isRead: json['is_read'] == true || json['is_read'] == 1,
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

/// API Service for notifications
class ApiNotificationService {
  static const String _baseUrl = 'http://localhost:3000/api';

  /// Get notifications for a user
  static Future<List<AppNotification>> getNotifications(String userEmail) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/notifications/${Uri.encodeComponent(userEmail)}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['notifications'] != null) {
          return (data['notifications'] as List)
              .map((n) => AppNotification.fromJson(n as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('[API] Error getting notifications: $e');
      return [];
    }
  }

  /// Get unread notification count
  static Future<int> getUnreadCount(String userEmail) async {
    try {
      final notifications = await getNotifications(userEmail);
      return notifications.where((n) => !n.isRead).length;
    } catch (e) {
      return 0;
    }
  }

  /// Mark notification as read
  static Future<bool> markAsRead(int notificationId) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/notifications/$notificationId/read'),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('[API] Error marking notification as read: $e');
      return false;
    }
  }

  /// Mark all notifications as read for a user
  static Future<bool> markAllAsRead(String userEmail) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/notifications/read-all/${Uri.encodeComponent(userEmail)}'),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('[API] Error marking all notifications as read: $e');
      return false;
    }
  }
}
