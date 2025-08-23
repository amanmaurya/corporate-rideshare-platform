import 'package:flutter/material.dart';
import '../../models/ride.dart';
import '../../models/user.dart';
import '../../services/ride_service.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../services/auth_service.dart';

class AvailableRidesScreen extends StatefulWidget {
  const AvailableRidesScreen({Key? key}) : super(key: key);

  @override
  State<AvailableRidesScreen> createState() => _AvailableRidesScreenState();
}

class _AvailableRidesScreenState extends State<AvailableRidesScreen> {
  List<Ride> _rides = [];
  List<RideRequest> _myRequests = [];
  bool _isLoading = true;
  String? _error;
  final TextEditingController _messageController = TextEditingController();
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadRides();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadRides() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final [rides, myRequests] = await Future.wait([
        RideService.getRides(status: 'pending'),
        _loadMyRequests(),
      ]);

      setState(() {
        _rides = rides.cast<Ride>();
        _myRequests = myRequests.cast<RideRequest>();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<List<RideRequest>> _loadMyRequests() async {
    try {
      // Get current user
      final currentUser = await AuthService.getCurrentUser();
      if (currentUser == null) return [];
      
      // Get all rides and check for user's own requests
      final allRides = await RideService.getRides();
      List<RideRequest> requests = [];
      
      for (final ride in allRides) {
        try {
          // Use the new method to get only the user's own request
          final myRequest = await RideService.getMyRideRequest(ride.id);
          if (myRequest != null) {
            requests.add(myRequest);
          }
        } catch (e) {
          // User has no request for this ride, skip
          print('No request found for ride ${ride.id}: $e');
        }
      }
      
      return requests;
    } catch (e) {
      print('Failed to load my requests: $e');
      return [];
    }
  }

  RideRequest? _getMyRequestForRide(String rideId) {
    try {
      return _myRequests.firstWhere(
        (req) => req.rideId == rideId,
      );
    } catch (e) {
      // No request found for this ride
      return null;
    }
  }

  bool _hasRequestedRide(String rideId) {
    return _myRequests.any((req) => req.rideId == rideId);
  }

  String _getRequestStatus(String rideId) {
    final request = _getMyRequestForRide(rideId);
    return request?.status ?? 'none';
  }

  List<Ride> get _filteredRides {
    switch (_selectedFilter) {
      case 'nearby':
        // TODO: Implement nearby filter based on user location
        return _rides;
      case 'scheduled':
        return _rides.where((ride) => ride.scheduledTime != null).toList();
      case 'flexible':
        return _rides.where((ride) => ride.scheduledTime == null).toList();
      default:
        return _rides;
    }
  }

  Future<void> _requestRide(Ride ride) async {
    final message = _messageController.text.trim();
    
    try {
      await RideService.requestRide(ride.id, message: message.isEmpty ? null : message);
      
      // Refresh the rides to show updated status
      _loadRides();
      
      // Show success message
      _showSuccessSnackBar('Ride request sent successfully!');
      
      // Close dialog
      Navigator.of(context).pop();
    } catch (e) {
      _showErrorSnackBar('Failed to request ride: ${e.toString()}');
    }
  }

  Future<void> _offerToDrive(Ride ride) async {
    try {
      await RideService.offerToDriveRide(ride.id);
      
      // Show success message
      _showSuccessSnackBar('Driver offer sent successfully!');
      
      // Refresh the rides to show updated status
      _loadRides();
    } catch (e) {
      _showErrorSnackBar('Failed to offer to drive: ${e.toString()}');
    }
  }

  Future<String?> _showRequestDialog(Ride ride) async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.directions_car,
              color: AppColors.primaryColor,
              size: 24,
            ),
            const SizedBox(width: 12),
            const Text('Request to Join Ride'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryColor.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.my_location,
                        color: AppColors.successColor,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ride.pickupLocation,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.flag,
                        color: AppColors.errorColor,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ride.destination,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Message (optional)',
                hintText: 'Add a message for the ride creator...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.message),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context, _messageController.text.trim());
              _messageController.clear();
            },
            icon: const Icon(Icons.send),
            label: const Text('Send Request'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showRideDetails(Ride ride) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: AppColors.primaryColor,
              size: 24,
            ),
            const SizedBox(width: 12),
            const Text('Ride Details'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('From', ride.pickupLocation, Icons.my_location, AppColors.successColor),
              _buildDetailRow('To', ride.destination, Icons.flag, AppColors.errorColor),
              _buildDetailRow('Passengers', '${ride.currentPassengers}/${ride.maxPassengers}', Icons.people, AppColors.primaryColor),
              if (ride.scheduledTime != null)
                _buildDetailRow('Time', '${ride.scheduledTime!.hour}:${ride.scheduledTime!.minute.toString().padLeft(2, '0')}', Icons.schedule, AppColors.warningColor),
              if (ride.distance != null)
                _buildDetailRow('Distance', '${ride.distance!.toStringAsFixed(1)} km', Icons.straighten, AppColors.info),
              if (ride.notes != null && ride.notes!.isNotEmpty)
                _buildDetailRow('Notes', ride.notes!, Icons.note, AppColors.textSecondaryColor),
              _buildDetailRow('Status', ride.status, Icons.info, AppColors.primaryColor),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (ride.currentPassengers < ride.maxPassengers)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _requestRide(ride);
              },
              icon: const Icon(Icons.check),
              label: const Text('Request to Join'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.successColor,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Rides'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRides,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedFilter,
              decoration: InputDecoration(
                labelText: 'Filter',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              items: [
                DropdownMenuItem(value: 'all', child: Text('All Rides')),
                DropdownMenuItem(value: 'nearby', child: Text('Nearby')),
                DropdownMenuItem(value: 'scheduled', child: Text('Scheduled')),
                DropdownMenuItem(value: 'flexible', child: Text('Flexible Time')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedFilter = value ?? 'all';
                });
              },
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${_filteredRides.length} rides',
              style: TextStyle(
                color: AppColors.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
        ),
      );
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_filteredRides.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadRides,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredRides.length,
        itemBuilder: (context, index) {
          final ride = _filteredRides[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildRideCard(ride),
          );
        },
      ),
    );
  }

  Widget _buildRideCard(Ride ride) {
    return Card(
      elevation: 8,
      shadowColor: AppColors.primaryColor.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              Colors.white,
              AppColors.backgroundColor,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status and time
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${ride.pickupLocation} → ${ride.destination}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (ride.scheduledTime != null)
                          Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 16,
                                color: AppColors.warningColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${ride.scheduledTime!.hour}:${ride.scheduledTime!.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  color: AppColors.warningColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  _buildStatusChip(ride.status),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Route visualization
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryColor.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: AppColors.successColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  ride.pickupLocation,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            width: 2,
                            height: 20,
                            margin: const EdgeInsets.only(left: 5),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor.withOpacity(0.3),
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: AppColors.errorColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  ride.destination,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Driver information section
              if (ride.driverId != null || (ride.driverOffers?.isNotEmpty ?? false)) ...[
                const SizedBox(height: 16),
                _buildDriverInfoSection(ride),
              ],
              
              const SizedBox(height: 20),
              
              // Ride details
              Row(
                children: [
                  _buildDetailChip(
                    Icons.people,
                    '${ride.currentPassengers}/${ride.maxPassengers}',
                    AppColors.primaryColor,
                  ),
                  const SizedBox(width: 12),
                  if (ride.fare != null)
                    _buildDetailChip(
                      Icons.attach_money,
                      '\$${ride.fare!.toStringAsFixed(2)}',
                      AppColors.successColor,
                    ),
                  if (ride.distance != null) ...[
                    const SizedBox(width: 12),
                    _buildDetailChip(
                      Icons.straighten,
                      '${ride.distance!.toStringAsFixed(1)} km',
                      AppColors.info,
                    ),
                  ],
                ],
              ),
              
              // Notes
              if (ride.notes != null && ride.notes!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warningColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.warningColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.note,
                        size: 16,
                        color: AppColors.warningColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ride.notes!,
                          style: TextStyle(
                            color: AppColors.warningColor,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 20),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showRideDetails(ride),
                      icon: const Icon(Icons.info_outline),
                      label: const Text('Details'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryColor,
                        side: BorderSide(color: AppColors.primaryColor),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildRequestButton(ride),
                  ),
                ],
              ),
              
              // Driver offer button (if user is a driver and ride has no driver)
              if (ride.driverId == null) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FutureBuilder<User?>(
                    future: AuthService.getCurrentUser(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          height: 48,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      
                      final currentUser = snapshot.data;
                      if (currentUser?.isDriver == true) {
                        return ElevatedButton.icon(
                          onPressed: () => _offerToDrive(ride),
                          icon: const Icon(Icons.directions_car),
                          label: const Text('Offer to Drive'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.info,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }
                      
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    IconData icon;
    
    switch (status) {
      case 'pending':
        color = AppColors.warningColor;
        icon = Icons.schedule;
        break;
      case 'matched':
        color = AppColors.primaryColor;
        icon = Icons.people;
        break;
      case 'in_progress':
        color = AppColors.successColor;
        icon = Icons.directions_car;
        break;
      case 'completed':
        color = AppColors.textSecondaryColor;
        icon = Icons.check_circle;
        break;
      default:
        color = AppColors.textSecondaryColor;
        icon = Icons.info;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestButton(Ride ride) {
    final myRequest = _getMyRequestForRide(ride.id);
    final isRequested = _hasRequestedRide(ride.id);

    // If user already requested to join as passenger
    if (isRequested && myRequest != null) {
      return _buildRequestStatusButton(myRequest);
    }

    // Regular request to join button
    return ElevatedButton.icon(
      onPressed: ride.currentPassengers >= ride.maxPassengers 
          ? null 
          : () => _requestRide(ride),
      icon: const Icon(Icons.check),
      label: Text(ride.currentPassengers >= ride.maxPassengers 
          ? 'Ride Full' 
          : 'Request to Join'),
      style: ElevatedButton.styleFrom(
        backgroundColor: ride.currentPassengers >= ride.maxPassengers 
            ? AppColors.textSecondaryColor
            : AppColors.primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildRequestStatusButton(RideRequest request) {
    Color buttonColor;
    IconData icon;
    String label;
    String? subtitle;
    bool isEnabled = false;

    switch (request.status.toLowerCase()) {
      case 'pending':
        buttonColor = AppColors.warningColor;
        icon = Icons.schedule;
        label = 'Request Pending';
        subtitle = 'Waiting for approval';
        break;
      case 'accepted':
        buttonColor = AppColors.successColor;
        icon = Icons.check_circle;
        label = 'Request Accepted';
        subtitle = 'You can join this ride';
        isEnabled = true;
        break;
      case 'declined':
        buttonColor = AppColors.errorColor;
        icon = Icons.cancel;
        label = 'Request Declined';
        subtitle = 'Try another ride';
        break;
      case 'cancelled':
        buttonColor = AppColors.textSecondaryColor;
        icon = Icons.block;
        label = 'Request Cancelled';
        subtitle = 'No longer available';
        break;
      default:
        buttonColor = AppColors.textSecondaryColor;
        icon = Icons.help;
        label = 'Unknown Status';
        subtitle = 'Contact support';
    }

    return Container(
      decoration: BoxDecoration(
        color: buttonColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: buttonColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          ElevatedButton.icon(
            onPressed: isEnabled ? () => _showRideDetails(_getRideById(request.rideId)!) : null,
            icon: Icon(icon),
            label: Text(label),
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          // Add cancel button for pending requests
          if (request.status.toLowerCase() == 'pending') ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _cancelRideRequest(request),
              icon: const Icon(Icons.cancel, size: 16),
              label: const Text('Cancel Request'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.errorColor,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ],
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: buttonColor,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (request.message != null && request.message!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: buttonColor.withOpacity(0.2)),
              ),
              child: Text(
                '"${request.message}"',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondaryColor,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Ride? _getRideById(String rideId) {
    try {
      return _rides.firstWhere((ride) => ride.id == rideId);
    } catch (e) {
      return null;
    }
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.errorColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading rides',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadRides,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.directions_car_outlined,
              size: 64,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No rides available',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for new ride opportunities',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDriverInfoSection(Ride ride) {
    if (ride.driverId != null) {
      // Show assigned driver information
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.successColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.successColor.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.directions_car, size: 20, color: AppColors.successColor),
                const SizedBox(width: 12),
                Text(
                  'Driver Assigned',
                  style: TextStyle(
                    color: AppColors.successColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (ride.driverName != null) ...[
              _buildDriverInfoRow('Name', ride.driverName!),
              const SizedBox(height: 8),
            ],
            if (ride.driverEmail != null) ...[
              _buildDriverInfoRow('Email', ride.driverEmail!),
              const SizedBox(height: 8),
            ],
            if (ride.driverPhone != null) ...[
              _buildDriverInfoRow('Phone', ride.driverPhone!),
              const SizedBox(height: 8),
            ],
            if (ride.driverRating != null) ...[
              _buildDriverInfoRow('Rating', '${ride.driverRating!.toStringAsFixed(1)} ⭐'),
            ],
          ],
        ),
      );
    } else if (ride.driverOffers?.isNotEmpty ?? false) {
      // Show driver offers
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.info.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.info.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_offer, size: 20, color: AppColors.info),
                const SizedBox(width: 12),
                Text(
                  'Driver Offers (${ride.driverOffers!.length})',
                  style: TextStyle(
                    color: AppColors.info,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...ride.driverOffers!.take(3).map((offer) => _buildDriverOfferCard(offer)),
            if (ride.driverOffers!.length > 3) ...[
              const SizedBox(height: 8),
              Text(
                '... and ${ride.driverOffers!.length - 3} more offers',
                style: TextStyle(
                  color: AppColors.textSecondaryColor,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      );
    }
    
    return const SizedBox.shrink();
  }

  Widget _buildDriverInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            color: AppColors.textSecondaryColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDriverOfferCard(DriverOffer offer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.info.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.info,
            child: Text(
              offer.driverName.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  offer.driverName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (offer.driverRating != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${offer.driverRating!.toStringAsFixed(1)} ⭐',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondaryColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              offer.status.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.info,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelRideRequest(RideRequest request) async {
    try {
      await RideService.cancelRideRequest(request.id);
      _loadRides(); // Refresh the rides to show updated status
      _showSuccessSnackBar('Ride request cancelled successfully!');
    } catch (e) {
      _showErrorSnackBar('Failed to cancel ride request: ${e.toString()}');
    }
  }
}
