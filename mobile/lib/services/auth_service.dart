import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../utils/constants.dart';
import 'api_service.dart';

class AuthService {
  static User? _currentUser;
  static String? _token;

  static User? get currentUser => _currentUser;
  static String? get token => _token;
  static bool get isAuthenticated => _token != null && _currentUser != null;

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(AppConstants.tokenKey);

    final userJson = prefs.getString(AppConstants.userKey);
    if (userJson != null) {
      try {
        final userData = json.decode(userJson);
        _currentUser = User.fromJson(userData);
      } catch (e) {
        // Invalid user data, clear it
        await logout();
      }
    }
  }

  static Future<User> login(String email, String password, String companyId) async {
    try {
      final response = await ApiService.login(email, password, companyId);

      _token = response['access_token'];
      _currentUser = User.fromJson(response['user']);

      // Save to local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.tokenKey, _token!);
      await prefs.setString(AppConstants.userKey, json.encode(_currentUser!.toJson()));

      return _currentUser!;
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  static Future<User> register({
    required String name,
    required String email,
    required String phone,
    required String department,
    required String role,
    required String companyId,
    required String password,
    bool isDriver = false,
  }) async {
    try {
      final userData = {
        'name': name,
        'email': email,
        'phone': phone,
        'department': department,
        'role': role,
        'company_id': companyId,
        'password': password,
        'is_driver': isDriver,
      };

      final response = await ApiService.register(userData);
      return User.fromJson(response);
    } catch (e) {
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  static Future<void> logout() async {
    _token = null;
    _currentUser = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.userKey);
  }

  static Future<User> refreshUser() async {
    try {
      final response = await ApiService.getCurrentUser();
      _currentUser = User.fromJson(response);

      // Update local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.userKey, json.encode(_currentUser!.toJson()));

      return _currentUser!;
    } catch (e) {
      throw Exception('Failed to refresh user data: ${e.toString()}');
    }
  }
}
