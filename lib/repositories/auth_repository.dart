import '../core/result.dart';
import '../models/user.dart';

abstract class AuthRepository {
  Future<Result<User>> login(String email, String password, {bool rememberMe = false});
  Future<Result<User>> register(String name, String email, String password, {bool rememberMe = false});
  Future<Result<void>> forgotPassword(String email);
  Future<Result<void>> logout();
  Future<Result<User?>> getCurrentUser();
  Future<Result<User>> updateUser(User user);
  Future<Result<void>> changePassword(String currentPassword, String newPassword);
  Stream<User?> watchUser();
}