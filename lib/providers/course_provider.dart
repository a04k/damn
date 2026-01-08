import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/course.dart';
import '../models/user.dart';
import '../services/data_service.dart';
import 'app_session_provider.dart';

/// All courses provider
final coursesProvider = FutureProvider<List<Course>>((ref) async {
  return DataService.getCourses();
});

/// Course by ID provider
final courseByIdProvider = FutureProvider.family<Course?, String>((ref, courseId) async {
  return DataService.getCourse(courseId);
});

/// Current user's enrolled courses
final enrolledCoursesProvider = FutureProvider<List<Course>>((ref) async {
  final userAsync = ref.watch(currentUserProvider);
  
  final user = userAsync.valueOrNull;
  if (user == null) return [];
  
  // Get all courses first
  final allCourses = await DataService.getCourses();
  
  // Filter by enrolled course IDs
  if (user.enrolledCourses.isEmpty) {
    // Try to fetch from API directly
    return DataService.getEnrolledCourses(user.id);
  }
  
  return allCourses.where((c) => user.enrolledCourses.contains(c.id)).toList();
});

/// Professor's assigned courses
final professorCoursesProvider = FutureProvider<List<Course>>((ref) async {
  final userAsync = ref.watch(currentUserProvider);
  
  final user = userAsync.valueOrNull;
  if (user == null || user.mode != AppMode.professor) return [];
  
  return DataService.getProfessorCourses(user.email);
});

/// Course enrollment controller
final courseControllerProvider = StateNotifierProvider<CourseController, AsyncValue<void>>((ref) {
  return CourseController(ref);
});

class CourseController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  CourseController(this._ref) : super(const AsyncValue.data(null));

  Future<void> enrollInCourse(String courseId) async {
    state = const AsyncValue.loading();
    try {
      final success = await DataService.enrollInCourse(courseId);
      if (success) {
        // Refresh enrolled courses
        _ref.invalidate(enrolledCoursesProvider);
      }
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> dropCourse(String courseId) async {
    state = const AsyncValue.loading();
    try {
      final success = await DataService.dropCourse(courseId);
      if (success) {
        _ref.invalidate(enrolledCoursesProvider);
      }
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> removeFromWishlist(String courseId) async {
    await dropCourse(courseId);
  }
}

/// Course filter state
final courseFilterProvider = StateProvider<CourseFilter>((ref) {
  return CourseFilter();
});

class CourseFilter {
  final EnrollmentStatus? enrollmentStatus;
  final CourseCategory? category;
  final String searchTerm;

  CourseFilter({
    this.enrollmentStatus,
    this.category,
    this.searchTerm = '',
  });

  CourseFilter copyWith({
    EnrollmentStatus? enrollmentStatus,
    CourseCategory? category,
    String? searchTerm,
  }) {
    return CourseFilter(
      enrollmentStatus: enrollmentStatus ?? this.enrollmentStatus,
      category: category ?? this.category,
      searchTerm: searchTerm ?? this.searchTerm,
    );
  }
}