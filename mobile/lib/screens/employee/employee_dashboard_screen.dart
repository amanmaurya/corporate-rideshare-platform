import 'package:flutter/material.dart';
import '../../models/ride.dart';
import '../../models/user.dart';
import '../../services/ride_service.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../ride/available_rides_screen.dart';
import '../ride/active_ride_screen.dart';

class EmployeeDashboardScreen extends StatefulWidget {
  const EmployeeDashboardScreen({Key? key}) : super(key: key);

  @override
  State<EmployeeDashboardScreen> createState() => _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState extends State<EmployeeDashboardScreen> {
  List<Ride> _upcomingRides = [];
  Map<String, dynamic>? _dashboardData;
  List<Ride> _scheduledRides = [];
  List<Ride> _completedRides = [];
  List<Ride> _cancelledRides = [];
  bool _isLoading = true;
  String? _error;
  User? _currentUser;

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

      final dashboardData = await RideService.getEmployeeDashboard();
      
      if (dashboardData != null) {
        setState(() {
          _dashboardData = dashboardData;
          _upcomingRides = (dashboardData['rides']['upcoming'] as List<dynamic>? ?? [])
              .map((json) => Ride.fromJson(Map<String, dynamic>.from(json)))
              .toList();
          _scheduledRides = (dashboardData['rides']['scheduled_rides'] as List<dynamic>? ?? [])
              .map((json) => Ride.fromJson(Map<String, dynamic>.from(json)))
              .toList();
          _completedRides = (dashboardData['rides']['completed'] as List<dynamic>? ?? [])
              .map((json) => Ride.fromJson(Map<String, dynamic>.from(json)))
              .toList();
          _cancelledRides = (dashboardData['rides']['cancelled'] as List<dynamic>? ?? [])
              .map((json) => Ride.fromJson(Map<String, dynamic>.from(json)))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load dashboard data';
          _isLoading = false;
        });
      }
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
        title: const Text('Employee Dashboard'),
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
            _buildUpcomingRidesSection(),
            const SizedBox(height: 24),
            _buildScheduledRequestsSection(),
            const SizedBox(height: 24),
            _buildCompletedRidesSection(),
            const SizedBox(height: 24),
            _buildCancelledRidesSection(),
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
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Icon(
                  Icons.person,
                  size: 35,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, ${_currentUser?.name ?? 'Employee'}!',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Find rides and travel with your colleagues',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
            'Upcoming',
            '${_dashboardData?['upcoming_rides'] ?? 0}',
            Icons.schedule,
            AppColors.primaryColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Pending',
            '${_dashboardData?['scheduled_rides'] ?? 0}',
            Icons.pending,
            AppColors.warningColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Completed',
            '${_dashboardData?['completed_rides'] ?? 0}',
            Icons.check_circle,
            AppColors.successColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Cancelled',
            '${_dashboardData?['cancelled_rides'] ?? 0}',
            Icons.cancel,
            AppColors.errorColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
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

  Widget _buildUpcomingRidesSection() {
    if (_upcomingRides.isEmpty) {
      return _buildEmptySection(
        'Upcoming Rides',
        Icons.schedule,
        'No upcoming rides',
        'Confirmed rides will appear here',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Upcoming Rides', Icons.schedule, AppColors.primaryColor),
        const SizedBox(height: 16),
        ..._upcomingRides.map((ride) => _buildRideCard(ride, showActions: true)),
      ],
    );
  }

  Widget _buildScheduledRequestsSection() {
    if (_scheduledRides.isEmpty) {
      return _buildEmptySection(
        'Scheduled Rides',
        Icons.pending,
        'No scheduled rides',
        'Rides you\'ve requested will appear here',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Scheduled Rides', Icons.pending, AppColors.warningColor),
        const SizedBox(height: 16),
        ..._scheduledRides.map((ride) => _buildRideCard(ride, showActions: true)),
      ],
    );
  }

  Widget _buildCompletedRidesSection() {
    if (_completedRides.isEmpty) {
      return _buildEmptySection(
        'Completed Rides',
        Icons.check_circle,
        'No completed rides',
        'Completed rides will appear here',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Completed Rides', Icons.check_circle, AppColors.successColor),
        const SizedBox(height: 16),
        ..._completedRides.map((ride) => _buildRideCard(ride, showActions: false)),
      ],
    );
  }

  Widget _buildCancelledRidesSection() {
    if (_cancelledRides.isEmpty) {
      return _buildEmptySection(
        'Cancelled Rides',
        Icons.cancel,
        'No cancelled rides',
        'Cancelled rides will appear here',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Cancelled Rides', Icons.cancel, AppColors.errorColor),
        const SizedBox(height: 16),
        ..._cancelledRides.map((ride) => _buildCancelledRideCard(ride)),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptySection(String title, IconData icon, String message, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(title, icon, AppColors.textSecondaryColor),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 48,
                color: AppColors.textSecondaryColor,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRideCard(Ride ride, {bool showActions = true}) {
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
          
          if (showActions && ride.isInProgress) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _navigateToActiveRide(ride),
                icon: const Icon(Icons.track_changes),
                label: const Text('Track Ride'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.info,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCancelledRideCard(Ride ride) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.errorColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.errorColor.withOpacity(0.1),
            child: Icon(
              Icons.cancel,
              color: AppColors.errorColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${ride.pickupLocation} → ${ride.destination}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Driver: ${ride.driverName ?? 'Unknown'}',
                  style: TextStyle(
                    color: AppColors.textSecondaryColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.errorColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Cancelled',
              style: TextStyle(
                color: AppColors.errorColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
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
            'Error Loading Dashboard',
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
            onPressed: _loadDashboardData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // Action methods
  void _navigateToActiveRide(Ride ride) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActiveRideScreen(ride: ride),
      ),
    ).then((_) => _loadDashboardData());
  }
}
