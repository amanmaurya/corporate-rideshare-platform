class WebSocketMessage {
  final String type;
  final Map<String, dynamic> data;
  final String? timestamp;
  final String? status;
  final String? message;

  WebSocketMessage({
    required this.type,
    required this.data,
    this.timestamp,
    this.status,
    this.message,
  });

  factory WebSocketMessage.fromJson(Map<String, dynamic> json) {
    return WebSocketMessage(
      type: json['type'] ?? '',
      data: json['data'] ?? {},
      timestamp: json['timestamp'],
      status: json['status'],
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'data': data,
      if (timestamp != null) 'timestamp': timestamp,
      if (status != null) 'status': status,
      if (message != null) 'message': message,
    };
  }

  @override
  String toString() {
    return 'WebSocketMessage(type: $type, data: $data, timestamp: $timestamp)';
  }
}

// Specific message types
class LocationUpdateMessage extends WebSocketMessage {
  final double latitude;
  final double longitude;
  final String companyId;
  final bool isDriver;
  final bool isAvailable;

  LocationUpdateMessage({
    required this.latitude,
    required this.longitude,
    required this.companyId,
    this.isDriver = false,
    this.isAvailable = true,
  }) : super(
    type: 'location_update',
    data: {
      'latitude': latitude,
      'longitude': longitude,
      'company_id': companyId,
      'is_driver': isDriver,
      'is_available': isAvailable,
    },
  );
}

class RideRequestMessage extends WebSocketMessage {
  final String rideId;
  final Map<String, dynamic> rideData;

  RideRequestMessage({
    required this.rideId,
    required this.rideData,
  }) : super(
    type: 'ride_request',
    data: {
      'ride_id': rideId,
      ...rideData,
    },
  );
}

class RideResponseMessage extends WebSocketMessage {
  final String rideId;
  final String response; // 'accept' or 'decline'
  final String? message;
  final String? driverName;
  final String? estimatedArrival;

  RideResponseMessage({
    required this.rideId,
    required this.response,
    this.message,
    this.driverName,
    this.estimatedArrival,
  }) : super(
    type: 'ride_response',
    data: {
      'ride_id': rideId,
      'response': response,
      if (message != null) 'message': message,
      if (driverName != null) 'driver_name': driverName,
      if (estimatedArrival != null) 'estimated_arrival': estimatedArrival,
    },
  );
}

class DriverStatusMessage extends WebSocketMessage {
  final bool isAvailable;
  final String? reason;

  DriverStatusMessage({
    required this.isAvailable,
    this.reason,
  }) : super(
    type: 'driver_status',
    data: {
      'is_available': isAvailable,
      if (reason != null) 'reason': reason,
    },
  );
}
