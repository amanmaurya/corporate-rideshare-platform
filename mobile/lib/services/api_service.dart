import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class ApiService {
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  static Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);

    final headers = Map<String, String>.from(_headers);
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  static Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      final error = json.decode(response.body);
      throw Exception(error['detail'] ?? 'Unknown error occurred');
    }
  }

  static Future<List<dynamic>> _handleListResponse(http.Response response) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = json.decode(response.body);
      if (data is List) {
        return data;
      } else if (data is Map && data.containsKey('items')) {
        return data['items'] ?? [];
      } else {
        return [];
      }
    } else {
      final error = json.decode(response.body);
      throw Exception(error['detail'] ?? 'Unknown error occurred');
    }
  }

  // Auth endpoints
  static Future<Map<String, dynamic>> login(String email, String password, String companyId) async {
    final response = await http.post(
      Uri.parse('${AppConstants.authEndpoint}/login'),
      headers: _headers,
      body: json.encode({
        'email': email,
        'password': password,
        'company_id': companyId,
      }),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    final response = await http.post(
      Uri.parse('${AppConstants.authEndpoint}/register'),
      headers: _headers,
      body: json.encode(userData),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await http.get(
      Uri.parse('${AppConstants.authEndpoint}/me'),
      headers: await _getAuthHeaders(),
    );

    return _handleResponse(response);
  }

  // Ride endpoints
  static Future<Map<String, dynamic>> createRide(Map<String, dynamic> rideData) async {
    final response = await http.post(
      Uri.parse('${AppConstants.ridesEndpoint}/'),
      headers: await _getAuthHeaders(),
      body: json.encode(rideData),
    );

    return _handleResponse(response);
  }

  static Future<List<dynamic>> getRides({String? status}) async {
    String url = '${AppConstants.ridesEndpoint}/';
    if (status != null) {
      url += '?status=$status';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: await _getAuthHeaders(),
    );

    return await _handleListResponse(response);
  }

  static Future<List<dynamic>> getMyRides() async {
    final response = await http.get(
      Uri.parse('${AppConstants.ridesEndpoint}/my-rides'),
      headers: await _getAuthHeaders(),
    );

    return await _handleListResponse(response);
  }

  static Future<Map<String, dynamic>> getRide(String rideId) async {
    final response = await http.get(
      Uri.parse('${AppConstants.ridesEndpoint}/$rideId'),
      headers: await _getAuthHeaders(),
    );

    return _handleResponse(response);
  }

  static Future<List<dynamic>> getRideMatches(String rideId) async {
    final response = await http.get(
      Uri.parse('${AppConstants.ridesEndpoint}/$rideId/matches'),
      headers: await _getAuthHeaders(),
    );

    return await _handleListResponse(response);
  }

  static Future<Map<String, dynamic>> requestRide(String rideId, {String? message}) async {
    final response = await http.post(
      Uri.parse('${AppConstants.ridesEndpoint}/$rideId/request'),
      headers: await _getAuthHeaders(),
      body: json.encode({
        'ride_id': rideId,
        'message': message,
      }),
    );

    return _handleResponse(response);
  }

  static Future<void> deleteRide(String rideId) async {
    final response = await http.delete(
      Uri.parse('${AppConstants.ridesEndpoint}/$rideId'),
      headers: await _getAuthHeaders(),
    );

    if (response.statusCode >= 400) {
      final error = json.decode(response.body);
      throw Exception(error['detail'] ?? 'Failed to delete ride');
    }
  }
}
