import 'dart:developer' as developer;

class AppLogger {
  static const String _tag = 'StudentDashboard';
  
  static void debug(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: tag ?? _tag,
      time: DateTime.now(),
      level: 500,
      error: error,
      stackTrace: stackTrace,
    );
  }
  
  static void info(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: tag ?? _tag,
      time: DateTime.now(),
      level: 800,
      error: error,
      stackTrace: stackTrace,
    );
  }
  
  static void warning(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: tag ?? _tag,
      time: DateTime.now(),
      level: 900,
      error: error,
      stackTrace: stackTrace,
    );
  }
  
  static void error(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: tag ?? _tag,
      time: DateTime.now(),
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }
  
  // Specialized logging methods
  static void repository(String message, {String? repository, dynamic error, StackTrace? stackTrace}) {
    debug(message, tag: 'Repo:$repository', error: error, stackTrace: stackTrace);
  }
  
  static void cache(String message, {String? operation, dynamic error, StackTrace? stackTrace}) {
    debug(message, tag: 'Cache:$operation', error: error, stackTrace: stackTrace);
  }
  
  static void api(String message, {String? endpoint, dynamic error, StackTrace? stackTrace}) {
    info(message, tag: 'API:$endpoint', error: error, stackTrace: stackTrace);
  }
  
  static void auth(String message, {dynamic error, StackTrace? stackTrace}) {
    info(message, tag: 'Auth', error: error, stackTrace: stackTrace);
  }
  
  static void ui(String message, {String? screen, dynamic error, StackTrace? stackTrace}) {
    debug(message, tag: 'UI:$screen', error: error, stackTrace: stackTrace);
  }
}