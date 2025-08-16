// App Configuration - Easy to modify for different environments
class AppConfig {
  // ===== QUICK CONFIGURATION =====
  // Change this line to switch environments:
  static const String _currentEnvironment = 'local'; // Options: 'local', 'dev', 'staging', 'prod'
  
  // ===== ENVIRONMENT URLS =====
  static const Map<String, String> _apiUrls = {
    'local': 'http://localhost:8000',           // Your local development
    'dev': 'http://dev-api.yourcompany.com',    // Development server
    'staging': 'http://staging-api.yourcompany.com', // Staging server
    'prod': 'https://api.yourcompany.com',      // Production server
  };
  
  // ===== AUTO-DETECTION =====
  static String get apiBaseUrl {
    return _apiUrls[_currentEnvironment] ?? _apiUrls['local']!;
  }
  
  // ===== ENVIRONMENT INFO =====
  static String get currentEnvironment => _currentEnvironment;
  static bool get isLocal => _currentEnvironment == 'local';
  static bool get isDevelopment => _currentEnvironment == 'dev';
  static bool get isStaging => _currentEnvironment == 'staging';
  static bool get isProduction => _currentEnvironment == 'prod';
  
  // ===== DEBUG SETTINGS =====
  static bool get enableDebugLogs => isLocal || isDevelopment;
  static bool get enableVerboseLogs => isLocal;
  
  // ===== CONFIGURATION INFO =====
  static String get configInfo => '''
App Configuration:
- Environment: $currentEnvironment
- API URL: $apiBaseUrl
- Debug Logs: $enableDebugLogs
- Verbose Logs: $enableVerboseLogs
''';
}
