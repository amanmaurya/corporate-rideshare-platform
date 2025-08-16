import 'package:flutter/foundation.dart';

class AppNotification {
  final String id;
  final String type;
  final String title;
  final String message;
  final Map<String, dynamic> data;
  final String priority;
  final DateTime timestamp;
  final bool read;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.data = const {},
    this.priority = 'normal',
    required this.timestamp,
    this.read = false,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      data: json['data'] ?? {},
      priority: json['priority'] ?? 'normal',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      read: json['read'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'message': message,
      'data': data,
      'priority': priority,
      'timestamp': timestamp.toIso8601String(),
      'read': read,
    };
  }

  AppNotification copyWith({
    String? id,
    String? type,
    String? title,
    String? message,
    Map<String, dynamic>? data,
    String? priority,
    DateTime? timestamp,
    bool? read,
  }) {
    return AppNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      data: data ?? this.data,
      priority: priority ?? this.priority,
      timestamp: timestamp ?? this.timestamp,
      read: read ?? this.read,
    );
  }

  @override
  String toString() {
    return 'AppNotification(id: $id, type: $type, title: $title, read: $read)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppNotification && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // Helper methods
  bool get isHighPriority => priority == 'high' || priority == 'urgent';
  bool get isUrgent => priority == 'urgent';
  
  // Get specific data fields
  String? get rideId => data['ride_id'];
  String? get driverId => data['driver_id'];
  String? get driverName => data['driver_name'];
  String? get estimatedArrival => data['estimated_arrival'];
  
  // Check if notification is ride-related
  bool get isRideRelated => type.startsWith('ride_') || type == 'driver_arriving';
  
  // Get notification icon based on type
  String get icon {
    switch (type) {
      case 'ride_request':
        return '🚗';
      case 'ride_accepted':
        return '✅';
      case 'ride_declined':
        return '❌';
      case 'ride_started':
        return '🚀';
      case 'ride_completed':
        return '🎉';
      case 'driver_arriving':
        return '📍';
      case 'location_update':
        return '📍';
      case 'payment_received':
        return '💰';
      case 'ride_cancelled':
        return '🚫';
      default:
        return '📱';
    }
  }
  
  // Get notification color based on priority
  String get priorityColor {
    switch (priority) {
      case 'urgent':
        return '#FF0000'; // Red
      case 'high':
        return '#FF6B35'; // Orange
      case 'normal':
        return '#2196F3'; // Blue
      case 'low':
        return '#4CAF50'; // Green
      default:
        return '#2196F3'; // Blue
    }
  }
  
  // Get formatted timestamp
  String get formattedTimestamp {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
