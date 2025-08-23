import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/ride.dart';
import '../../services/websocket_service.dart';


import '../../utils/constants.dart';

class RealTimeRideScreen extends StatefulWidget {
  final Ride ride;
  
  const RealTimeRideScreen({Key? key, required this.ride}) : super(key: key);

  @override
  State<RealTimeRideScreen> createState() => _RealTimeRideScreenState();
}

class _RealTimeRideScreenState extends State<RealTimeRideScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _isTracking = false;
  Timer? _locationTimer;
  
  @override
  void initState() {
    super.initState();
    _initializeWebSocket();
    _getCurrentLocation();
  }
  
  @override
  void dispose() {
    _stopLocationTracking();
    super.dispose();
  }
  
  /// Initialize WebSocket connection
  void _initializeWebSocket() {
    try {
      WebSocketService.instance.connect('user-1');
      print('🔌 WebSocket initialized for real-time ride tracking');
    } catch (e) {
      print('❌ WebSocket initialization failed: $e');
    }
  }
  
  /// Get current location
  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      setState(() {
        _currentPosition = position;
      });
      
      // Update map camera
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(position.latitude, position.longitude),
          ),
        );
      }
      
    } catch (e) {
      print('❌ Failed to get location: $e');
      _showErrorSnackBar('Failed to get location: $e');
    }
  }
  
  /// Start location tracking
  void _startLocationTracking() {
    if (_isTracking) return;
    
    setState(() {
      _isTracking = true;
    });
    
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _updateLocation();
    });
    
    _showSuccessSnackBar('Location tracking started');
  }
  
  /// Stop location tracking
  void _stopLocationTracking() {
    _locationTimer?.cancel();
    setState(() {
      _isTracking = false;
    });
    _showSuccessSnackBar('Location tracking stopped');
  }
  
  /// Update location and send to backend
  Future<void> _updateLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      setState(() {
        _currentPosition = position;
      });
      
      // Send location update via WebSocket
      await WebSocketService.instance.updateLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        companyId: widget.ride.companyId,
        isDriver: false,
      );
      
      // Update ride location in backend (placeholder)
      // TODO: Implement ride location update
      
    } catch (e) {
      print('❌ Failed to update location: $e');
    }
  }
  
  /// Start the ride
  Future<void> _startRide() async {
    try {
      // TODO: Implement start ride functionality
      final success = true; // Placeholder
      
      if (success) {
        _showSuccessSnackBar('Ride started successfully!');
        setState(() {
          // Update ride status locally
        });
      } else {
        _showErrorSnackBar('Failed to start ride');
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    }
  }
  
  /// Complete the ride
  Future<void> _completeRide() async {
    try {
      // TODO: Implement complete ride functionality
      final result = {'fare': 25.0}; // Placeholder
      
      if (result != null) {
        _showSuccessSnackBar('Ride completed! Fare: \$${result['fare']}');
        Navigator.of(context).pop();
      } else {
        _showErrorSnackBar('Failed to complete ride');
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    }
  }
  
  /// Show success snackbar
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.successColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  /// Show error snackbar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.errorColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ride #${widget.ride.id}'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          // Location tracking toggle
          IconButton(
            icon: Icon(_isTracking ? Icons.location_on : Icons.location_off),
            onPressed: _isTracking ? _stopLocationTracking : _startLocationTracking,
            tooltip: _isTracking ? 'Stop Tracking' : 'Start Tracking',
          ),
        ],
      ),
      body: Column(
        children: [
          // Map Section
          Expanded(
            flex: 3,
            child: _currentPosition != null
                ? GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                      ),
                      zoom: 15,
                    ),
                    onMapCreated: (controller) {
                      _mapController = controller;
                    },
                    markers: _buildMarkers(),
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                  )
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Getting your location...'),
                      ],
                    ),
                  ),
          ),
          
          // Ride Info Section
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ride Status
                  Row(
                    children: [
                      Icon(
                        _getStatusIcon(),
                        color: _getStatusColor(),
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Status: ${widget.ride.status.toUpperCase()}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Ride Details
                  _buildRideDetail('From', widget.ride.pickupLocation),
                  _buildRideDetail('To', widget.ride.destination),
                  _buildRideDetail('Distance', '${widget.ride.distance?.toStringAsFixed(1)} km'),
                  _buildRideDetail('Fare', '\$${widget.ride.fare?.toStringAsFixed(2)}'),
                  
                  const Spacer(),
                  
                  // Action Buttons
                  if (widget.ride.status == 'matched')
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _startRide,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Start Ride'),
                          ),
                        ),
                      ],
                    ),
                  
                  if (widget.ride.status == 'in_progress')
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _completeRide,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.successColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Complete Ride'),
                          ),
                        ),
                      ],
                    ),
                  
                  // Location tracking status
                  if (_isTracking)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: AppColors.primaryColor,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Location tracking active',
                            style: TextStyle(
                              color: AppColors.primaryColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build map markers
  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};
    
    // Current location marker
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          infoWindow: const InfoWindow(title: 'Your Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }
    
    // Pickup location marker
    markers.add(
      Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(widget.ride.pickupLatitude, widget.ride.pickupLongitude),
        infoWindow: InfoWindow(title: 'Pickup: ${widget.ride.pickupLocation}'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    );
    
    // Destination marker
    markers.add(
      Marker(
        markerId: const MarkerId('destination'),
        position: LatLng(widget.ride.destinationLatitude, widget.ride.destinationLongitude),
        infoWindow: InfoWindow(title: 'Destination: ${widget.ride.destination}'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );
    
    return markers;
  }
  
  /// Build ride detail row
  Widget _buildRideDetail(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Get status icon
  IconData _getStatusIcon() {
    switch (widget.ride.status) {
      case 'pending':
        return Icons.schedule;
      case 'matched':
        return Icons.check_circle;
      case 'in_progress':
        return Icons.directions_car;
      case 'completed':
        return Icons.done_all;
      default:
        return Icons.info;
    }
  }
  
  /// Get status color
  Color _getStatusColor() {
    switch (widget.ride.status) {
      case 'pending':
        return Colors.orange;
      case 'matched':
        return Colors.blue;
      case 'in_progress':
        return Colors.green;
      case 'completed':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }
}
