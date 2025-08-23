import '../models/ride.dart';
import '../models/payment.dart';
import '../services/api_service.dart';
import '../services/payment_service.dart';
import '../services/websocket_service.dart';

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
      final ride = Ride.fromJson(response);
      
      // Send real-time update via WebSocket
      try {
        await WebSocketService.instance.updateRideStatus(
          rideId: ride.id,
          status: 'created',
          additionalData: {
            'pickup_location': pickupLocation,
            'destination': destination,
            'max_passengers': maxPassengers,
          },
        );
      } catch (e) {
        print('WebSocket update failed: $e');
      }
      
      return ride;
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
      final rideRequest = RideRequest.fromJson(response);
      
      // Send real-time update via WebSocket
      try {
        await WebSocketService.instance.updateRideStatus(
          rideId: rideId,
          status: 'requested',
          additionalData: {
            'user_id': rideRequest.userId,
            'message': message,
          },
        );
      } catch (e) {
        print('WebSocket update failed: $e');
      }
      
      return rideRequest;
    } catch (e) {
      throw Exception('Failed to request ride: ${e.toString()}');
    }
  }

  static Future<void> deleteRide(String rideId) async {
    try {
      await ApiService.deleteRide(rideId);
      
      // Send real-time update via WebSocket
      try {
        await WebSocketService.instance.updateRideStatus(
          rideId: rideId,
          status: 'deleted',
        );
      } catch (e) {
        print('WebSocket update failed: $e');
      }
    } catch (e) {
      throw Exception('Failed to delete ride: ${e.toString()}');
    }
  }

  /// Start a ride and update status
  static Future<void> startRide(String rideId) async {
    try {
      // Update ride status via API
      await ApiService.updateRide(rideId, {'status': 'in_progress'});
      
      // Send real-time update via WebSocket
      try {
        await WebSocketService.instance.updateRideStatus(
          rideId: rideId,
          status: 'in_progress',
          additionalData: {
            'actual_start_time': DateTime.now().toIso8601String(),
          },
        );
      } catch (e) {
        print('WebSocket update failed: $e');
      }
    } catch (e) {
      throw Exception('Failed to start ride: ${e.toString()}');
    }
  }

  /// Complete a ride and process payment
  static Future<Payment> completeRide(String rideId) async {
    try {
      // Update ride status via API
      await ApiService.updateRide(rideId, {'status': 'completed'});
      
      // Send real-time update via WebSocket
      try {
        await WebSocketService.instance.updateRideStatus(
          rideId: rideId,
          status: 'completed',
          additionalData: {
            'actual_end_time': DateTime.now().toIso8601String(),
          },
        );
      } catch (e) {
        print('WebSocket update failed: $e');
      }
      
      // Process payment for completed ride
      final payment = await PaymentService.processRidePayment(rideId: rideId);
      return payment;
      
    } catch (e) {
      throw Exception('Failed to complete ride: ${e.toString()}');
    }
  }

  /// Update ride location during active ride
  static Future<void> updateRideLocation({
    required String rideId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      // Update location via API
      await ApiService.updateRideLocation(rideId, latitude, longitude);
      
      // Send real-time location update via WebSocket
      try {
        await WebSocketService.instance.updateLocation(
          rideId: rideId,
          latitude: latitude,
          longitude: longitude,
        );
      } catch (e) {
        print('WebSocket location update failed: $e');
      }
      
    } catch (e) {
      throw Exception('Failed to update ride location: ${e.toString()}');
    }
  }

  /// Get estimated fare for a ride
  static Future<FareCalculation> getEstimatedFare({
    required double distanceKm,
    required int durationMinutes,
  }) async {
    try {
      return await PaymentService.calculateFare(
        distanceKm: distanceKm,
        durationMinutes: durationMinutes,
      );
    } catch (e) {
      throw Exception('Failed to calculate fare: ${e.toString()}');
    }
  }

  /// Get payment history for rides
  static Future<List<PaymentHistory>> getRidePaymentHistory() async {
    try {
      return await PaymentService.getPaymentHistory();
    } catch (e) {
      throw Exception('Failed to get payment history: ${e.toString()}');
    }
  }
}
