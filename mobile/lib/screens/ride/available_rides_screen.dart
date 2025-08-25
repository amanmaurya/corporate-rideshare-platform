import 'package:flutter/material.dart';
import '../../models/ride.dart';
import '../../services/ride_service.dart';
import '../../utils/constants.dart';

class AvailableRidesScreen extends StatefulWidget {
  const AvailableRidesScreen({Key? key}) : super(key: key);

  @override
  State<AvailableRidesScreen> createState() => _AvailableRidesScreenState();
}

class _AvailableRidesScreenState extends State<AvailableRidesScreen> {
  List<Ride> _availableRides = [];
  List<RideRequest> _myRequests = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final [availableRides, myRequests] = await Future.wait([
        RideService.getAvailableRides(),
        RideService.getUserRideRequests(),
      ]);

      setState(() {
        _availableRides = List<Ride>.from(availableRides);
        _myRequests = List<RideRequest>.from(myRequests);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
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
            onPressed: _loadData,
          ),
        ],
      ),
      body: _buildBody(),
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

    if (_availableRides.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _availableRides.length,
        itemBuilder: (context, index) {
          final ride = _availableRides[index];
          return _buildRideCard(ride);
        },
      ),
    );
  }

  Widget _buildRideCard(Ride ride) {
    // Check if user has already requested this ride
    final existingRequest = _myRequests.firstWhere(
      (request) => request.rideId == ride.id,
              orElse: () => RideRequest(
          id: '',
          rideId: '',
          userId: '',
          status: 'none',
          createdAt: DateTime.now(),
        ),
    );

    final hasRequested = existingRequest.status != 'none';
    final requestStatus = existingRequest.status;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: hasRequested 
              ? _getStatusColor(requestStatus).withOpacity(0.3)
              : Colors.grey[300]!,
          width: hasRequested ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with route and status
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
                    Text(
                      'Driver: ${ride.driverName ?? 'Unknown'}',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusChip(ride.status),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Ride details
          Row(
            children: [
              Icon(
                Icons.schedule,
                size: 16,
                color: AppColors.textSecondaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                ride.scheduledTime != null 
                    ? '${ride.scheduledTime!.hour}:${ride.scheduledTime!.minute.toString().padLeft(2, '0')}'
                    : 'Flexible time',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondaryColor,
                ),
              ),
              const SizedBox(width: 24),
              Icon(
                Icons.attach_money,
                size: 16,
                color: AppColors.textSecondaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                '\$${ride.fare?.toStringAsFixed(2) ?? '0.00'}',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondaryColor,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Capacity and distance
          Row(
            children: [
              Icon(
                Icons.airline_seat_recline_normal,
                size: 16,
                color: AppColors.textSecondaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                '${ride.confirmedPassengers}/${ride.vehicleCapacity} seats taken',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondaryColor,
                ),
              ),
              const SizedBox(width: 24),
              Icon(
                Icons.straighten,
                size: 16,
                color: AppColors.textSecondaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                '${ride.distance?.toStringAsFixed(1) ?? '0.0'} km',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondaryColor,
                ),
              ),
            ],
          ),
          
          if (ride.notes != null && ride.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.backgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primaryColor.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.note,
                    size: 16,
                    color: AppColors.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ride.notes!,
                      style: const TextStyle(
                        fontSize: 14,
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
          if (!hasRequested && ride.hasAvailableSeats) ...[
            // Can request seat
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _requestRide(ride),
                icon: const Icon(Icons.add),
                label: const Text('Request Seat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ] else if (hasRequested) ...[
            // Already requested - show status
            Row(
              children: [
                Icon(
                  _getStatusIcon(requestStatus),
                  color: _getStatusColor(requestStatus),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _getStatusText(requestStatus),
                  style: TextStyle(
                    color: _getStatusColor(requestStatus),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (requestStatus == 'pending') ...[
                  OutlinedButton(
                    onPressed: () => _cancelRequest(existingRequest.id),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.errorColor,
                      side: BorderSide(color: AppColors.errorColor),
                    ),
                    child: const Text('Cancel'),
                  ),
                ],
              ],
            ),
          ] else if (!ride.hasAvailableSeats) ...[
            // No available seats
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.errorColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: AppColors.errorColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'No available seats',
                    style: TextStyle(
                      color: AppColors.errorColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    
    switch (status) {
      case 'available':
        color = AppColors.primaryColor;
        label = 'Available';
        break;
      case 'confirmed':
        color = AppColors.warningColor;
        label = 'Confirmed';
        break;
      case 'in_progress':
        color = AppColors.info;
        label = 'In Progress';
        break;
      case 'completed':
        color = AppColors.successColor;
        label = 'Completed';
        break;
      case 'cancelled':
        color = AppColors.errorColor;
        label = 'Cancelled';
        break;
      default:
        color = AppColors.textSecondaryColor;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_car_outlined,
            size: 64,
            color: AppColors.textSecondaryColor,
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
            'Check back later for available rides',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
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
            'Error Loading Rides',
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
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // Helper methods
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.warningColor;
      case 'accepted':
        return AppColors.successColor;
      case 'rejected':
        return AppColors.errorColor;
      case 'cancelled':
        return AppColors.textSecondaryColor;
      default:
        return AppColors.textSecondaryColor;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'accepted':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'cancelled':
        return Icons.close;
      default:
        return Icons.info;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Request Pending';
      case 'accepted':
        return 'Request Accepted';
      case 'rejected':
        return 'Request Rejected';
      case 'cancelled':
        return 'Request Cancelled';
      default:
        return 'Unknown Status';
    }
  }

  // Action methods
  Future<void> _requestRide(Ride ride) async {
    try {
      await RideService.requestRide(ride.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request sent successfully!'),
            backgroundColor: AppColors.successColor,
          ),
        );
        
        // Refresh data to show updated status
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _cancelRequest(String requestId) async {
    try {
      await RideService.cancelRideRequest(requestId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request cancelled'),
            backgroundColor: AppColors.warningColor,
          ),
        );
        
        // Refresh data
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel request: ${e.toString()}'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }
}

