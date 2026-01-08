/// API Configuration
/// Centralized configuration for API endpoints and headers
class ApiConfig {
  // Base URL - change this for different environments
  static const String baseUrl = 'http://localhost:3000/api';
  
  // For production, use:
  // static const String baseUrl = 'https://api.yourcollegeguide.com/api';
  
  // Auth token (set after login)
  static String? _authToken;
  
  /// Set the authentication token after login
  static void setAuthToken(String? token) {
    _authToken = token;
  }
  
  /// Get the authentication token
  static String? get authToken => _authToken;
  
  /// Check if user is authenticated
  static bool get isAuthenticated => _authToken != null && _authToken!.isNotEmpty;
  
  /// Clear auth token (logout)
  static void clearAuth() {
    _authToken = null;
  }
  
  /// Get headers with authorization
  static Map<String, String> get authHeaders => {
    'Content-Type': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };
  
  /// Get headers without authorization
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
  };
}
