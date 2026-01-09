import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/course.dart';

abstract class CourseRepository {
  Future<List<Course>> getCourses();
  Future<Course?> getCourseById(String id);
  // These are user-centric, ideally handled by user provider + data manipulation, 
  // keeping them here for compatibility but implementation might vary.
  Future<void> enrollInCourse(String courseId);
  Future<void> removeFromWishlist(String courseId);
}

class ApiCourseRepository implements CourseRepository {
  static const String _baseUrl = 'http://localhost:3000/api';

  @override
  Future<List<Course>> getCourses() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/courses'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> list = data['courses'];
        return list.map((json) {
           // Ensure enum names match
           return Course.fromJson(json);
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error getting courses: $e');
      return [];
    }
  }

  @override
  Future<Course?> getCourseById(String id) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/courses/$id'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Course.fromJson(data['course']);
      }
      return null;
    } catch (e) {
      print('Error getting course by id: $e');
      return null;
    }
  }

  @override
  Future<void> enrollInCourse(String courseId) async {
    // This requires user context or an endpoint that knows the current user via token/session.
    // Since we don't have global auth header injection setup in a simple way here yet,
    // we might need to handle this in the provider or assume a specific endpoint.
    // For now, this is a placeholder or could throw.
    // But to avoid breaking the app, we'll do nothing.
    print('ApiCourseRepository.enrollInCourse: Not implemented at repo level, use UserProvider');
  }

  @override
  Future<void> removeFromWishlist(String courseId) async {
    print('ApiCourseRepository.removeFromWishlist: Not implemented at repo level');
  }
  
  Future<List<Course>> getEnrolledCourses() async {
      return []; // Logic moved to provider
  }

  Future<List<Course>> getWishlistCourses() async {
      return []; // Logic moved to provider
  }
    
  Stream<List<Course>> watchCourses() {
    // Fallback for stream providers if we don't switch to future provider immediately
    return Stream.fromFuture(getCourses()); 
  }
}