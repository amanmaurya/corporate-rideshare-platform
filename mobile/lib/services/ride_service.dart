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
      final errorMessage = e.toString();
      
      // Handle specific error cases
      if (errorMessage.contains('already requested')) {
        throw Exception('You have already requested to join this ride');
      } else if (errorMessage.contains('Ride is full')) {
        throw Exception('This ride is already full');
      } else if (errorMessage.contains('Ride not found')) {
        throw Exception('Ride not found or no longer available');
      } else {
        throw Exception('Failed to request ride: ${errorMessage}');
      }
    }
  }

  static Future<void> deleteRide(String rideId) async {
    try {
      await ApiService.deleteRide(rideId);
    } catch (e) {
      throw Exception('Failed to delete ride: ${e.toString()}');
    }
  }

  static Future<List<RideRequest>> getRideRequests(String rideId) async {
    try {
      final response = await ApiService.getRideRequests(rideId);
      return response.map((json) => RideRequest.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get ride requests: ${e.toString()}');
    }
  }

  static Future<RideRequest?> getMyRideRequest(String rideId) async {
    try {
      final response = await ApiService.getMyRideRequest(rideId);
      if (response == null) return null;
      return RideRequest.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get my ride request: ${e.toString()}');
    }
  }

  static Future<List<RideRequest>> getUserRideRequests() async {
    try {
      final response = await ApiService.getUserRideRequests();
      return response.map((json) => RideRequest.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get user ride requests: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> acceptRideRequest(String rideId, String requestId) async {
    try {
      final response = await ApiService.acceptRideRequest(rideId, requestId);
      return response;
    } catch (e) {
      throw Exception('Failed to accept ride request: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> rejectRideRequest(String rideId, String requestId) async {
    try {
      final response = await ApiService.rejectRideRequest(rideId, requestId);
      return response;
    } catch (e) {
      throw Exception('Failed to reject ride request: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> rejectPassengerRequest(String rideId, String requestId) async {
    try {
      final response = await ApiService.rejectPassengerRequest(rideId, requestId);
      return response;
    } catch (e) {
      throw Exception('Failed to reject passenger request: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> acceptPassengerRequest(String rideId, String requestId) async {
    try {
      final response = await ApiService.acceptPassengerRequest(rideId, requestId);
      return response;
    } catch (e) {
      throw Exception('Failed to accept passenger request: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> offerToDriveRide(String rideId) async {
    try {
      final response = await ApiService.offerToDriveRide(rideId);
      return response;
    } catch (e) {
      throw Exception('Failed to offer to drive ride: ${e.toString()}');
    }
  }

  static Future<void> cancelRideRequest(String requestId) async {
    try {
      await ApiService.cancelRideRequest(requestId);
    } catch (e) {
      throw Exception('Failed to cancel ride request: ${e.toString()}');
    }
  }
}
