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
  
  // Driver information
  final String? driverName;
  final String? driverEmail;
  final String? driverPhone;
  final double? driverRating;
  final bool? driverIsAvailable;
  
  // Driver offers
  final List<DriverOffer>? driverOffers;

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
    this.driverName,
    this.driverEmail,
    this.driverPhone,
    this.driverRating,
    this.driverIsAvailable,
    this.driverOffers,
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
      driverName: json['driver_name'],
      driverEmail: json['driver_email'],
      driverPhone: json['driver_phone'],
      driverRating: json['driver_rating']?.toDouble(),
      driverIsAvailable: json['driver_is_available'],
      driverOffers: json['driver_offers'] != null 
          ? (json['driver_offers'] as List)
              .map((offer) => DriverOffer.fromJson(offer))
              .toList()
          : null,
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
  final String? userName;
  final String? userEmail;

  RideRequest({
    required this.id,
    required this.rideId,
    required this.userId,
    required this.status,
    this.message,
    required this.createdAt,
    this.userName,
    this.userEmail,
  });

  factory RideRequest.fromJson(Map<String, dynamic> json) {
    return RideRequest(
      id: json['id'],
      rideId: json['ride_id'],
      userId: json['user_id'],
      status: json['status'],
      message: json['message'],
      createdAt: DateTime.parse(json['created_at']),
      userName: json['user_name'],
      userEmail: json['user_email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ride_id': rideId,
      'user_id': userId,
      'status': status,
      'message': message,
      'created_at': createdAt.toIso8601String(),
      'user_name': userName,
      'user_email': userEmail,
    };
  }
}

class DriverOffer {
  final String id;
  final String driverId;
  final String driverName;
  final String? driverEmail;
  final String? driverPhone;
  final double? driverRating;
  final String status; // pending, accepted, declined
  final String? message;
  final DateTime createdAt;

  DriverOffer({
    required this.id,
    required this.driverId,
    required this.driverName,
    this.driverEmail,
    this.driverPhone,
    this.driverRating,
    required this.status,
    this.message,
    required this.createdAt,
  });

  factory DriverOffer.fromJson(Map<String, dynamic> json) {
    return DriverOffer(
      id: json['id'],
      driverId: json['driver_id'],
      driverName: json['driver_name'],
      driverEmail: json['driver_email'],
      driverPhone: json['driver_phone'],
      driverRating: json['driver_rating']?.toDouble(),
      status: json['status'],
      message: json['message'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driver_id': driverId,
      'driver_name': driverName,
      'driver_email': driverEmail,
      'driver_phone': driverPhone,
      'driver_rating': driverRating,
      'status': status,
      'message': message,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
