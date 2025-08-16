class Ride {
  final String id;
  final String companyId;
  final String riderId;
  final String? driverId;
  final String pickupLocation;
  final String destination;
  final double pickupLatitude;
  final double pickupLongitude;
  final double destinationLatitude;
  final double destinationLongitude;
  final DateTime? scheduledTime;
  final DateTime? actualStartTime;
  final DateTime? actualEndTime;
  final String status;
  final double? fare;
  final double? distance;
  final int? duration;
  final int maxPassengers;
  final int currentPassengers;
  final String? notes;
  final DateTime createdAt;

  Ride({
    required this.id,
    required this.companyId,
    required this.riderId,
    this.driverId,
    required this.pickupLocation,
    required this.destination,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.destinationLatitude,
    required this.destinationLongitude,
    this.scheduledTime,
    this.actualStartTime,
    this.actualEndTime,
    required this.status,
    this.fare,
    this.distance,
    this.duration,
    this.maxPassengers = 4,
    this.currentPassengers = 1,
    this.notes,
    required this.createdAt,
  });

  factory Ride.fromJson(Map<String, dynamic> json) {
    return Ride(
      id: json['id'],
      companyId: json['company_id'],
      riderId: json['rider_id'],
      driverId: json['driver_id'],
      pickupLocation: json['pickup_location'],
      destination: json['destination'],
      pickupLatitude: json['pickup_latitude'].toDouble(),
      pickupLongitude: json['pickup_longitude'].toDouble(),
      destinationLatitude: json['destination_latitude'].toDouble(),
      destinationLongitude: json['destination_longitude'].toDouble(),
      scheduledTime: json['scheduled_time'] != null 
          ? DateTime.parse(json['scheduled_time']) 
          : null,
      actualStartTime: json['actual_start_time'] != null 
          ? DateTime.parse(json['actual_start_time']) 
          : null,
      actualEndTime: json['actual_end_time'] != null 
          ? DateTime.parse(json['actual_end_time']) 
          : null,
      status: json['status'],
      fare: json['fare']?.toDouble(),
      distance: json['distance']?.toDouble(),
      duration: json['duration'],
      maxPassengers: json['max_passengers'] ?? 4,
      currentPassengers: json['current_passengers'] ?? 1,
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
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
  }
}

class RideRequest {
  final String id;
  final String rideId;
  final String userId;
  final String status;
  final String? message;
  final DateTime createdAt;

  RideRequest({
    required this.id,
    required this.rideId,
    required this.userId,
    required this.status,
    this.message,
    required this.createdAt,
  });

  factory RideRequest.fromJson(Map<String, dynamic> json) {
    return RideRequest(
      id: json['id'],
      rideId: json['ride_id'],
      userId: json['user_id'],
      status: json['status'],
      message: json['message'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
