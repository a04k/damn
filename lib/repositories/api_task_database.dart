import 'dart:convert';
import 'package:http/http.dart' as http;

/// Task model for API
class ApiTask {
  final String id;
  final String title;
  final String course;
  final String priority;
  bool completed;
  final String? description;
  final String? userId;

  ApiTask({
    required this.id,
    required this.title,
    required this.course,
    required this.priority,
    this.completed = false,
    this.description,
    this.userId,
  });

  factory ApiTask.fromJson(Map<String, dynamic> json) {
    return ApiTask(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      course: json['course'] ?? 'General',
      priority: json['priority'] ?? 'low',
      completed: json['completed'] ?? false,
      description: json['description'],
      userId: json['userId'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'course': course,
    'priority': priority,
    'completed': completed,
    'description': description,
    'userId': userId,
  };
}

/// API Task Database Service - Works on all platforms including Web
class ApiTaskDatabase {
  static const String _baseUrl = 'http://localhost:3000/api';

  /// Get all tasks
  static Future<List<ApiTask>> getAllTasks() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/tasks'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final tasksList = data['tasks'] as List;
        return tasksList.map((t) => ApiTask.fromJson(t)).toList();
      }
    } catch (e) {
      print('[API Tasks] Error getting tasks: $e');
    }
    return [];
  }

  /// Add a new task
  static Future<ApiTask?> addTask({
    required String title,
    required String course,
    required String priority,
    String? description,
    String? userId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/tasks'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          'course': course,
          'priority': priority,
          'description': description,
          'userId': userId,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiTask.fromJson(data['task']);
      }
    } catch (e) {
      print('[API Tasks] Error adding task: $e');
    }
    return null;
  }

  /// Update a task
  static Future<bool> updateTask(String id, Map<String, dynamic> updates) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/tasks/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updates),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('[API Tasks] Error updating task: $e');
    }
    return false;
  }

  /// Toggle task completion
  static Future<bool> toggleComplete(String id) async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/tasks/$id/toggle'),
        headers: {'Content-Type': 'application/json'},
      );
      return response.statusCode == 200;
    } catch (e) {
      print('[API Tasks] Error toggling task: $e');
    }
    return false;
  }

  /// Delete a task
  static Future<bool> deleteTask(String id) async {
    try {
      final response = await http.delete(Uri.parse('$_baseUrl/tasks/$id'));
      return response.statusCode == 200;
    } catch (e) {
      print('[API Tasks] Error deleting task: $e');
    }
    return false;
  }
}
