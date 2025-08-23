import 'dart:convert';
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:shared_preferences/shared_preferences.dart';
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
  String? _currentCompanyId;
  
  // Singleton pattern
  static WebSocketService get instance {
    _instance ??= WebSocketService._internal();
    return _instance!;
  }
  
  WebSocketService._internal();
  
  // Getters
  bool get isConnected => _isConnected;
  Stream<WebSocketMessage>? get messageStream => _messageController?.stream;
  
  /// Connect to WebSocket server using JWT token
  Future<void> connect() async {
    if (_isConnected) return;
    
    try {
      // Get JWT token from shared preferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.tokenKey);
      
      if (token == null) {
        throw Exception('No authentication token found');
      }
      
      final wsUrl = AppConstants.baseUrl.replaceFirst('http', 'ws');
      final uri = Uri.parse('$wsUrl/api/v1/websocket/ws/$token');
      
      _channel = WebSocketChannel.connect(uri);
      _messageController = StreamController<WebSocketMessage>.broadcast();
      
      // Listen for messages
      _channel!.stream.listen(
        (data) => _handleMessage(data),
        onError: (error) => _handleError(error),
        onDone: () => _handleDisconnect(),
      );
      
      _isConnected = true;
      print('🔌 WebSocket connected successfully');
      
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
    _currentCompanyId = null;
    
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
      if (!_isConnected) {
        print('🔄 Attempting WebSocket reconnection...');
        connect();
      }
    });
  }
  
  /// Send ping message to keep connection alive
  Future<void> sendPing() async {
    final message = WebSocketMessage(
      type: 'ping',
      data: {
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    
    await sendMessage(message);
  }
  
  /// Send location update
  Future<void> updateLocation({
    required double latitude,
    required double longitude,
    required String rideId,
  }) async {
    final message = WebSocketMessage(
      type: 'location_update',
      data: {
        'ride_id': rideId,
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    
    await sendMessage(message);
  }
  
  /// Send ride status update
  Future<void> updateRideStatus({
    required String rideId,
    required String status,
    Map<String, dynamic>? additionalData,
  }) async {
    final messageData = {
      'ride_id': rideId,
      'status': status,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    if (additionalData != null) {
      messageData.addAll(additionalData);
    }
    
    final message = WebSocketMessage(
      type: 'ride_status',
      data: messageData,
    );
    
    await sendMessage(message);
  }
  
  /// Listen for specific message types
  Stream<WebSocketMessage> listenToMessageType(String messageType) {
    return messageStream?.where((message) => message.type == messageType) ?? 
           Stream.empty();
  }
  
  /// Listen for ride updates
  Stream<WebSocketMessage> get rideUpdates => 
      listenToMessageType('ride_update');
  
  /// Listen for ride requests
  Stream<WebSocketMessage> get rideRequests => 
      listenToMessageType('ride_request');
  
  /// Listen for location updates
  Stream<WebSocketMessage> get locationUpdates => 
      listenToMessageType('location_update');
  
  /// Listen for notifications
  Stream<WebSocketMessage> get notifications => 
      listenToMessageType('notification');
  
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
      'company_id': _currentCompanyId,
      'has_message_stream': _messageController != null,
    };
  }
  
  /// Start heartbeat to keep connection alive
  void startHeartbeat() {
    Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isConnected) {
        sendPing();
      } else {
        timer.cancel();
      }
    });
  }
}
