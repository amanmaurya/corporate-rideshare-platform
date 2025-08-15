# 🚀 Real-Time Features Integration Guide

This guide explains how to integrate the new real-time features into your Flutter app.

## 📱 **What We've Built**

### 1. **WebSocket Service** (`websocket_service.dart`)
- Real-time communication with backend
- Automatic reconnection handling
- Message routing for different types

### 2. **Notification Service** (`notification_service.dart`)
- Local notification management
- Push token registration
- Real-time notification updates

### 3. **Enhanced Ride Service** (`enhanced_ride_service.dart`)
- New ride management features
- WebSocket integration
- Location updates and driver matching

### 4. **New Screens**
- `RealTimeRideScreen` - Live ride tracking
- `NotificationsScreen` - Notification management
- `DriverAvailabilityScreen` - Driver status toggle

## 🔧 **Setup Instructions**

### Step 1: Install Dependencies
```bash
cd mobile
flutter pub get
```

### Step 2: Initialize Services
Add this to your `main.dart` or app initialization:

```dart
import 'package:corporate_rideshare/services/notification_service.dart';
import 'package:corporate_rideshare/services/websocket_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize notification service
  await NotificationService.instance.initialize();
  
  runApp(MyApp());
}
```

### Step 3: Connect WebSocket
Connect to WebSocket when user logs in:

```dart
// In your login success handler
await WebSocketService.instance.connect(userId);
```

## 🎯 **How to Use Real-Time Features**

### 1. **Real-Time Ride Tracking**
```dart
// Navigate to real-time ride screen
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => RealTimeRideScreen(ride: ride),
  ),
);
```

### 2. **Listen for Notifications**
```dart
// In any screen
StreamBuilder<List<AppNotification>>(
  stream: NotificationService.instance.notificationStream,
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      final notifications = snapshot.data!;
      // Update UI with notifications
    }
    return YourWidget();
  },
);
```

### 3. **Send Location Updates**
```dart
// Update user location
await WebSocketService.instance.updateLocation(
  latitude: position.latitude,
  longitude: position.longitude,
  companyId: 'company-1',
  isDriver: false,
);
```

### 4. **Handle Driver Availability**
```dart
// Toggle driver status
await EnhancedRideService.instance.setDriverAvailability(
  isAvailable: true,
  reason: 'Driver is now available',
);
```

## 🔌 **WebSocket Message Types**

### **Incoming Messages:**
- `ride_accepted` - Ride request accepted by driver
- `ride_started` - Ride has started
- `ride_completed` - Ride has completed
- `location_update` - Driver location update
- `notification` - New notification

### **Outgoing Messages:**
- `location_update` - Send user location
- `ride_request` - Send ride request
- `ride_response` - Accept/decline ride
- `driver_status` - Update driver availability

## 📍 **Location Services**

### **Find Nearby Drivers:**
```dart
final nearbyDrivers = await EnhancedRideService.instance.findNearbyDrivers(
  latitude: currentLat,
  longitude: currentLon,
  radiusKm: 5.0,
);
```

### **Update Ride Location:**
```dart
await EnhancedRideService.instance.updateRideLocation(
  rideId,
  latitude,
  longitude,
);
```

## 🔔 **Notification System**

### **Notification Types:**
- `ride_request` - New ride request
- `ride_accepted` - Ride accepted
- `ride_declined` - Ride declined
- `ride_started` - Ride started
- `ride_completed` - Ride completed
- `driver_arriving` - Driver arriving

### **Priority Levels:**
- `low` - Green
- `normal` - Blue
- `high` - Orange
- `urgent` - Red

## 🚗 **Enhanced Ride Flow**

### **Complete Ride Lifecycle:**
1. **Request Ride** → Send via WebSocket
2. **Driver Matching** → Find nearby drivers
3. **Accept/Decline** → Driver responds
4. **Start Ride** → Begin tracking
5. **Track Progress** → Real-time updates
6. **Complete Ride** → End and calculate fare

## 🛠 **Troubleshooting**

### **WebSocket Connection Issues:**
- Check backend is running
- Verify user authentication
- Check network connectivity

### **Location Permission Issues:**
- Ensure location permissions are granted
- Check GPS is enabled
- Verify location accuracy settings

### **Notification Issues:**
- Check notification permissions
- Verify push token registration
- Check backend notification service

## 📱 **Testing the Features**

### **Test WebSocket Connection:**
```dart
// Check connection status
final status = WebSocketService.instance.getConnectionStatus();
print('Connected: ${status['is_connected']}');
```

### **Test Notifications:**
```dart
// Send test notification
await NotificationService.instance.addNotification(
  AppNotification(
    id: 'test_${DateTime.now().millisecondsSinceEpoch}',
    type: 'test',
    title: 'Test Notification',
    message: 'This is a test notification',
    timestamp: DateTime.now(),
  ),
);
```

### **Test Location Updates:**
```dart
// Simulate location update
await WebSocketService.instance.updateLocation(
  latitude: 37.7749,
  longitude: -122.4194,
  companyId: 'company-1',
);
```

## 🎉 **What You Get**

With these integrations, your app now has:

✅ **Real-time ride tracking**  
✅ **Instant notifications**  
✅ **Live driver matching**  
✅ **Location services**  
✅ **Professional-grade features**  
✅ **Enterprise-level architecture**  

## 🚀 **Next Steps**

1. **Test all features** with the backend running
2. **Integrate with existing screens** 
3. **Add push notifications** (FCM/APNS)
4. **Implement offline support**
5. **Add analytics and monitoring**

Your Flutter app is now a **fully-featured, real-time corporate rideshare platform**! 🎊
