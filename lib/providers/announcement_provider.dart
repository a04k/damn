import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/announcement.dart';
import '../services/data_service.dart';

/// Announcements provider using DataService
final announcementsProvider = FutureProvider<List<Announcement>>((ref) async {
  return DataService.getAnnouncements();
});

/// Announcement controller for actions
final announcementControllerProvider = StateNotifierProvider<AnnouncementController, AsyncValue<void>>((ref) {
  return AnnouncementController(ref);
});

class AnnouncementController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  AnnouncementController(this._ref) : super(const AsyncValue.data(null));

  Future<void> markAsRead(String id) async {
    state = const AsyncValue.loading();
    try {
      // Mark as read logic (to be implemented in API)
      _ref.invalidate(announcementsProvider);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> markAllAsRead() async {
    state = const AsyncValue.loading();
    try {
      // Mark all as read logic
      _ref.invalidate(announcementsProvider);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> createAnnouncement({
    required String title,
    required String message,
    String? courseId,
    String type = 'GENERAL',
  }) async {
    state = const AsyncValue.loading();
    try {
      final success = await DataService.createAnnouncement(
        title: title,
        message: message,
        courseId: courseId,
        type: type,
      );
      
      if (success) {
        _ref.invalidate(announcementsProvider);
      }
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}