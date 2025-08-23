import 'package:flutter/material.dart';
import '../../models/ride.dart';
import '../../services/ride_service.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../ride/ride_requests_screen.dart';
import '../rides/real_time_ride_screen.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({Key? key}) : super(key: key);

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  List<Ride> _myRides = [];
  List<RideRequest> _pendingRequests = []; // Changed type to RideRequest
  List<RideRequest> _driverOffers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final currentUser = await AuthService.getCurrentUser();
      if (currentUser == null || !currentUser.isDriver) {
        setState(() {
          _error = 'User not authenticated or not a driver';
          _isLoading = false;
        });
        return;
      }

      final [myRides, allRides] = await Future.wait([
        RideService.getMyRides(),
        RideService.getRides(),
      ]);

      // Only get requests for rides where the user can actually manage them
      List<RideRequest> manageableRequests = [];
      List<RideRequest> driverOffers = [];
      
      for (final ride in allRides) {
        try {
          // Only try to get requests if user can manage this ride
          if (ride.riderId == currentUser.id || 
              ride.driverId == currentUser.id || 
              currentUser.role == 'admin') {
            
            final requests = await RideService.getRideRequests(ride.id);
            manageableRequests.addAll(requests);
          }
          
          // Check if current user has offered to drive this ride
          if (ride.driverId == null && currentUser.isDriver) {
            try {
              final requests = await RideService.getRideRequests(ride.id);
              final myOffer = requests.where((req) => 
                req.userId == currentUser.id && req.status == 'driver_offer'
              ).toList();
              driverOffers.addAll(myOffer);
            } catch (e) {
              // User can't see requests for this ride, skip
              print('Cannot access requests for ride ${ride.id}: $e');
            }
          }
        } catch (e) {
          // User is not authorized to see requests for this ride
          print('Not authorized to get requests for ride ${ride.id}: $e');
        }
      }

      setState(() {
        _myRides = myRides;
        // Only show pending requests for rides the user can manage
        _pendingRequests = manageableRequests.where((request) => 
          request.status == 'pending'
        ).toList();
        _driverOffers = driverOffers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _navigateToRideRequests(Ride ride) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RideRequestsScreen(ride: ride),
      ),
    );
  }

  void _navigateToRealTimeRide(Ride ride) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RealTimeRideScreen(ride: ride),
      ),
    );
  }

  Future<void> _approveRequest(RideRequest request) async {
    try {
      // Find the ride for this request from all available rides
      // We need to get the ride details since it's not in _myRides
      final ride = await RideService.getRide(request.rideId);
      
      // Use the appropriate method based on user role
      if (ride.riderId == (await AuthService.getCurrentUser())?.id) {
        // User is the ride creator - use acceptRideRequest
        await RideService.acceptRideRequest(ride.id, request.id);
      } else {
        // User is a driver - use acceptPassengerRequest
        await RideService.acceptPassengerRequest(ride.id, request.id);
      }
      
      // Refresh the dashboard
      _loadDashboardData();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Request from ${request.userName ?? 'user'} approved!'),
          backgroundColor: AppColors.successColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to approve request: ${e.toString()}'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  Future<void> _rejectRequest(RideRequest request) async {
    try {
      // Get the ride to determine if user is ride creator or driver
      final ride = await RideService.getRide(request.rideId);
      
      if (ride.riderId == (await AuthService.getCurrentUser())?.id) {
        // User is the ride creator - use rejectRideRequest
        await RideService.rejectRideRequest(ride.id, request.id);
      } else {
        // User is a driver - use rejectPassengerRequest
        await RideService.rejectPassengerRequest(ride.id, request.id);
      }
      
      // Refresh the dashboard data
      _loadDashboardData();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Request from ${request.userName ?? 'user'} rejected'),
          backgroundColor: AppColors.warningColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reject request: ${e.toString()}'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Navigate to create ride screen
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Ride'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
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

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeSection(),
            const SizedBox(height: 24),
            _buildQuickStats(),
            const SizedBox(height: 24),
            _buildActiveRidesSection(),
            const SizedBox(height: 24),
            _buildPendingRequestsSection(),
            const SizedBox(height: 24),
            _buildRecentRidesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor,
            AppColors.primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.directions_car,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, Driver!',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ready to hit the road?',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.directions_car,
            title: 'Active Rides',
            value: _myRides.where((r) => r.status == 'in_progress').length.toString(),
            color: AppColors.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.people,
            title: 'Pending Requests',
            value: _pendingRequests.length.toString(),
            color: AppColors.warningColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.check_circle,
            title: 'Completed',
            value: _myRides.where((r) => r.status == 'completed').length.toString(),
            color: AppColors.successColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveRidesSection() {
    final activeRides = _myRides.where((r) => r.status == 'in_progress').toList();
    
    if (activeRides.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Active Rides', Icons.directions_car, AppColors.primaryColor),
        const SizedBox(height: 16),
        ...activeRides.map((ride) => _buildRideCard(ride, showActions: true)),
      ],
    );
  }

  Widget _buildPendingRequestsSection() {
    if (_pendingRequests.isEmpty && _driverOffers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Pending Requests', Icons.people, AppColors.warningColor),
        const SizedBox(height: 16),
        ..._pendingRequests.map((request) => _buildRequestCard(request)),
        if (_driverOffers.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildSectionHeader('Driver Offers', Icons.local_shipping, AppColors.primaryColor),
          const SizedBox(height: 16),
          ..._driverOffers.map((offer) => _buildRequestCard(offer)),
        ],
      ],
    );
  }

  Widget _buildRecentRidesSection() {
    final recentRides = _myRides.take(5).toList();
    
    if (recentRides.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Recent Rides', Icons.history, AppColors.textSecondaryColor),
        const SizedBox(height: 16),
        ...recentRides.map((ride) => _buildRideCard(ride, showActions: false)),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildRideCard(Ride ride, {required bool showActions}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${ride.pickupLocation} → ${ride.destination}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${ride.currentPassengers}/${ride.maxPassengers} passengers',
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
            
            if (showActions) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  if (ride.status == 'matched') ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _navigateToRealTimeRide(ride),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Start Ride'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.successColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _navigateToRideRequests(ride),
                      icon: const Icon(Icons.people),
                      label: const Text('View Requests'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryColor,
                        side: BorderSide(color: AppColors.primaryColor),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(RideRequest request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primaryColor,
                  child: Text(
                    request.userName?.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.userName ?? 'Unknown User',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        request.userEmail ?? 'No email',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(request.status),
              ],
            ),
            
            if (request.message != null && request.message!.isNotEmpty) ...[
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
                      Icons.message,
                      size: 16,
                      color: AppColors.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        request.message!,
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
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: AppColors.textSecondaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Requested ${_formatTime(request.createdAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondaryColor,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approveRequest(request),
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.successColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectRequest(request),
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.errorColor,
                      side: BorderSide(color: AppColors.errorColor),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.directions_car_outlined,
            size: 64,
            color: AppColors.textSecondaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'No rides yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first ride to get started!',
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
            'Error loading dashboard',
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
            onPressed: _loadDashboardData,
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

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
