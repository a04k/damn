class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  
  const AppException(
    this.message, {
    this.code,
    this.originalError,
  });
  
  @override
  String toString() => 'AppException: $message';
}

class NetworkException extends AppException {
  const NetworkException(
    super.message, {
    super.code,
    super.originalError,
  });
}

class DataException extends AppException {
  const DataException(
    super.message, {
    super.code,
    super.originalError,
  });
}

class AuthException extends AppException {
  const AuthException(
    super.message, {
    super.code,
    super.originalError,
  });
}

class CacheException extends AppException {
  const CacheException(
    super.message, {
    super.code,
    super.originalError,
  });
}

class NotFoundException extends AppException {
  const NotFoundException(
    super.message, {
    super.code,
    super.originalError,
  });
}

class ValidationException extends AppException {
  const ValidationException(
    super.message, {
    super.code,
    super.originalError,
  });
}