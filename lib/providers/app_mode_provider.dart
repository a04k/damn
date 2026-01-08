import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import 'app_session_provider.dart';

/// App mode controller - manages student/professor mode
final appModeControllerProvider = StateNotifierProvider<AppModeController, AppMode>((ref) {
  return AppModeController(ref);
});

class AppModeController extends StateNotifier<AppMode> {
  final Ref _ref;

  AppModeController(this._ref) : super(AppMode.student) {
    _loadCurrentMode();
  }

  void _loadCurrentMode() {
    final userAsync = _ref.read(currentUserProvider);
    final user = userAsync.valueOrNull;
    if (user != null) {
      state = user.mode;
    }
  }

  Future<void> switchMode(AppMode mode) async {
    state = mode;
    
    final sessionState = _ref.read(appSessionControllerProvider);
    if (sessionState is AppSessionAuthenticated) {
      final updatedUser = sessionState.user.copyWith(mode: mode);
      await _ref.read(appSessionControllerProvider.notifier).updateUser(updatedUser);
    }
  }

  bool isProfessorMode() => state == AppMode.professor;

  bool isStudentMode() => state == AppMode.student;
}

/// Simple provider to check if user is professor
final isProfessorProvider = Provider<bool>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  final user = userAsync.valueOrNull;
  return user?.mode == AppMode.professor;
});