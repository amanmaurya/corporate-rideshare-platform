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
  List<Ride> _rides = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRides();
  }

  Future<void> _loadRides() async {
    try {
      final rides = await RideService.getRides(status: 'pending');
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

  Future<void> _requestRide(String rideId) async {
    try {
      await RideService.requestRide(rideId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ride request sent successfully!'),
            backgroundColor: AppColors.successColor,
          ),
        );
        await _loadRides(); // Refresh the list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error requesting ride: ${e.toString()}'),
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
        title: const Text('Available Rides'),
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
                        Icons.search_off,
                        size: 64,
                        color: AppColors.textSecondaryColor,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No available rides',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppColors.textSecondaryColor,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Check back later for new rides!',
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
                      return _AvailableRideCard(
                        ride: ride,
                        onRequest: () => _requestRide(ride.id),
                      );
                    },
                  ),
                ),
    );
  }
}

class _AvailableRideCard extends StatelessWidget {
  final Ride ride;
  final VoidCallback onRequest;

  const _AvailableRideCard({
    Key? key,
    required this.ride,
    required this.onRequest,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.successColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'AVAILABLE',
                    style: TextStyle(
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

            // Route
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

            // Details
            Row(
              children: [
                Icon(
                  Icons.people,
                  size: 16,
                  color: AppColors.textSecondaryColor,
                ),
                const SizedBox(width: 4),
                Text(
                  '${ride.currentPassengers}/${ride.maxPassengers} passengers',
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
                OutlinedButton(
                  onPressed: () {
                    // TODO: Show ride details
                  },
                  child: const Text('Details'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: ride.currentPassengers >= ride.maxPassengers 
                      ? null 
                      : onRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    ride.currentPassengers >= ride.maxPassengers 
                        ? 'Full' 
                        : 'Request',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
