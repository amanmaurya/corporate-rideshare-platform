class Ride {
  final String id;
  final String companyId;
  final String driverId;  // Driver creates the ride
  final String pickupLocation;
  final String destination;
  final double pickupLatitude;
  final double pickupLongitude;
  final double destinationLatitude;
  final double destinationLongitude;
  final DateTime? scheduledTime;
  final DateTime? actualStartTime;
  final DateTime? actualEndTime;
  
  // Strict status flow: available → confirmed → in_progress → completed
  final String status;
  
  final double? fare;
  final double? distance;
  final int? duration;
  
  // Vehicle capacity management
  final int vehicleCapacity;  // Total seats in vehicle
  final int confirmedPassengers;  // Number of confirmed passengers
  
  final String? notes;
  final DateTime createdAt;
  
  // Driver information
  final String? driverName;
  final String? driverEmail;
  final String? driverPhone;
  final double? driverRating;
  
  // Ride progress tracking
  final double? currentLatitude;
  final double? currentLongitude;
  final DateTime? pickupTime;
  final DateTime? dropoffTime;
  final DateTime? estimatedPickupTime;
  final DateTime? estimatedDropoffTime;
  final double? rideProgress;
  
  // Payment and rating (only after completion)
  final String? paymentStatus;
  final String? paymentMethod;
  final double? rideRating;
  final String? rideFeedback;
  final String? routePolyline;

  Ride({
    required this.id,
    required this.companyId,
    required this.driverId,
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
    required this.vehicleCapacity,
    required this.confirmedPassengers,
    this.notes,
    required this.createdAt,
    this.driverName,
    this.driverEmail,
    this.driverPhone,
    this.driverRating,
    this.currentLatitude,
    this.currentLongitude,
    this.pickupTime,
    this.dropoffTime,
    this.estimatedPickupTime,
    this.estimatedDropoffTime,
    this.rideProgress,
    this.paymentStatus,
    this.paymentMethod,
    this.rideRating,
    this.rideFeedback,
    this.routePolyline,
  });

  factory Ride.fromJson(Map<String, dynamic> json) {
    return Ride(
      id: json['id'],
      companyId: json['company_id'],
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
      vehicleCapacity: json['vehicle_capacity'] ?? 4,
      confirmedPassengers: json['confirmed_passengers'] ?? 0,
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      driverName: json['driver_name'],
      driverEmail: json['driver_email'],
      driverPhone: json['driver_phone'],
      driverRating: json['driver_rating']?.toDouble(),
      currentLatitude: json['current_latitude']?.toDouble(),
      currentLongitude: json['current_longitude']?.toDouble(),
      pickupTime: json['pickup_time'] != null 
          ? DateTime.parse(json['pickup_time']) 
          : null,
      dropoffTime: json['dropoff_time'] != null 
          ? DateTime.parse(json['dropoff_time']) 
          : null,
      estimatedPickupTime: json['estimated_pickup_time'] != null 
          ? DateTime.parse(json['estimated_pickup_time']) 
          : null,
      estimatedDropoffTime: json['estimated_dropoff_time'] != null 
          ? DateTime.parse(json['estimated_dropoff_time']) 
          : null,
      rideProgress: json['ride_progress']?.toDouble(),
      paymentStatus: json['payment_status'],
      paymentMethod: json['payment_method'],
      rideRating: json['ride_rating']?.toDouble(),
      rideFeedback: json['ride_feedback'],
      routePolyline: json['route_polyline'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'driver_id': driverId,
      'pickup_location': pickupLocation,
      'destination': destination,
      'pickup_latitude': pickupLatitude,
      'pickup_longitude': pickupLongitude,
      'destination_latitude': destinationLatitude,
      'destination_longitude': destinationLongitude,
      'scheduled_time': scheduledTime?.toIso8601String(),
      'vehicle_capacity': vehicleCapacity,
      'notes': notes,
      'status': status,
      'fare': fare,
      'distance': distance,
      'duration': duration,
      'confirmed_passengers': confirmedPassengers,
      'actual_start_time': actualStartTime?.toIso8601String(),
      'actual_end_time': actualEndTime?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'driver_name': driverName,
      'driver_email': driverEmail,
      'driver_phone': driverPhone,
      'driver_rating': driverRating,
      'current_latitude': currentLatitude,
      'current_longitude': currentLongitude,
      'pickup_time': pickupTime?.toIso8601String(),
      'dropoff_time': dropoffTime?.toIso8601String(),
      'estimated_pickup_time': estimatedPickupTime?.toIso8601String(),
      'estimated_dropoff_time': estimatedDropoffTime?.toIso8601String(),
      'ride_progress': rideProgress,
      'payment_status': paymentStatus,
      'payment_method': paymentMethod,
      'ride_rating': rideRating,
      'ride_feedback': rideFeedback,
      'route_polyline': routePolyline,
    };
  }

  // Helper methods for status checks
  bool get isAvailable => status == 'available';
  bool get isConfirmed => status == 'confirmed';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  
  // Capacity helpers
  bool get hasAvailableSeats => confirmedPassengers < vehicleCapacity;
  int get availableSeats => vehicleCapacity - confirmedPassengers;
  
  // Status flow helpers
  bool get canStart => isConfirmed && confirmedPassengers > 0;
  bool get canComplete => isInProgress;
  bool get canCancel => !isCompleted && !isCancelled;
}

class RideRequest {
  final String id;
  final String rideId;
  final String userId;  // User requesting seat (could be driver or rider)
  final String status;  // pending, accepted, rejected, cancelled
  final String? message;
  final DateTime createdAt;
  final String? userName;  // Name of the user
  final String? userEmail;  // Email of the user

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
      'message': message,
      'created_at': createdAt.toIso8601String(),
      'user_name': userName,
      'user_email': userEmail,
    };
  }

  // Helper methods for status checks
  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
  bool get isCancelled => status == 'cancelled';
}
