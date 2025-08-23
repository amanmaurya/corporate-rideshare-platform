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

  static Future<Map<String, dynamic>> acceptRideRequest(String rideId, String requestId) async {
    final response = await http.post(
      Uri.parse('${AppConstants.ridesEndpoint}/$rideId/accept'),
      headers: await _getAuthHeaders(),
      body: json.encode({
        'request_id': requestId,
      }),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> rejectRideRequest(String rideId, String requestId) async {
    final response = await http.post(
      Uri.parse('${AppConstants.ridesEndpoint}/$rideId/reject'),
      headers: await _getAuthHeaders(),
      body: json.encode({
        'request_id': requestId,
      }),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> rejectPassengerRequest(String rideId, String requestId) async {
    final response = await http.post(
      Uri.parse('${AppConstants.ridesEndpoint}/$rideId/reject-passenger'),
      headers: await _getAuthHeaders(),
      body: json.encode({
        'request_id': requestId,
      }),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> acceptPassengerRequest(String rideId, String requestId) async {
    final response = await http.post(
      Uri.parse('${AppConstants.ridesEndpoint}/$rideId/accept-passenger'),
      headers: await _getAuthHeaders(),
      body: json.encode({
        'request_id': requestId,
      }),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> startRide(String rideId) async {
    final response = await http.post(
      Uri.parse('${AppConstants.ridesEndpoint}/$rideId/start'),
      headers: await _getAuthHeaders(),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> completeRide(String rideId) async {
    final response = await http.post(
      Uri.parse('${AppConstants.ridesEndpoint}/$rideId/complete'),
      headers: await _getAuthHeaders(),
    );

    return _handleResponse(response);
  }

  static Future<List<dynamic>> getRideRequests(String rideId) async {
    final response = await http.get(
      Uri.parse('${AppConstants.ridesEndpoint}/$rideId/requests'),
      headers: await _getAuthHeaders(),
    );

    return await _handleListResponse(response);
  }

  static Future<Map<String, dynamic>?> getMyRideRequest(String rideId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.ridesEndpoint}/$rideId/my-request'),
        headers: await _getAuthHeaders(),
      );

      // Check status code FIRST, before calling _handleResponse
      if (response.statusCode == 404) {
        return null;  // User has no request for this ride
      }

      // Only call _handleResponse for successful responses
      return _handleResponse(response);
    } catch (e) {
      // Handle any other errors
      if (e.toString().contains('You have not requested this ride') || 
          e.toString().contains('404')) {
        return null;
      }
      rethrow;
    }
  }

  static Future<List<dynamic>> getUserRideRequests() async {
    final response = await http.get(
      Uri.parse('${AppConstants.ridesEndpoint}/user/my-requests'),
      headers: await _getAuthHeaders(),
    );

    return await _handleListResponse(response);
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

  // Company endpoints
  static Future<List<dynamic>> getCompanies() async {
    final response = await http.get(
      Uri.parse('${AppConstants.companiesEndpoint}/'),
      headers: await _getAuthHeaders(),
    );

    return await _handleListResponse(response);
  }

  static Future<Map<String, dynamic>> getCompany(String companyId) async {
    final response = await http.get(
      Uri.parse('${AppConstants.companiesEndpoint}/$companyId'),
      headers: await _getAuthHeaders(),
    );

    return _handleResponse(response);
  }

  // User endpoints
  static Future<Map<String, dynamic>> updateUser(String userId, Map<String, dynamic> userData) async {
    final response = await http.put(
      Uri.parse('${AppConstants.usersEndpoint}/$userId'),
      headers: await _getAuthHeaders(),
      body: json.encode(userData),
    );

    return _handleResponse(response);
  }

  static Future<void> deleteUser(String userId) async {
    final response = await http.delete(
      Uri.parse('${AppConstants.usersEndpoint}/$userId'),
      headers: await _getAuthHeaders(),
    );

    if (response.statusCode >= 400) {
      final error = json.decode(response.body);
      throw Exception(error['detail'] ?? 'Failed to delete user');
    }
  }

  // Driver management
  static Future<Map<String, dynamic>> registerAsDriver(Map<String, dynamic> driverData) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.usersEndpoint}/register-driver'),
        headers: await _getAuthHeaders(),
        body: json.encode(driverData),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to register as driver: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> offerToDriveRide(String rideId) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.ridesEndpoint}/$rideId/offer-driving'),
        headers: await _getAuthHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to offer to drive ride: ${e.toString()}');
    }
  }

  static Future<void> cancelRideRequest(String requestId) async {
    try {
      final response = await http.delete(
        Uri.parse('${AppConstants.ridesEndpoint}/requests/$requestId'),
        headers: await _getAuthHeaders(),
      );
      
      if (response.statusCode >= 400) {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Failed to cancel ride request');
      }
    } catch (e) {
      throw Exception('Failed to cancel ride request: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> assignDriverToRide(String rideId, String driverId) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.ridesEndpoint}/$rideId/assign-driver'),
        headers: await _getAuthHeaders(),
        body: json.encode({'driver_id': driverId}),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to assign driver to ride: ${e.toString()}');
    }
  }
}


