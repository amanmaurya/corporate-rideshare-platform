import 'dart:convert';
import '../models/ride.dart';
import '../utils/constants.dart';
import 'api_service.dart';
import 'websocket_service.dart';
import 'notification_service.dart';

class EnhancedRideService {
  static EnhancedRideService? _instance;
  
  // Singleton pattern
  static EnhancedRideService get instance {
    _instance ??= EnhancedRideService._internal();
    return _instance!;
  }
  
  EnhancedRideService._internal();
  
  /// Find nearby drivers
  Future<List<Map<String, dynamic>>> findNearbyDrivers({
    double? latitude,
    double? longitude,
    double radiusKm = 5.0,
  }) async {
    try {
      String url = '/rides/nearby/drivers?radius_km=$radiusKm';
      
      if (latitude != null && longitude != null) {
        url += '&latitude=$latitude&longitude=$longitude';
      }
      
      final response = await ApiService.get(url);
      return List<Map<String, dynamic>>.from(response['nearby_drivers'] ?? []);
    } catch (e) {
      print('❌ Failed to find nearby drivers: $e');
      return [];
    }
  }
  
  /// Start a ride
  Future<bool> startRide(String rideId) async {
    try {
      final response = await ApiService.post('/rides/$rideId/start', {});
      return response['message'] == 'Ride started successfully';
    } catch (e) {
      print('❌ Failed to start ride: $e');
      return false;
    }
  }
  
  /// Complete a ride
  Future<Map<String, dynamic>?> completeRide(String rideId) async {
    try {
      final response = await ApiService.post('/rides/$rideId/complete', {});
      return response['message'] == 'Ride completed successfully' ? response : null;
    } catch (e) {
      print('❌ Failed to complete ride: $e');
      return null;
    }
  }
  
  /// Accept a ride request
  Future<bool> acceptRideRequest(String rideId, String requestId) async {
    try {
      final response = await ApiService.post('/rides/$rideId/accept', {
        'request_id': requestId,
      });
      
      if (response['message'] == 'Ride request accepted') {
        await WebSocketService.instance.sendRideResponse(
          rideId: rideId,
          response: 'accept',
          driverName: 'You',
          estimatedArrival: '5 minutes',
        );
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Failed to accept ride request: $e');
      return false;
    }
  }
  
  /// Update ride location
  Future<bool> updateRideLocation(String rideId, double latitude, double longitude) async {
    try {
      final response = await ApiService.post('/rides/$rideId/update-location', {
        'latitude': latitude,
        'longitude': longitude,
      });
      
      if (response['message'] == 'Location updated successfully') {
        await WebSocketService.instance.updateLocation(
          latitude: latitude,
          longitude: longitude,
          companyId: 'company-1',
          isDriver: true,
        );
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Failed to update ride location: $e');
      return false;
    }
  }
  
  /// Send ride request via WebSocket
  Future<void> sendRideRequestViaWebSocket({
    required String rideId,
    required Map<String, dynamic> rideData,
  }) async {
    try {
      await WebSocketService.instance.sendRideRequest(
        rideId: rideId,
        rideData: rideData,
      );
    } catch (e) {
      print('❌ Failed to send ride request via WebSocket: $e');
    }
  }
  
  /// Get ride statistics
  Future<Map<String, dynamic>> getRideStatistics() async {
    try {
      final myRides = await ApiService.get('/rides/my-rides');
      final rides = List<Map<String, dynamic>>.from(myRides);
      
      int totalRides = rides.length;
      int completedRides = rides.where((r) => r['status'] == 'completed').length;
      int activeRides = rides.where((r) => r['status'] == 'in_progress').length;
      
      double totalFare = 0.0;
      double totalDistance = 0.0;
      
      for (final ride in rides) {
        if (ride['status'] == 'completed') {
          totalFare += (ride['actual_fare'] ?? 0.0);
          totalDistance += (ride['distance'] ?? 0.0);
        }
      }
      
      return {
        'total_rides': totalRides,
        'completed_rides': completedRides,
        'active_rides': activeRides,
        'total_fare': totalFare,
        'total_distance': totalDistance,
        'average_fare': completedRides > 0 ? totalFare / completedRides : 0.0,
      };
    } catch (e) {
      print('❌ Failed to get ride statistics: $e');
      return {};
    }
  }
  
  /// Set driver availability status
  Future<bool> setDriverAvailability(bool isAvailable, {String? reason}) async {
    try {
      await WebSocketService.instance.updateDriverStatus(
        isAvailable: isAvailable,
        reason: reason,
      );
      return true;
    } catch (e) {
      print('❌ Failed to set driver availability: $e');
      return false;
    }
  }
}
