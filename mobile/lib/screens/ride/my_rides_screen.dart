import 'package:flutter/material.dart';
import '../../models/ride.dart';
import '../../services/ride_service.dart';
import '../../utils/constants.dart';

class MyRidesScreen extends StatefulWidget {
  const MyRidesScreen({Key? key}) : super(key: key);

  @override
  State<MyRidesScreen> createState() => _MyRidesScreenState();
}

class _MyRidesScreenState extends State<MyRidesScreen> {
  List<Ride> _rides = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRides();
  }

  Future<void> _loadRides() async {
    try {
      final rides = await RideService.getMyRides();
      setState(() {
        _rides = rides;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading rides: ${e.toString()}'),
            backgroundColor: AppColors.errorColor,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteRide(String rideId) async {
    try {
      await RideService.deleteRide(rideId);
      await _loadRides(); // Refresh the list
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ride deleted successfully'),
            backgroundColor: AppColors.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting ride: ${e.toString()}'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Rides'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRides,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _rides.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.directions_car_outlined,
                        size: 64,
                        color: AppColors.textSecondaryColor,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No rides yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppColors.textSecondaryColor,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Create your first ride to get started!',
                        style: TextStyle(
                          color: AppColors.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadRides,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _rides.length,
                    itemBuilder: (context, index) {
                      final ride = _rides[index];
                      return _RideCard(
                        ride: ride,
                        onDelete: () => _deleteRide(ride.id),
                      );
                    },
                  ),
                ),
    );
  }
}

class _RideCard extends StatelessWidget {
  final Ride ride;
  final VoidCallback onDelete;

  const _RideCard({
    Key? key,
    required this.ride,
    required this.onDelete,
  }) : super(key: key);

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.warningColor;
      case 'matched':
        return AppColors.accentColor;
      case 'in_progress':
        return AppColors.primaryColor;
      case 'completed':
        return AppColors.successColor;
      case 'cancelled':
        return AppColors.errorColor;
      default:
        return AppColors.textSecondaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status and Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(ride.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    ride.status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  '${ride.createdAt.day}/${ride.createdAt.month}/${ride.createdAt.year}',
                  style: const TextStyle(
                    color: AppColors.textSecondaryColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Pickup and Destination
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: AppColors.primaryColor,
                  size: 20,
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
                const Icon(
                  Icons.flag,
                  color: AppColors.errorColor,
                  size: 20,
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
            const SizedBox(height: 12),

            // Ride Details
            Row(
              children: [
                Icon(
                  Icons.people,
                  size: 16,
                  color: AppColors.textSecondaryColor,
                ),
                const SizedBox(width: 4),
                Text(
                  '${ride.currentPassengers}/${ride.maxPassengers}',
                  style: const TextStyle(
                    color: AppColors.textSecondaryColor,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 16),
                if (ride.scheduledTime != null) ...[
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: AppColors.textSecondaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${ride.scheduledTime!.hour}:${ride.scheduledTime!.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      color: AppColors.textSecondaryColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),

            // Notes
            if (ride.notes != null && ride.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                ride.notes!,
                style: const TextStyle(
                  color: AppColors.textSecondaryColor,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],

            // Actions
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (ride.status == 'pending') ...[
                  TextButton(
                    onPressed: onDelete,
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: AppColors.errorColor),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                ElevatedButton(
                  onPressed: () {
                    // TODO: Navigate to ride details
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('View Details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
