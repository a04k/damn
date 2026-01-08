import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/result.dart';
import '../../core/exceptions.dart';
import '../../core/logger.dart';
import '../../core/api_config.dart';
import '../auth_repository.dart';
import '../../models/user.dart';
import '../../services/data_service.dart';

/// Auth Repository that uses the unified DataService
class MockAuthRepository implements AuthRepository {
  User? _currentUser;
  final StreamController<User?> _userController = StreamController<User?>.broadcast();
  static const String _userEmailKey = 'user_email';
  static const String _authTokenKey = 'auth_token';

  @override
  Future<Result<User>> login(String email, String password, {bool rememberMe = false}) async {
    try {
      AppLogger.auth('Login attempt for: $email');
      
      final user = await DataService.login(email, password);
      if (user == null) {
        return Result.failure(const AuthException('Invalid credentials', code: 'INVALID_CREDENTIALS'));
      }

      _currentUser = user;
      _userController.add(user);

      if (rememberMe) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userEmailKey, email);
        if (ApiConfig.authToken != null) {
          await prefs.setString(_authTokenKey, ApiConfig.authToken!);
        }
      }

      AppLogger.auth('Login successful for: $email');
      return Result.success(user);
    } catch (e) {
      AppLogger.auth('Login failed', error: e);
      return Result.failure(AuthException('Login failed', originalError: e));
    }
  }

  @override
  Future<Result<User>> register(String name, String email, String password, {bool rememberMe = false}) async {
    try {
      AppLogger.auth('Register attempt for: $email');
      
      final user = await DataService.register(name: name, email: email, password: password);
      
      if (user != null) {
        _currentUser = user;
        _userController.add(user);
        
        if (rememberMe) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_userEmailKey, email);
          if (ApiConfig.authToken != null) {
            await prefs.setString(_authTokenKey, ApiConfig.authToken!);
          }
        }
        
        AppLogger.auth('Registration successful for: $email');
        return Result.success(user);
      } else {
        return Result.failure(const DataException('Registration failed'));
      }
    } catch (e) {
      if (e.toString().contains('exists')) {
        return Result.failure(const AuthException('User already exists', code: 'EMAIL_EXISTS'));
      }
      AppLogger.auth('Registration failed', error: e);
      return Result.failure(AuthException('Registration failed', originalError: e));
    }
  }

  @override
  Future<Result<User?>> getCurrentUser() async {
    try {
      if (_currentUser != null) return Result.success(_currentUser);

      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString(_userEmailKey);
      final savedToken = prefs.getString(_authTokenKey);
      
      // Restore auth token
      if (savedToken != null) {
        ApiConfig.setAuthToken(savedToken);
      }
      
      if (email != null) {
        final user = await DataService.getUser(email);
        if (user != null) {
          _currentUser = user;
          _userController.add(user);
          return Result.success(user);
        }
      }
      return Result.success(null);
    } catch (e) {
      AppLogger.auth('Get current user failed', error: e);
      return Result.failure(CacheException('Failed to restore session', originalError: e));
    }
  }
  
  @override
  Future<Result<void>> logout() async {
    _currentUser = null;
    _userController.add(null);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userEmailKey);
    await prefs.remove(_authTokenKey);
    
    ApiConfig.clearAuth();
    
    AppLogger.auth('Logout successful');
    return Result.success(null);
  }

  @override
  Future<Result<User>> updateUser(User user) async {
    try {
      // For now, just update locally
      _currentUser = user;
      _userController.add(user);
      return Result.success(user);
    } catch (e) {
      AppLogger.auth('Update user failed', error: e);
      return Result.failure(DataException('Update failed', originalError: e));
    }
  }

  @override
  Future<Result<void>> changePassword(String current, String newPass) async {
    try {
      if (_currentUser == null) {
        return Result.failure(const AuthException('Not logged in'));
      }
      
      // Password change would need a dedicated endpoint
      AppLogger.auth('Password changed for: ${_currentUser!.email}');
      return Result.success(null);
    } catch (e) {
      return Result.failure(DataException('Error changing password', originalError: e));
    }
  }

  @override
  Future<Result<void>> forgotPassword(String email) async {
    // Would send email via API
    AppLogger.auth('Password reset requested for: $email');
    return Result.success(null);
  }

  @override
  Stream<User?> watchUser() {
    return _userController.stream;
  }
}