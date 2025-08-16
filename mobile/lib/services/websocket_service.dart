import 'dart:convert';
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import '../utils/constants.dart';
import '../models/websocket_message.dart';
import 'package:flutter/foundation.dart';

class WebSocketService {
  static WebSocketService? _instance;
  WebSocketChannel? _channel;
  StreamController<WebSocketMessage>? _messageController;
  Timer? _reconnectTimer;
  bool _isConnected = false;
  String? _currentUserId;
  
  // Singleton pattern
  static WebSocketService get instance {
    _instance ??= WebSocketService._internal();
    return _instance!;
  }
  
  WebSocketService._internal();
  
  // Getters
  bool get isConnected => _isConnected;
  Stream<WebSocketMessage>? get messageStream => _messageController?.stream;
  
  /// Connect to WebSocket server
  Future<void> connect(String userId) async {
    if (_isConnected && _currentUserId == userId) return;
    
    _currentUserId = userId;
    _disconnect(); // Close existing connection
    
    try {
      final wsUrl = AppConstants.baseUrl.replaceFirst('http', 'ws');
      final uri = Uri.parse('$wsUrl/api/v1/websocket/ws/$userId');
      
      _channel = WebSocketChannel.connect(uri);
      _messageController = StreamController<WebSocketMessage>.broadcast();
      
      // Listen for messages
      _channel!.stream.listen(
        (data) => _handleMessage(data),
        onError: (error) => _handleError(error),
        onDone: () => _handleDisconnect(),
      );
      
      _isConnected = true;
      print('🔌 WebSocket connected for user: $userId');
      
    } catch (e) {
      print('❌ WebSocket connection failed: $e');
      _scheduleReconnect();
    }
  }
  
  /// Disconnect from WebSocket server
  void _disconnect() {
    _channel?.sink.close(status.goingAway);
    _channel = null;
    _messageController?.close();
    _messageController = null;
    _isConnected = false;
    _currentUserId = null;
    
    if (_reconnectTimer != null) {
      _reconnectTimer!.cancel();
      _reconnectTimer = null;
    }
  }
  
  /// Send message to WebSocket server
  Future<void> sendMessage(WebSocketMessage message) async {
    if (!_isConnected || _channel == null) {
      throw Exception('WebSocket not connected');
    }
    
    try {
      final jsonMessage = json.encode(message.toJson());
      _channel!.sink.add(jsonMessage);
      print('📤 WebSocket message sent: ${message.type}');
    } catch (e) {
      print('❌ Failed to send WebSocket message: $e');
      throw Exception('Failed to send message');
    }
  }
  
  /// Handle incoming messages
  void _handleMessage(dynamic data) {
    try {
      final jsonData = json.decode(data);
      final message = WebSocketMessage.fromJson(jsonData);
      
      print('📥 WebSocket message received: ${message.type}');
      _messageController?.add(message);
      
    } catch (e) {
      print('❌ Failed to parse WebSocket message: $e');
    }
  }
  
  /// Handle WebSocket errors
  void _handleError(dynamic error) {
    print('❌ WebSocket error: $error');
    _isConnected = false;
    _scheduleReconnect();
  }
  
  /// Handle WebSocket disconnection
  void _handleDisconnect() {
    print('🔌 WebSocket disconnected');
    _isConnected = false;
    _scheduleReconnect();
  }
  
  /// Schedule reconnection attempt
  void _scheduleReconnect() {
    if (_reconnectTimer != null) return;
    
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (_currentUserId != null && !_isConnected) {
        print('🔄 Attempting WebSocket reconnection...');
        connect(_currentUserId!);
      }
    });
  }
  
  /// Send location update
  Future<void> updateLocation({
    required double latitude,
    required double longitude,
    required String companyId,
    bool isDriver = false,
    bool isAvailable = true,
  }) async {
    final message = WebSocketMessage(
      type: 'location_update',
      data: {
        'latitude': latitude,
        'longitude': longitude,
        'company_id': companyId,
        'is_driver': isDriver,
        'is_available': isAvailable,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    
    await sendMessage(message);
  }
  
  /// Send ride request
  Future<void> sendRideRequest({
    required String rideId,
    required Map<String, dynamic> rideData,
  }) async {
    final message = WebSocketMessage(
      type: 'ride_request',
      data: {
        'ride_id': rideId,
        ...rideData,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    
    await sendMessage(message);
  }
  
  /// Send ride response (accept/decline)
  Future<void> sendRideResponse({
    required String rideId,
    required String response, // 'accept' or 'decline'
    String? message,
    String? driverName,
    String? estimatedArrival,
  }) async {
    final messageData = {
      'ride_id': rideId,
      'response': response,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    if (message != null) messageData['message'] = message;
    if (driverName != null) messageData['driver_name'] = driverName;
    if (estimatedArrival != null) messageData['estimated_arrival'] = estimatedArrival;
    
    final wsMessage = WebSocketMessage(
      type: 'ride_response',
      data: messageData,
    );
    
    await sendMessage(wsMessage);
  }
  
  /// Update driver status
  Future<void> updateDriverStatus({
    required bool isAvailable,
    String? reason,
  }) async {
    final message = WebSocketMessage(
      type: 'driver_status',
      data: {
        'is_available': isAvailable,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    
    if (reason != null) message.data['reason'] = reason;
    
    await sendMessage(message);
  }
  
  /// Disconnect and cleanup
  void disconnect() {
    _disconnect();
    print('🔌 WebSocket service disconnected');
  }
  
  /// Get connection status
  Map<String, dynamic> getConnectionStatus() {
    return {
      'is_connected': _isConnected,
      'user_id': _currentUserId,
      'has_message_stream': _messageController != null,
    };
  }
}
