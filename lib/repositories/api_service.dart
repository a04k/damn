import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';

/// API Configuration
class ApiConfig {
  static const String baseUrl = 'http://localhost:3000/api';
  static String? _authToken;

  static void setAuthToken(String? token) {
    _authToken = token;
  }

  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };
}

/// Main API Service for the new backend
class ApiService {
  static const String _baseUrl = ApiConfig.baseUrl;

  // ============ AUTH ============

  static Future<ApiResponse<AuthData>> login(String email, String password, {String? fcmToken}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          if (fcmToken != null) 'fcmToken': fcmToken,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        final token = data['token'];
        ApiConfig.setAuthToken(token);
        return ApiResponse.success(AuthData(
          user: _parseUser(data['user']),
          token: token,
        ));
      }
      return ApiResponse.error(data['error']?['message'] ?? 'Login failed');
    } catch (e) {
      return ApiResponse.error('Connection error: $e');
    }
  }

  static Future<ApiResponse<AuthData>> register(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 201 && data['success'] == true) {
        final token = data['token'];
        ApiConfig.setAuthToken(token);
        return ApiResponse.success(AuthData(
          user: _parseUser(data['user']),
          token: token,
        ));
      }
      return ApiResponse.error(data['error']?['message'] ?? 'Registration failed');
    } catch (e) {
      return ApiResponse.error('Connection error: $e');
    }
  }

  static Future<ApiResponse<void>> verifyEmail(String email, String code) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'code': code}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return ApiResponse.success(null);
      }
      return ApiResponse.error(data['error']?['message'] ?? 'Verification failed');
    } catch (e) {
      return ApiResponse.error('Connection error: $e');
    }
  }

  static Future<ApiResponse<void>> resendCode(String email, {String type = 'REGISTRATION'}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/resend-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'type': type}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return ApiResponse.success(null);
      }
      return ApiResponse.error(data['error']?['message'] ?? 'Failed to send code');
    } catch (e) {
      return ApiResponse.error('Connection error: $e');
    }
  }

  static Future<ApiResponse<void>> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        return ApiResponse.success(null);
      }
      return ApiResponse.error('Failed to send reset code');
    } catch (e) {
      return ApiResponse.error('Connection error: $e');
    }
  }

  static Future<ApiResponse<void>> resetPassword(String email, String code, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'code': code,
          'newPassword': newPassword,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return ApiResponse.success(null);
      }
      return ApiResponse.error(data['error']?['message'] ?? 'Reset failed');
    } catch (e) {
      return ApiResponse.error('Connection error: $e');
    }
  }

  static Future<ApiResponse<User>> getCurrentUser() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/auth/me'),
        headers: ApiConfig.headers,
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return ApiResponse.success(_parseUser(data['user']));
      }
      return ApiResponse.error('Failed to get user');
    } catch (e) {
      return ApiResponse.error('Connection error: $e');
    }
  }

  static Future<ApiResponse<void>> updateFcmToken(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/fcm-token'),
        headers: ApiConfig.headers,
        body: jsonEncode({'fcmToken': token}),
      );

      if (response.statusCode == 200) {
        return ApiResponse.success(null);
      }
      return ApiResponse.error('Failed to update FCM token');
    } catch (e) {
      return ApiResponse.error('Connection error: $e');
    }
  }

  // ============ USER ============

  static Future<ApiResponse<User>> updateUser(User user) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/users/${Uri.encodeComponent(user.email)}'),
        headers: ApiConfig.headers,
        body: jsonEncode({
          'name': user.name,
          'avatar': user.avatar,
          'major': user.major,
          'department': user.department,
          'gpa': user.gpa,
          'level': user.level,
          'isOnboardingComplete': user.isOnboardingComplete,
          'enrolledCourses': user.enrolledCourses,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return ApiResponse.success(_parseUser(data['user']));
      }
      return ApiResponse.error('Failed to update user');
    } catch (e) {
      return ApiResponse.error('Connection error: $e');
    }
  }

  static Future<ApiResponse<User>> completeOnboarding(List<String> courseIds) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/users/complete-onboarding'),
        headers: ApiConfig.headers,
        body: jsonEncode({'enrolledCourses': courseIds}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return ApiResponse.success(_parseUser(data['user']));
      }
      return ApiResponse.error('Failed to complete onboarding');
    } catch (e) {
      return ApiResponse.error('Connection error: $e');
    }
  }

  // ============ COURSES ============

  static Future<ApiResponse<List<Map<String, dynamic>>>> getCourses({String? category, String? search}) async {
    try {
      final params = <String, String>{};
      if (category != null) params['category'] = category;
      if (search != null) params['search'] = search;

      final uri = Uri.parse('$_baseUrl/courses').replace(queryParameters: params.isEmpty ? null : params);
      final response = await http.get(uri, headers: ApiConfig.headers);

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return ApiResponse.success(List<Map<String, dynamic>>.from(data['courses']));
      }
      return ApiResponse.error('Failed to get courses');
    } catch (e) {
      return ApiResponse.error('Connection error: $e');
    }
  }

  static Future<ApiResponse<Map<String, dynamic>>> getCourse(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/courses/$id'),
        headers: ApiConfig.headers,
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return ApiResponse.success(data['course']);
      }
      return ApiResponse.error('Course not found');
    } catch (e) {
      return ApiResponse.error('Connection error: $e');
    }
  }

  static Future<ApiResponse<List<Map<String, dynamic>>>> getProfessorCourses(String email) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/courses/professor/${Uri.encodeComponent(email)}'),
        headers: ApiConfig.headers,
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return ApiResponse.success(List<Map<String, dynamic>>.from(data['courses']));
      }
      return ApiResponse.error('Failed to get courses');
    } catch (e) {
      return ApiResponse.error('Connection error: $e');
    }
  }

  static Future<ApiResponse<void>> enrollInCourse(String courseId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/courses/$courseId/enroll'),
        headers: ApiConfig.headers,
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return ApiResponse.success(null);
      }
      return ApiResponse.error(data['error']?['message'] ?? 'Enrollment failed');
    } catch (e) {
      return ApiResponse.error('Connection error: $e');
    }
  }

  // ============ CONTENT ============

  static Future<ApiResponse<Map<String, dynamic>>> createContent({
    required String courseId,
    required String title,
    required String contentType,
    String? description,
    String? fileUrl,
    int? weekNumber,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/content'),
        headers: ApiConfig.headers,
        body: jsonEncode({
          'courseId': courseId,
          'title': title,
          'contentType': contentType,
          'description': description,
          'fileUrl': fileUrl,
          'weekNumber': weekNumber,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 201 && data['success'] == true) {
        return ApiResponse.success(data['content']);
      }
      return ApiResponse.error(data['error']?['message'] ?? 'Failed to create content');
    } catch (e) {
      return ApiResponse.error('Connection error: $e');
    }
  }

  static Future<ApiResponse<Map<String, dynamic>>> createAssignment({
    required String courseId,
    required String title,
    required DateTime dueDate,
    String? description,
    int points = 100,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/content/assignment'),
        headers: ApiConfig.headers,
        body: jsonEncode({
          'courseId': courseId,
          'title': title,
          'description': description,
          'dueDate': dueDate.toIso8601String(),
          'points': points,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 201 && data['success'] == true) {
        return ApiResponse.success(data['task']);
      }
      return ApiResponse.error(data['error']?['message'] ?? 'Failed to create assignment');
    } catch (e) {
      return ApiResponse.error('Connection error: $e');
    }
  }

  static Future<ApiResponse<Map<String, dynamic>>> createExam({
    required String courseId,
    required String title,
    required DateTime examDate,
    String? description,
    int points = 100,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/content/exam'),
        headers: ApiConfig.headers,
        body: jsonEncode({
          'courseId': courseId,
          'title': title,
          'description': description,
          'examDate': examDate.toIso8601String(),
          'points': points,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 201 && data['success'] == true) {
        return ApiResponse.success(data['task']);
      }
      return ApiResponse.error(data['error']?['message'] ?? 'Failed to create exam');
    } catch (e) {
      return ApiResponse.error('Connection error: $e');
    }
  }

  // ============ TASKS ============

  static Future<ApiResponse<List<Map<String, dynamic>>>> getTasks({bool? upcoming}) async {
    try {
      final params = upcoming == true ? {'upcoming': 'true'} : null;
      final uri = Uri.parse('$_baseUrl/tasks').replace(queryParameters: params);
      final response = await http.get(uri, headers: ApiConfig.headers);

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return ApiResponse.success(List<Map<String, dynamic>>.from(data['tasks']));
      }
      return ApiResponse.error('Failed to get tasks');
    } catch (e) {
      return ApiResponse.error('Connection error: $e');
    }
  }

  static Future<ApiResponse<List<Map<String, dynamic>>>> getPendingTasks() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/tasks/pending'),
        headers: ApiConfig.headers,
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return ApiResponse.success(List<Map<String, dynamic>>.from(data['tasks']));
      }
      return ApiResponse.error('Failed to get pending tasks');
    } catch (e) {
      return ApiResponse.error('Connection error: $e');
    }
  }

  static Future<ApiResponse<void>> completeTask(String taskId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/tasks/$taskId/complete'),
        headers: ApiConfig.headers,
      );

      if (response.statusCode == 200) {
        return ApiResponse.success(null);
      }
      return ApiResponse.error('Failed to complete task');
    } catch (e) {
      return ApiResponse.error('Connection error: $e');
    }
  }

  // ============ ANNOUNCEMENTS ============

  static Future<ApiResponse<List<Map<String, dynamic>>>> getAnnouncements({String? courseId}) async {
    try {
      final params = courseId != null ? {'courseId': courseId} : null;
      final uri = Uri.parse('$_baseUrl/announcements').replace(queryParameters: params);
      final response = await http.get(uri, headers: ApiConfig.headers);

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return ApiResponse.success(List<Map<String, dynamic>>.from(data['announcements']));
      }
      return ApiResponse.error('Failed to get announcements');
    } catch (e) {
      return ApiResponse.error('Connection error: $e');
    }
  }

  static Future<ApiResponse<Map<String, dynamic>>> createAnnouncement({
    required String title,
    required String message,
    String? courseId,
    String type = 'GENERAL',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/announcements'),
        headers: ApiConfig.headers,
        body: jsonEncode({
          'title': title,
          'message': message,
          'courseId': courseId,
          'type': type,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 201 && data['success'] == true) {
        return ApiResponse.success(data['announcement']);
      }
      return ApiResponse.error(data['error']?['message'] ?? 'Failed to create announcement');
    } catch (e) {
      return ApiResponse.error('Connection error: $e');
    }
  }

  // ============ NOTIFICATIONS ============

  static Future<ApiResponse<NotificationData>> getNotifications({bool unreadOnly = false}) async {
    try {
      final params = unreadOnly ? {'unreadOnly': 'true'} : null;
      final uri = Uri.parse('$_baseUrl/notifications').replace(queryParameters: params);
      final response = await http.get(uri, headers: ApiConfig.headers);

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return ApiResponse.success(NotificationData(
          notifications: List<Map<String, dynamic>>.from(data['notifications']),
          unreadCount: data['unreadCount'] ?? 0,
        ));
      }
      return ApiResponse.error('Failed to get notifications');
    } catch (e) {
      return ApiResponse.error('Connection error: $e');
    }
  }

  static Future<ApiResponse<void>> markNotificationRead(String id) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/notifications/$id/read'),
        headers: ApiConfig.headers,
      );

      if (response.statusCode == 200) {
        return ApiResponse.success(null);
      }
      return ApiResponse.error('Failed to mark as read');
    } catch (e) {
      return ApiResponse.error('Connection error: $e');
    }
  }

  static Future<ApiResponse<void>> markAllNotificationsRead() async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/notifications/read-all'),
        headers: ApiConfig.headers,
      );

      if (response.statusCode == 200) {
        return ApiResponse.success(null);
      }
      return ApiResponse.error('Failed to mark all as read');
    } catch (e) {
      return ApiResponse.error('Connection error: $e');
    }
  }

  // ============ SCHEDULE ============

  static Future<ApiResponse<List<Map<String, dynamic>>>> getSchedule() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/schedule'),
        headers: ApiConfig.headers,
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return ApiResponse.success(List<Map<String, dynamic>>.from(data['events']));
      }
      return ApiResponse.error('Failed to get schedule');
    } catch (e) {
      return ApiResponse.error('Connection error: $e');
    }
  }

  // ============ HELPERS ============

  static User _parseUser(Map<String, dynamic> json) {
    return User.fromJson(json);
  }
}

/// API Response wrapper
class ApiResponse<T> {
  final bool isSuccess;
  final T? data;
  final String? error;

  ApiResponse._({required this.isSuccess, this.data, this.error});

  factory ApiResponse.success(T data) => ApiResponse._(isSuccess: true, data: data);
  factory ApiResponse.error(String message) => ApiResponse._(isSuccess: false, error: message);

  R fold<R>(R Function(T data) onSuccess, R Function(String error) onError) {
    if (isSuccess && data != null) {
      return onSuccess(data as T);
    }
    return onError(error ?? 'Unknown error');
  }
}

/// Auth data wrapper
class AuthData {
  final User user;
  final String token;

  AuthData({required this.user, required this.token});
}

/// Notification data wrapper
class NotificationData {
  final List<Map<String, dynamic>> notifications;
  final int unreadCount;

  NotificationData({required this.notifications, required this.unreadCount});
}
