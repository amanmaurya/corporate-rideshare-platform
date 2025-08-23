import 'package:flutter/foundation.dart';

class AppConfig {
  static const String _devApiUrl = 'http://localhost:8000';
  static const String _prodApiUrl = 'https://api.corporate-rideshare.com';
  static const String _stagingApiUrl = 'https://staging-api.corporate-rideshare.com';
  
  static const String _devWebSocketUrl = 'ws://localhost:8000';
  static const String _prodWebSocketUrl = 'wss://api.corporate-rideshare.com';
  static const String _stagingWebSocketUrl = 'wss://staging-api.corporate-rideshare.com';
  
  static const String _appVersion = '1.0.0';
  static const String _buildNumber = '1';
  
  static late String _apiBaseUrl;
  static late String _webSocketBaseUrl;
  static late bool _isProduction;
  static late bool _isStaging;
  static late bool _isDevelopment;
  
  // Getters
  static String get apiBaseUrl => _apiBaseUrl;
  static String get webSocketBaseUrl => _webSocketBaseUrl;
  static bool get isProduction => _isProduction;
  static bool get isStaging => _isStaging;
  static bool get isDevelopment => _isDevelopment;
  static String get appVersion => _appVersion;
  static String get buildNumber => _buildNumber;
  
  // Environment detection
  static bool get isDebug => kDebugMode;
  static bool get isRelease => kReleaseMode;
  static bool get isProfile => kProfileMode;
  
  // Feature flags
  static bool get enableWebSocket => true;
  static bool get enablePushNotifications => false; // TODO: Enable when FCM is integrated
  static bool get enableAnalytics => true;
  static bool get enableCrashReporting => false; // TODO: Enable when crash reporting is integrated
  
  // API configuration
  static int get apiTimeoutSeconds => 30;
  static int get maxRetryAttempts => 3;
  static bool get enableApiCaching => true;
  
  // WebSocket configuration
  static int get webSocketReconnectDelay => 5; // seconds
  static int get webSocketHeartbeatInterval => 30; // seconds
  static int get webSocketMaxReconnectAttempts => 5;
  
  // Payment configuration
  static bool get enablePayments => true;
  static String get defaultCurrency => 'USD';
  static double get maxPaymentAmount => 1000.0;
  
  // Location configuration
  static double get defaultLocationAccuracy => 10.0; // meters
  static int get locationUpdateInterval => 30; // seconds
  static double get maxSearchRadius => 10.0; // kilometers
  
  // Ride configuration
  static int get maxPassengers => 6;
  static int get maxRideDuration => 120; // minutes
  static double get maxRideDistance => 100.0; // kilometers
  
  // Notification configuration
  static bool get enableInAppNotifications => true;
  static bool get enableEmailNotifications => false; // TODO: Enable when email service is integrated
  static int get notificationRetentionDays => 30;
  
  // Security configuration
  static bool get enableBiometricAuth => false; // TODO: Enable when biometric auth is implemented
  static bool get enableCertificatePinning => false; // TODO: Enable in production
  static int get sessionTimeoutMinutes => 60;
  
  // Logging configuration
  static bool get enableDebugLogging => isDebug;
  static bool get enableApiLogging => isDebug;
  static bool get enableWebSocketLogging => isDebug;
  
  /// Initialize app configuration based on environment
  static Future<void> initialize() async {
    // Determine environment
    if (kReleaseMode) {
      // Production build
      _isProduction = true;
      _isStaging = false;
      _isDevelopment = false;
      _apiBaseUrl = _prodApiUrl;
      _webSocketBaseUrl = _prodWebSocketUrl;
    } else if (kDebugMode) {
      // Debug/Development build
      _isProduction = false;
      _isStaging = false;
      _isDevelopment = true;
      _apiBaseUrl = _devApiUrl;
      _webSocketBaseUrl = _devWebSocketUrl;
    } else {
      // Profile/Staging build
      _isProduction = false;
      _isStaging = true;
      _isDevelopment = false;
      _apiBaseUrl = _stagingApiUrl;
      _webSocketBaseUrl = _stagingWebSocketUrl;
    }
    
    // Log configuration
    if (enableDebugLogging) {
      print('🚀 App Config Initialized:');
      print('   Environment: ${_getEnvironmentString()}');
      print('   API Base URL: $_apiBaseUrl');
      print('   WebSocket URL: $_webSocketBaseUrl');
      print('   App Version: $_appVersion');
      print('   Build Number: $_buildNumber');
      print('   Debug Mode: $isDebug');
      print('   Release Mode: $isRelease');
    }
  }
  
  /// Get environment string for display
  static String _getEnvironmentString() {
    if (_isProduction) return 'Production';
    if (_isStaging) return 'Staging';
    if (_isDevelopment) return 'Development';
    return 'Unknown';
  }
  
  /// Get configuration summary for debugging
  static Map<String, dynamic> getConfigSummary() {
    return {
      'environment': _getEnvironmentString(),
      'apiBaseUrl': _apiBaseUrl,
      'webSocketBaseUrl': _webSocketBaseUrl,
      'appVersion': _appVersion,
      'buildNumber': _buildNumber,
      'isDebug': isDebug,
      'isRelease': isRelease,
      'isProduction': _isProduction,
      'isStaging': _isStaging,
      'isDevelopment': _isDevelopment,
      'features': {
        'webSocket': enableWebSocket,
        'pushNotifications': enablePushNotifications,
        'analytics': enableAnalytics,
        'payments': enablePayments,
        'biometricAuth': enableBiometricAuth,
      },
      'api': {
        'timeoutSeconds': apiTimeoutSeconds,
        'maxRetryAttempts': maxRetryAttempts,
        'enableCaching': enableApiCaching,
      },
      'webSocket': {
        'reconnectDelay': webSocketReconnectDelay,
        'heartbeatInterval': webSocketHeartbeatInterval,
        'maxReconnectAttempts': webSocketMaxReconnectAttempts,
      },
    };
  }
  
  /// Check if a feature is enabled
  static bool isFeatureEnabled(String featureName) {
    switch (featureName.toLowerCase()) {
      case 'websocket':
        return enableWebSocket;
      case 'pushnotifications':
        return enablePushNotifications;
      case 'analytics':
        return enableAnalytics;
      case 'payments':
        return enablePayments;
      case 'biometricauth':
        return enableBiometricAuth;
      case 'emailnotifications':
        return enableEmailNotifications;
      default:
        return false;
    }
  }
  
  /// Get API endpoint URL
  static String getApiEndpoint(String endpoint) {
    return '$_apiBaseUrl/api/v1/$endpoint';
  }
  
  /// Get WebSocket endpoint URL
  static String getWebSocketEndpoint(String endpoint) {
    return '$_webSocketBaseUrl/api/v1/websocket/$endpoint';
  }
}
