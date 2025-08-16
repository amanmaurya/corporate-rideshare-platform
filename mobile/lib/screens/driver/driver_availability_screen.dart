import 'package:flutter/material.dart';
import '../../services/websocket_service.dart';
import '../../services/enhanced_ride_service.dart';
import '../../utils/colors.dart';

class DriverAvailabilityScreen extends StatefulWidget {
  const DriverAvailabilityScreen({Key? key}) : super(key: key);

  @override
  State<DriverAvailabilityScreen> createState() => _DriverAvailabilityScreenState();
}

class _DriverAvailabilityScreenState extends State<DriverAvailabilityScreen> {
  bool _isAvailable = true;
  bool _isLoading = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _initializeWebSocket();
  }

  Future<void> _initializeWebSocket() async {
    try {
      // Connect as driver
      await WebSocketService.instance.connect('driver-1');
      print('🔌 WebSocket connected for driver');
    } catch (e) {
      print('❌ WebSocket connection failed: $e');
    }
  }

  Future<void> _toggleAvailability() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final success = await EnhancedRideService.instance.setDriverAvailability(
        !_isAvailable,
        reason: !_isAvailable ? 'Driver is now available' : 'Driver is unavailable',
      );

      if (success) {
        setState(() {
          _isAvailable = !_isAvailable;
          _statusMessage = _isAvailable 
              ? 'You are now available for ride requests' 
              : 'You are now unavailable for ride requests';
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_statusMessage!),
            backgroundColor: AppColors.successColor,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        setState(() {
          _statusMessage = 'Failed to update availability status';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating status: $e'),
          backgroundColor: AppColors.errorColor,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Status'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      _isAvailable ? Icons.check_circle : Icons.cancel,
                      size: 64,
                      color: _isAvailable ? AppColors.successColor : AppColors.errorColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isAvailable ? 'Available' : 'Unavailable',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _isAvailable ? AppColors.successColor : AppColors.errorColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isAvailable 
                          ? 'You are currently accepting ride requests'
                          : 'You are not accepting ride requests',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Toggle Button
            ElevatedButton(
              onPressed: _isLoading ? null : _toggleAvailability,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isAvailable ? AppColors.errorColor : AppColors.successColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _isAvailable ? 'Go Offline' : 'Go Online',
                      style: const TextStyle(fontSize: 18),
                    ),
            ),
            
            const SizedBox(height: 24),
            
            // Status Message
            if (_statusMessage != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isAvailable 
                      ? AppColors.successColor.withOpacity(0.1)
                      : AppColors.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isAvailable 
                        ? AppColors.successColor.withOpacity(0.3)
                        : AppColors.errorColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isAvailable ? Icons.info : Icons.warning,
                      color: _isAvailable ? AppColors.successColor : AppColors.errorColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _statusMessage!,
                        style: TextStyle(
                          color: _isAvailable ? AppColors.successColor : AppColors.errorColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            const Spacer(),
            
            // Information Card
            Card(
              color: Colors.blue.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info,
                          color: AppColors.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'How it works',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoItem(
                      'When online',
                      'You will receive ride requests from nearby riders',
                    ),
                    _buildInfoItem(
                      'When offline',
                      'You will not receive any ride requests',
                    ),
                    _buildInfoItem(
                      'Real-time updates',
                      'Your status updates instantly via WebSocket',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
