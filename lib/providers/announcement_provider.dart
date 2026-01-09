import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/announcement.dart';
import '../services/data_service.dart';

import 'package:shared_preferences/shared_preferences.dart';

/// Announcements provider using DataService with local read status
final announcementsProvider = FutureProvider<List<Announcement>>((ref) async {
  final announcements = await DataService.getAnnouncements();
  final prefs = await SharedPreferences.getInstance();
  final readIds = prefs.getStringList('read_announcements') ?? [];
  
  return announcements.map((a) {
    if (readIds.contains(a.id)) {
      return a.copyWith(isRead: true);
    }
    return a;
  }).toList();
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
      final prefs = await SharedPreferences.getInstance();
      final readIds = prefs.getStringList('read_announcements') ?? [];
      
      if (!readIds.contains(id)) {
        readIds.add(id);
        await prefs.setStringList('read_announcements', readIds);
        _ref.invalidate(announcementsProvider);
      }
      
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> markAllAsRead() async {
    state = const AsyncValue.loading();
    try {
      final announcements = await _ref.read(announcementsProvider.future);
      final prefs = await SharedPreferences.getInstance();
      final readIds = prefs.getStringList('read_announcements') ?? [];
      
      bool changed = false;
      for (var a in announcements) {
        if (!readIds.contains(a.id)) {
          readIds.add(a.id);
          changed = true;
        }
      }
      
      if (changed) {
        await prefs.setStringList('read_announcements', readIds);
        _ref.invalidate(announcementsProvider);
      }
      
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