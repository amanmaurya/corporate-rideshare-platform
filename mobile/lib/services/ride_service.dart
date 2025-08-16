import '../models/ride.dart';
import '../services/api_service.dart';

class RideService {
  static Future<Ride> createRide({
    required String pickupLocation,
    required String destination,
    required double pickupLatitude,
    required double pickupLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
    DateTime? scheduledTime,
    String? notes,
    int maxPassengers = 4,
  }) async {
    try {
      final rideData = {
        'pickup_location': pickupLocation,
        'destination': destination,
        'pickup_latitude': pickupLatitude,
        'pickup_longitude': pickupLongitude,
        'destination_latitude': destinationLatitude,
        'destination_longitude': destinationLongitude,
        'scheduled_time': scheduledTime?.toIso8601String(),
        'notes': notes,
        'max_passengers': maxPassengers,
      };

      final response = await ApiService.createRide(rideData);
      return Ride.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create ride: ${e.toString()}');
    }
  }

  static Future<List<Ride>> getRides({String? status}) async {
    try {
      final response = await ApiService.getRides(status: status);
      return response.map((json) => Ride.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get rides: ${e.toString()}');
    }
  }

  static Future<List<Ride>> getMyRides() async {
    try {
      final response = await ApiService.getMyRides();
      return response.map((json) => Ride.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get my rides: ${e.toString()}');
    }
  }

  static Future<Ride> getRide(String rideId) async {
    try {
      final response = await ApiService.getRide(rideId);
      return Ride.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get ride: ${e.toString()}');
    }
  }

  static Future<List<Map<String, dynamic>>> getRideMatches(String rideId) async {
    try {
      final response = await ApiService.getRideMatches(rideId);
      return response.cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to get ride matches: ${e.toString()}');
    }
  }

  static Future<RideRequest> requestRide(String rideId, {String? message}) async {
    try {
      final response = await ApiService.requestRide(rideId, message: message);
      return RideRequest.fromJson(response);
    } catch (e) {
      throw Exception('Failed to request ride: ${e.toString()}');
    }
  }

  static Future<void> deleteRide(String rideId) async {
    try {
      await ApiService.deleteRide(rideId);
    } catch (e) {
      throw Exception('Failed to delete ride: ${e.toString()}');
    }
  }
}
