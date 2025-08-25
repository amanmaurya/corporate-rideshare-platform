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
    required int vehicleCapacity,
    DateTime? scheduledTime,
    String? notes,
    double? fare,
  }) async {
    try {
      final rideData = {
        'pickup_location': pickupLocation,
        'destination': destination,
        'pickup_latitude': pickupLatitude,
        'pickup_longitude': pickupLongitude,
        'destination_latitude': destinationLatitude,
        'destination_longitude': destinationLongitude,
        'vehicle_capacity': vehicleCapacity,
        'scheduled_time': scheduledTime?.toIso8601String(),
        'notes': notes,
        'fare': fare,
      };

      final response = await ApiService.createRide(rideData);
      return Ride.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create ride: ${e.toString()}');
    }
  }

  static Future<List<Ride>> getAvailableRides() async {
    try {
      final response = await ApiService.getRides();
      return response.map((json) => Ride.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get available rides: ${e.toString()}');
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

  static Future<RideRequest> requestRide(String rideId, {String? message}) async {
    try {
      final response = await ApiService.requestRide(rideId, message: message);
      return RideRequest.fromJson(response);
    } catch (e) {
      final errorMessage = e.toString();
      
      // Handle specific error cases
      if (errorMessage.contains('already requested')) {
        throw Exception('You have already requested to join this ride');
      } else if (errorMessage.contains('full')) {
        throw Exception('This ride is already full');
      } else if (errorMessage.contains('not found')) {
        throw Exception('Ride not found or no longer available');
      } else if (errorMessage.contains('not available')) {
        throw Exception('Ride is not available for requests');
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

  // Ride lifecycle management
  static Future<Ride> startRide(String rideId) async {
    try {
      final response = await ApiService.startRide(rideId);
      return Ride.fromJson(response);
    } catch (e) {
      throw Exception('Failed to start ride: ${e.toString()}');
    }
  }

  static Future<Ride> updateRideProgress(
    String rideId, {
    double? currentLatitude,
    double? currentLongitude,
    double? rideProgress,
    DateTime? estimatedPickupTime,
    DateTime? estimatedDropoffTime,
  }) async {
    try {
      final response = await ApiService.updateRideProgress(
        rideId,
        currentLatitude: currentLatitude,
        currentLongitude: currentLongitude,
        rideProgress: rideProgress,
        estimatedPickupTime: estimatedPickupTime,
        estimatedDropoffTime: estimatedDropoffTime,
      );
      return Ride.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update ride progress: ${e.toString()}');
    }
  }

  static Future<Ride> pickupPassenger(String rideId) async {
    try {
      final response = await ApiService.pickupPassenger(rideId);
      return Ride.fromJson(response);
    } catch (e) {
      throw Exception('Failed to pickup passenger: ${e.toString()}');
    }
  }

  static Future<Ride> completeRide(String rideId) async {
    try {
      final response = await ApiService.completeRide(rideId);
      return Ride.fromJson(response);
    } catch (e) {
      throw Exception('Failed to complete ride: ${e.toString()}');
    }
  }

  static Future<Ride> cancelRide(String rideId) async {
    try {
      final response = await ApiService.cancelRide(rideId);
      return Ride.fromJson(response);
    } catch (e) {
      throw Exception('Failed to cancel ride: ${e.toString()}');
    }
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
    try {
      await ApiService.updateRideLocation(
        rideId,
        latitude,
        longitude,
        accuracy,
        speed,
        heading,
        isDriver,
      );
    } catch (e) {
      throw Exception('Failed to update ride location: ${e.toString()}');
    }
  }

  static Future<List<Map<String, dynamic>>> getRideLocations(String rideId) async {
    try {
      final response = await ApiService.getRideLocations(rideId);
      return response.cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to get ride locations: ${e.toString()}');
    }
  }

  // Request management
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

  static Future<void> cancelRideRequest(String requestId) async {
    try {
      await ApiService.cancelRideRequest(requestId);
    } catch (e) {
      throw Exception('Failed to cancel ride request: ${e.toString()}');
    }
  }

  // Dashboard endpoints
  static Future<Map<String, dynamic>> getDriverDashboard() async {
    try {
      final response = await ApiService.getDriverDashboard();
      return response;
    } catch (e) {
      throw Exception('Failed to get driver dashboard: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> getEmployeeDashboard() async {
    try {
      final response = await ApiService.getEmployeeDashboard();
      return response;
    } catch (e) {
      throw Exception('Failed to get employee dashboard: ${e.toString()}');
    }
  }

  // Payment and rating
  static Future<Ride> updatePaymentStatus(
    String rideId,
    String paymentStatus, {
    String? paymentMethod,
    double? fare,
  }) async {
    try {
      final response = await ApiService.updatePaymentStatus(
        rideId,
        paymentStatus,
        paymentMethod: paymentMethod,
        fare: fare,
      );
      return Ride.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update payment status: ${e.toString()}');
    }
  }

  static Future<Ride> rateRide(String rideId, double rating, String feedback) async {
    try {
      final response = await ApiService.rateRide(rideId, rating, feedback);
      return Ride.fromJson(response);
    } catch (e) {
      throw Exception('Failed to rate ride: ${e.toString()}');
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
}
