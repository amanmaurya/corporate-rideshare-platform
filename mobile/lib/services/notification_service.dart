import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification.dart';
import '../utils/constants.dart';
import 'api_service.dart';

class NotificationService {
  static NotificationService? _instance;
  static List<AppNotification> _notifications = [];
  static String? _pushToken;
  
  // Singleton pattern
  static NotificationService get instance {
    _instance ??= NotificationService._internal();
    return _instance!;
  }
  
  NotificationService._internal();
  
  // Getters
  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  String? get pushToken => _pushToken;
  
  /// Initialize notification service
  Future<void> initialize() async {
    await _loadNotifications();
    await _loadPushToken();
  }
  
  /// Load notifications from local storage
  Future<void> _loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getStringList('notifications') ?? [];
      
      _notifications = notificationsJson
          .map((json) => AppNotification.fromJson(jsonDecode(json)))
          .toList();
          
    } catch (e) {
      print('❌ Failed to load notifications: $e');
      _notifications = [];
    }
  }
  
  /// Save notifications to local storage
  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = _notifications
          .map((notification) => jsonEncode(notification.toJson()))
          .toList();
      
      await prefs.setStringList('notifications', notificationsJson);
    } catch (e) {
      print('❌ Failed to save notifications: $e');
    }
  }
  
  /// Load push token from local storage
  Future<void> _loadPushToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _pushToken = prefs.getString('push_token');
    } catch (e) {
      print('❌ Failed to load push token: $e');
    }
  }
  
  /// Save push token to local storage
  Future<void> _savePushToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_pushToken != null) {
        await prefs.setString('push_token', _pushToken!);
      } else {
        await prefs.remove('push_token');
      }
    } catch (e) {
      print('❌ Failed to save push token: $e');
    }
  }
  
  /// Add a new notification
  Future<void> addNotification(AppNotification notification) async {
    _notifications.insert(0, notification); // Add to beginning
    
    // Keep only last 100 notifications
    if (_notifications.length > 100) {
      _notifications = _notifications.take(100).toList();
    }
    
    await _saveNotifications();
    
    // Trigger notification stream update
    _notificationController?.add(_notifications);
  }
  
  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(read: true);
      await _saveNotifications();
      _notificationController?.add(_notifications);
    }
  }
  
  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(read: true);
    }
    
    await _saveNotifications();
    _notificationController?.add(_notifications);
  }
  
  /// Remove notification
  Future<void> removeNotification(String notificationId) async {
    _notifications.removeWhere((n) => n.id == notificationId);
    await _saveNotifications();
    _notificationController?.add(_notifications);
  }
  
  /// Clear all notifications
  Future<void> clearAll() async {
    _notifications.clear();
    await _saveNotifications();
    _notificationController?.add(_notifications);
  }
  
  /// Get unread notifications count
  int get unreadCount => _notifications.where((n) => !n.read).length;
  
  /// Get notifications by type
  List<AppNotification> getNotificationsByType(String type) {
    return _notifications.where((n) => n.type == type).toList();
  }
  
  /// Register push notification token
  Future<bool> registerPushToken(String token) async {
    try {
      _pushToken = token;
      await _savePushToken();
      
      // Send token to backend
      // TODO: Implement notification creation
      // final response = await ApiService.post(
      //   '/notifications/register-push-token',
      //   {'token': token},
      // );
      
      // return response['status'] == 'success';
      return true; // Placeholder
    } catch (e) {
      print('❌ Failed to register push token: $e');
      return false;
    }
  }
  
  /// Unregister push notification token
  Future<bool> unregisterPushToken() async {
    try {
      if (_pushToken != null) {
        // Send unregister request to backend
        // TODO: Implement notification unregistration
      // await ApiService.delete('/notifications/unregister-push-token');
      }
      
      _pushToken = null;
      await _savePushToken();
      return true;
    } catch (e) {
      print('❌ Failed to unregister push token: $e');
      return false;
    }
  }
  
  /// Fetch notifications from backend
  Future<void> fetchNotifications({int limit = 50, bool unreadOnly = false}) async {
    try {
      // TODO: Implement notification retrieval
      // final response = await ApiService.get(
      //   '/notifications/?limit=$limit&unread_only=$unreadOnly',
      // );
      
      // TODO: Implement notification retrieval
      final List<dynamic> notificationsJson = []; // Placeholder
      final newNotifications = notificationsJson
          .map((json) => AppNotification.fromJson(json))
          .toList();
      
      // Merge with existing notifications
      for (final notification in newNotifications) {
        final existingIndex = _notifications.indexWhere((n) => n.id == notification.id);
        if (existingIndex != -1) {
          _notifications[existingIndex] = notification;
        } else {
          _notifications.add(notification);
        }
      }
      
      // Sort by timestamp (newest first)
      _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      await _saveNotifications();
      _notificationController?.add(_notifications);
      
    } catch (e) {
      print('❌ Failed to fetch notifications: $e');
    }
  }
  
  /// Get notification statistics
  Map<String, int> getStatistics() {
    final total = _notifications.length;
    final unread = _notifications.where((n) => !n.read).length;
    final read = total - unread;
    
    return {
      'total': total,
      'unread': unread,
      'read': read,
    };
  }
  
  // Stream controller for real-time updates
  static final StreamController<List<AppNotification>> _notificationController = 
      StreamController<List<AppNotification>>.broadcast();
  
  Stream<List<AppNotification>> get notificationStream => _notificationController.stream;
  
  /// Dispose resources
  void dispose() {
    _notificationController.close();
  }
}

// Notification types
class NotificationType {
  static const String rideRequest = 'ride_request';
  static const String rideAccepted = 'ride_accepted';
  static const String rideDeclined = 'ride_declined';
  static const String rideStarted = 'ride_started';
  static const String rideCompleted = 'ride_completed';
  static const String driverArriving = 'driver_arriving';
  static const String locationUpdate = 'location_update';
  static const String paymentReceived = 'payment_received';
  static const String rideCancelled = 'ride_cancelled';
}

// Notification priority
class NotificationPriority {
  static const String low = 'low';
  static const String normal = 'normal';
  static const String high = 'high';
  static const String urgent = 'urgent';
}
