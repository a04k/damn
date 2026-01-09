import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';

/// API Service for communicating with the backend server
/// which handles MySQL database operations
class ApiUserDatabase {
  static const String _baseUrl = 'http://localhost:3000/api';

  /// Login user with email and password
  static Future<User?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _jsonToUser(data['user']);
      }
      print('[API] Login failed: ${response.body}');
      return null;
    } catch (e) {
      print('[API] Login error: $e');
      return null;
    }
  }

  /// Register a new user
  static Future<User?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _jsonToUser(data['user']);
      } else if (response.statusCode == 409) {
        throw Exception('User already exists');
      }
      print('[API] Register failed: ${response.body}');
      return null;
    } catch (e) {
      print('[API] Register error: $e');
      rethrow;
    }
  }

  /// Get user by email
  static Future<User?> getUser(String email) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users/${Uri.encodeComponent(email)}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _jsonToUser(data['user']);
      }
      return null;
    } catch (e) {
      print('[API] GetUser error: $e');
      return null;
    }
  }

  /// Update user data
  static Future<User?> updateUser(User user) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/users/${Uri.encodeComponent(user.email)}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': user.name,
          'avatar': user.avatar,
          'major': user.major,
          'department': user.department,
          'gpa': user.gpa,
          'level': user.level,
          'mode': user.mode.name,
          'isOnboardingComplete': user.isOnboardingComplete,
          'enrolledCourses': user.enrolledCourses,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['user'] != null) {
          print('[API] User updated successfully: ${user.email}');
          return _jsonToUser(data['user']);
        }
        return user;
      }
      print('[API] Update failed: ${response.body}');
      return null;
    } catch (e) {
      print('[API] Update error: $e');
      return null;
    }
  }

  /// Change user password
  static Future<bool> changePassword(
      String email, String currentPassword, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/change-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('[API] ChangePassword error: $e');
      return false;
    }
  }

  /// Delete all users from the database (for development/testing)
  static Future<bool> deleteAllUsers() async {
    try {
      final response = await http.delete(Uri.parse('$_baseUrl/users'));
      if (response.statusCode == 200) {
        print('[API] All users deleted');
        return true;
      }
      print('[API] Delete all users failed: ${response.body}');
      return false;
    } catch (e) {
      print('[API] DeleteAllUsers error: $e');
      return false;
    }
  }

  /// Convert JSON to User model
  static User _jsonToUser(Map<String, dynamic> json) {
    return User.fromJson(json);
  }
}
