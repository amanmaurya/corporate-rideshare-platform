import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../config/app_config.dart';

class AppConstants {
  // API Configuration - Uses AppConfig for easy environment switching
  static String get baseUrl {
    return AppConfig.apiBaseUrl;
  }
  
  static const String apiVersion = 'v1';
  static String get apiBaseUrl => '$baseUrl/api/$apiVersion';

  // Endpoints
  static String get authEndpoint => '$apiBaseUrl/auth';
  static String get ridesEndpoint => '$apiBaseUrl/rides';
  static String get companiesEndpoint => '$apiBaseUrl/companies';
  static String get usersEndpoint => '$apiBaseUrl/users';

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String companyKey = 'company_data';

  // Map Configuration
  static const double defaultLatitude = 37.7749;
  static const double defaultLongitude = -122.4194;
  static const double defaultZoom = 14.0;

  // App Configuration
  static const int maxPassengers = 6;
  static const double maxSearchRadius = 10.0; // km
  static const int requestTimeoutSeconds = 30;
  
  // Debug info
  static String get debugInfo => 'Platform: ${kIsWeb ? 'Web' : Platform.operatingSystem}, API: $baseUrl';
}

class AppColors {
  static const primaryColor = Color(0xFF2196F3);
  static const primaryDarkColor = Color(0xFF1976D2);
  static const accentColor = Color(0xFF03DAC6);
  static const backgroundColor = Color(0xFFF5F5F5);
  static const surfaceColor = Color(0xFFFFFFFF);
  static const errorColor = Color(0xFFB00020);
  static const successColor = Color(0xFF4CAF50);
  static const warningColor = Color(0xFFFF9800);
  static const textPrimaryColor = Color(0xFF212121);
  static const textSecondaryColor = Color(0xFF757575);
  static const info = Color(0xFF2196F3);
}
