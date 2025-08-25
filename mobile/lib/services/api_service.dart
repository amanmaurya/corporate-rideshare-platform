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
    final response = await http.get(
      Uri.parse('${AppConstants.ridesEndpoint}/'),
      headers: await _getAuthHeaders(),
    );

    return _handleListResponse(response);
  }

  static Future<List<dynamic>> getMyRides() async {
    final response = await http.get(
      Uri.parse('${AppConstants.ridesEndpoint}/my-rides'),
      headers: await _getAuthHeaders(),
    );

    return _handleListResponse(response);
  }

  static Future<Map<String, dynamic>> getRide(String rideId) async {
    final response = await http.get(
      Uri.parse('${AppConstants.ridesEndpoint}/$rideId'),
      headers: await _getAuthHeaders(),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> requestRide(String rideId, {String? message}) async {
    final body = <String, dynamic>{
      'ride_id': rideId,
    };

    if (message != null) body['message'] = message;

    final response = await http.post(
      Uri.parse('${AppConstants.ridesEndpoint}/$rideId/request'),
      headers: await _getAuthHeaders(),
      body: json.encode(body),
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

  static Future<List<dynamic>> getRideRequests(String rideId) async {
    final response = await http.get(
      Uri.parse('${AppConstants.ridesEndpoint}/$rideId/requests'),
      headers: await _getAuthHeaders(),
    );

    return _handleListResponse(response);
  }

  // Dashboard endpoints
  static Future<Map<String, dynamic>> getDriverDashboard() async {
    final response = await http.get(
      Uri.parse('${AppConstants.ridesEndpoint}/driver/dashboard'),
      headers: await _getAuthHeaders(),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getEmployeeDashboard() async {
    final response = await http.get(
      Uri.parse('${AppConstants.ridesEndpoint}/employee/dashboard'),
      headers: await _getAuthHeaders(),
    );

    return _handleResponse(response);
  }

  // Request management
  static Future<Map<String, dynamic>> acceptRideRequest(String rideId, String requestId) async {
    final body = {'request_id': requestId};

    final response = await http.post(
      Uri.parse('${AppConstants.ridesEndpoint}/$rideId/accept'),
      headers: await _getAuthHeaders(),
      body: json.encode(body),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> rejectRideRequest(String rideId, String requestId) async {
    final body = {'request_id': requestId};

    final response = await http.post(
      Uri.parse('${AppConstants.ridesEndpoint}/$rideId/reject'),
      headers: await _getAuthHeaders(),
      body: json.encode(body),
    );

    return _handleResponse(response);
  }

  static Future<void> cancelRideRequest(String requestId) async {
    final response = await http.delete(
      Uri.parse('${AppConstants.ridesEndpoint}/requests/$requestId'),
      headers: await _getAuthHeaders(),
    );
    
    if (response.statusCode >= 400) {
      final error = json.decode(response.body);
      throw Exception(error['detail'] ?? 'Failed to cancel ride request');
    }
  }

  // Ride lifecycle management
  static Future<Map<String, dynamic>> startRide(String rideId) async {
    final response = await http.post(
      Uri.parse('${AppConstants.ridesEndpoint}/$rideId/start'),
      headers: await _getAuthHeaders(),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateRideProgress(
    String rideId, {
    double? currentLatitude,
    double? currentLongitude,
    double? rideProgress,
    DateTime? estimatedPickupTime,
    DateTime? estimatedDropoffTime,
  }) async {
    final body = <String, dynamic>{
      'ride_id': rideId,
      'status': 'in_progress', // Required for status flow
    };

    if (currentLatitude != null) body['current_latitude'] = currentLatitude;
    if (currentLongitude != null) body['current_longitude'] = currentLongitude;
    if (rideProgress != null) body['ride_progress'] = rideProgress;
    if (estimatedPickupTime != null) body['estimated_pickup_time'] = estimatedPickupTime.toIso8601String();
    if (estimatedDropoffTime != null) body['estimated_dropoff_time'] = estimatedDropoffTime.toIso8601String();

    final response = await http.post(
      Uri.parse('${AppConstants.ridesEndpoint}/$rideId/update-progress'),
      headers: await _getAuthHeaders(),
      body: json.encode(body),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> pickupPassenger(String rideId) async {
    final response = await http.post(
      Uri.parse('${AppConstants.ridesEndpoint}/$rideId/pickup'),
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

  static Future<Map<String, dynamic>> cancelRide(String rideId) async {
    final response = await http.post(
      Uri.parse('${AppConstants.ridesEndpoint}/$rideId/cancel'),
      headers: await _getAuthHeaders(),
    );

    return _handleResponse(response);
  }

  static Future<void> updateRideLocation(
    String rideId,
    double latitude,
    double longitude,
    double accuracy,
    double speed,
    double heading,
    bool isDriver,
  ) async {
    final body = {
      'ride_id': rideId,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'speed': speed,
      'heading': heading,
      'is_driver': isDriver,
    };

    final response = await http.post(
      Uri.parse('${AppConstants.ridesEndpoint}/$rideId/location'),
      headers: await _getAuthHeaders(),
      body: json.encode(body),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = json.decode(response.body);
      throw Exception(error['detail'] ?? 'Failed to update location');
    }
  }

  static Future<List<dynamic>> getRideLocations(String rideId) async {
    final response = await http.get(
      Uri.parse('${AppConstants.ridesEndpoint}/$rideId/location'),
      headers: await _getAuthHeaders(),
    );

    return _handleListResponse(response);
  }

  static Future<Map<String, dynamic>> updatePaymentStatus(
    String rideId,
    String paymentStatus, {
    String? paymentMethod,
    double? fare,
  }) async {
    final body = <String, dynamic>{
      'ride_id': rideId,
      'payment_status': paymentStatus,
    };

    if (paymentMethod != null) body['payment_method'] = paymentMethod;
    if (fare != null) body['fare'] = fare;

    final response = await http.post(
      Uri.parse('${AppConstants.ridesEndpoint}/$rideId/payment'),
      headers: await _getAuthHeaders(),
      body: json.encode(body),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> rateRide(String rideId, double rating, String feedback) async {
    final body = {
      'ride_id': rideId,
      'rating': rating,
      'feedback': feedback,
    };

    final response = await http.post(
      Uri.parse('${AppConstants.ridesEndpoint}/$rideId/rate'),
      headers: await _getAuthHeaders(),
      body: json.encode(body),
    );

    return _handleResponse(response);
  }

  static Future<List<dynamic>> getUserRideRequests() async {
    final response = await http.get(
      Uri.parse('${AppConstants.ridesEndpoint}/user/my-requests'),
      headers: await _getAuthHeaders(),
    );

    return await _handleListResponse(response);
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


