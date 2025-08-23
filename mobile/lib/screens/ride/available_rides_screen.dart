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
  User? _currentUser;
  Set<String> _expandedCards = {}; // Track which cards are expanded
  bool _allExpanded = false; // Track if all cards are expanded

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

      final [currentUser, rides, myRequests] = await Future.wait([
        AuthService.getCurrentUser(),
        RideService.getRides(status: 'pending'),
        _loadMyRequests(),
      ]);

      setState(() {
        _currentUser = currentUser as User?;
        _rides = (rides as List).cast<Ride>();
        _myRequests = (myRequests as List).cast<RideRequest>();
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
      if (currentUser == null) {
        return [];
      }
      
      // Use the new efficient endpoint to get all user requests in one call
      final requests = await RideService.getUserRideRequests();
      
      return requests;
      
    } catch (e) {
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

  bool _isMyRide(Ride ride) {
    // Check if the current user is the creator of this ride
    return _currentUser != null && ride.riderId == _currentUser!.id;
  }

  void _toggleCardExpansion(String rideId) {
    setState(() {
      if (_expandedCards.contains(rideId)) {
        _expandedCards.remove(rideId);
      } else {
        _expandedCards.add(rideId);
      }
    });
  }

  void _toggleAllCards() {
    setState(() {
      if (_allExpanded) {
        _expandedCards.clear();
        _allExpanded = false;
      } else {
        _expandedCards = _filteredRides.map((ride) => ride.id).toSet();
        _allExpanded = true;
      }
    });
  }

  bool _isCardExpanded(String rideId) {
    return _expandedCards.contains(rideId);
  }

  List<Ride> get _filteredRides {
    // First filter out user's own rides
    List<Ride> availableRides = _rides.where((ride) {
      final isMyRide = _isMyRide(ride);
      return !isMyRide;
    }).toList();

    // Then apply the selected filter
    List<Ride> filteredRides;
    switch (_selectedFilter) {
      case 'nearby':
        // TODO: Implement nearby filter based on user location
        filteredRides = availableRides;
        break;
      case 'scheduled':
        filteredRides = availableRides.where((ride) => ride.scheduledTime != null).toList();
        break;
      case 'flexible':
        filteredRides = availableRides.where((ride) => ride.scheduledTime == null).toList();
        break;
      default:
        filteredRides = availableRides;
    }
    
    return filteredRides;
  }

  Future<void> _requestRide(Ride ride) async {
    final message = _messageController.text.trim();
    
    try {
      await RideService.requestRide(ride.id, message: message.isEmpty ? null : message);
      
      // Refresh the rides to show updated status
      await _loadRides();
      
      // Show success message
      _showSuccessSnackBar('Ride request sent successfully!');
      
      // Note: Dialog is closed by the button's onPressed callback, so no need to pop here
      
    } catch (e) {
      _showErrorSnackBar('Failed to request ride: ${e.toString()}');
      
      // Make sure loading state is reset even on error
      setState(() {
        _isLoading = false;
        _error = null;
      });
    }
  }

  Future<void> _offerToDrive(Ride ride) async {
    try {
      await RideService.offerToDriveRide(ride.id);
      
      // Show success message
      _showSuccessSnackBar('Driver offer sent successfully!');
      
      // Refresh the rides to show updated status
      await _loadRides();
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
              onPressed: () async {
                Navigator.pop(context);
                await _requestRide(ride);
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
            tooltip: 'Refresh rides',
          ),
          IconButton(
            icon: const Icon(Icons.view_list),
            onPressed: () => _toggleAllCards(),
            tooltip: _allExpanded ? 'Collapse all' : 'Expand all',
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
                  child: Column(
        children: [
          // Enhanced filter and ride count row
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryColor.withOpacity(0.05),
                        AppColors.primaryColor.withOpacity(0.02),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primaryColor.withOpacity(0.2)),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedFilter,
                    decoration: InputDecoration(
                      labelText: 'Filter Rides',
                      labelStyle: TextStyle(
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      prefixIcon: Icon(
                        Icons.filter_list,
                        color: AppColors.primaryColor,
                        size: 20,
                      ),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'all',
                        child: Row(
                          children: [
                            Icon(Icons.all_inclusive, color: AppColors.primaryColor),
                            const SizedBox(width: 12),
                            const Text('All Rides'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'nearby',
                        child: Row(
                          children: [
                            Icon(Icons.location_on, color: AppColors.primaryColor),
                            const SizedBox(width: 12),
                            const Text('Nearby'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'scheduled',
                        child: Row(
                          children: [
                            Icon(Icons.schedule, color: AppColors.primaryColor),
                            const SizedBox(width: 12),
                            const Text('Scheduled'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'flexible',
                        child: Row(
                          children: [
                            Icon(Icons.access_time, color: AppColors.primaryColor),
                            const SizedBox(width: 12),
                            const Text('Flexible Time'),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedFilter = value ?? 'all';
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryColor,
                      AppColors.primaryColor.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                      Icons.directions_car,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                      Text(
                      '${_filteredRides.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    const SizedBox(width: 4),
                      Text(
                      _filteredRides.length == 1 ? ' ride' : ' rides',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
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

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_filteredRides.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
                  onRefresh: _loadRides,
      color: AppColors.primaryColor,
      backgroundColor: Colors.white,
      strokeWidth: 3,
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

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryColor.withOpacity(0.1),
                    AppColors.primaryColor.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryColor.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: SizedBox(
                width: 72,
                height: 72,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                  strokeWidth: 4,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Finding Available Rides',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Please wait while we search for rides near you...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondaryColor,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryColor.withOpacity(0.05),
                    AppColors.primaryColor.withOpacity(0.02),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryColor.withOpacity(0.1)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Searching nearby locations...',
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
                  ),
                ),
    );
  }

  Widget _buildRideCard(Ride ride) {
    final isExpanded = _isCardExpanded(ride.id);
    
    return Card(
      elevation: 12,
      shadowColor: AppColors.primaryColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: InkWell(
        onTap: () => _toggleCardExpansion(ride.id),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [
                Colors.white,
                AppColors.backgroundColor.withOpacity(0.3),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
      child: Padding(
            padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                // Header with expand/collapse indicator
                _buildExpandableHeader(ride, isExpanded),
                
                // Show different content based on expansion state
                if (isExpanded) ...[
                  const SizedBox(height: 20),
                  _buildRouteVisualization(ride),
                  const SizedBox(height: 20),
                  _buildEnhancedRideCreatorSection(ride),
                  if (ride.driverId != null || (ride.driverOffers?.isNotEmpty ?? false)) ...[
                    const SizedBox(height: 16),
                    _buildDriverInfoSection(ride),
                  ],
                  const SizedBox(height: 20),
                  _buildRideMetrics(ride),
                  if (ride.notes != null && ride.notes!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildEnhancedNotesSection(ride),
                  ],
                  const SizedBox(height: 24),
                  _buildEnhancedActionButtons(ride),
                ] else ...[
                  // Compact view for collapsed state
                  const SizedBox(height: 16),
                  _buildCompactRideInfo(ride),
                  const SizedBox(height: 16),
                  _buildCompactActionButtons(ride),
                ],
              ],
            ),
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
          : () async {
              await _requestRide(ride);
            },
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
    String? additionalInfo;
    bool isEnabled = false;

    switch (request.status.toLowerCase()) {
      case 'pending':
        buttonColor = AppColors.warningColor;
        icon = Icons.schedule;
        label = 'Request Pending';
        subtitle = 'Waiting for driver\'s approval';
        additionalInfo = 'Typically approved within 5-10 minutes';
        break;
      case 'accepted':
        buttonColor = AppColors.successColor;
        icon = Icons.check_circle;
        label = 'Request Accepted';
        subtitle = 'You can join this ride';
        additionalInfo = 'Ride confirmed! Get ready to go';
        isEnabled = true;
        break;
      case 'declined':
        buttonColor = AppColors.errorColor;
        icon = Icons.cancel;
        label = 'Request Declined';
        subtitle = 'Try another ride';
        additionalInfo = 'Driver was unable to accommodate';
        break;
      case 'cancelled':
        buttonColor = AppColors.textSecondaryColor;
        icon = Icons.block;
        label = 'Request Cancelled';
        subtitle = 'No longer available';
        additionalInfo = 'You cancelled this request';
        break;
      default:
        buttonColor = AppColors.textSecondaryColor;
        icon = Icons.help;
        label = 'Unknown Status';
        subtitle = 'Contact support';
        additionalInfo = 'System error - please contact support';
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
              onPressed: () async {
                await _cancelRideRequest(request);
              },
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
          if (additionalInfo != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: buttonColor.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 12,
                    color: buttonColor,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      additionalInfo,
                      style: TextStyle(
                        fontSize: 11,
                        color: buttonColor,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
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
    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.errorColor.withOpacity(0.1),
                    AppColors.errorColor.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.errorColor.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                Icons.error_outline,
                size: 72,
                color: AppColors.errorColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Oops! Something went wrong',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'We couldn\'t load the available rides',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondaryColor,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.errorColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.errorColor.withOpacity(0.1)),
              ),
              child: Text(
                _error!,
                style: TextStyle(
                  color: AppColors.errorColor,
                  fontSize: 14,
                  fontFamily: 'monospace',
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _loadRides,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    elevation: 4,
                    shadowColor: AppColors.primaryColor.withOpacity(0.3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _error = null;
                      _isLoading = true;
                    });
                    _loadRides();
                  },
                  icon: const Icon(Icons.settings),
                  label: const Text('Reset'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryColor,
                    side: BorderSide(color: AppColors.primaryColor),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryColor.withOpacity(0.1),
                    AppColors.primaryColor.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryColor.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                Icons.directions_car_outlined,
                size: 72,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No rides available',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Check back later for new ride opportunities',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondaryColor,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryColor.withOpacity(0.05),
                    AppColors.primaryColor.withOpacity(0.02),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryColor.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 32,
                    color: AppColors.primaryColor,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Pro Tips',
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Try changing your filter settings\n• Check back during peak hours\n• Consider creating your own ride',
                    style: TextStyle(
                      color: AppColors.textSecondaryColor,
                      fontSize: 14,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
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
      await _loadRides(); // Refresh the rides to show updated status
      _showSuccessSnackBar('Ride request cancelled successfully!');
    } catch (e) {
      _showErrorSnackBar('Failed to cancel ride request: ${e.toString()}');
    }
  }

  Widget _buildRideHeader(Ride ride) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Row(
              children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.route,
                      size: 18,
                  color: AppColors.primaryColor,
                ),
                  ),
                  const SizedBox(width: 12),
                Expanded(
                  child: Text(
                      '${ride.pickupLocation} → ${ride.destination}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                  ),
                ),
              ],
            ),
              if (ride.scheduledTime != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                    const SizedBox(width: 42), // Align with route text
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: AppColors.warningColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Scheduled: ${ride.scheduledTime!.hour}:${ride.scheduledTime!.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: AppColors.warningColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        _buildEnhancedStatusChip(ride.status),
      ],
    );
  }

  Widget _buildRouteVisualization(Ride ride) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor.withOpacity(0.08),
            AppColors.primaryColor.withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryColor.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          // Route line visualization
          Column(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.successColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.successColor.withOpacity(0.3),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.my_location,
                  size: 10,
                  color: Colors.white,
                ),
              ),
              Container(
                width: 3,
                height: 40,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.successColor,
                      AppColors.errorColor,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.errorColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.errorColor.withOpacity(0.3),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.location_on,
                  size: 10,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Location details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.successColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'FROM',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.successColor,
                          letterSpacing: 1,
                        ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                          ride.pickupLocation,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                  ),
                ),
              ],
                  ),
            ),
            const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.errorColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'TO',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.errorColor,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Text(
                          ride.destination,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedRideCreatorSection(Ride ride) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.info.withOpacity(0.08),
            AppColors.info.withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.info.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          // Enhanced avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.info,
                  AppColors.info.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.info.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Text(
                (ride.riderName?.isNotEmpty == true) 
                    ? ride.riderName!.substring(0, 1).toUpperCase()
                    : 'U',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Creator info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Row(
              children: [
                Icon(
                      Icons.person_outline,
                  size: 16,
                      color: AppColors.info,
                ),
                    const SizedBox(width: 6),
                Text(
                      'Ride Offered By',
                      style: TextStyle(
                        color: AppColors.info,
                    fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                  Text(
                  ride.riderName ?? 'Anonymous User',
                    style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (ride.riderEmail != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.email_outlined,
                        size: 14,
                      color: AppColors.textSecondaryColor,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          ride.riderEmail!,
                          style: TextStyle(
                            color: AppColors.textSecondaryColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 14,
                      color: AppColors.primaryColor,
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primaryColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        'Posted ${_formatRelativeTime(ride.createdAt)}',
                        style: TextStyle(
                          color: AppColors.primaryColor,
                      fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                    ),
                  ),
                ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRideMetrics(Ride ride) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildEnhancedDetailChip(
          Icons.people,
          '${ride.currentPassengers}/${ride.maxPassengers}',
          AppColors.primaryColor,
          'Passengers',
        ),
        if (ride.distance != null)
          _buildEnhancedDetailChip(
            Icons.straighten,
            '${ride.distance!.toStringAsFixed(1)} km',
            AppColors.info,
            'Distance',
          ),
        if (ride.fare != null)
          _buildEnhancedDetailChip(
            Icons.attach_money,
            '\$${ride.fare!.toStringAsFixed(2)}',
            AppColors.successColor,
            'Fare',
          ),

      ],
    );
  }

  Widget _buildEnhancedNotesSection(Ride ride) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.warningColor.withOpacity(0.08),
            AppColors.warningColor.withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warningColor.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.warningColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.sticky_note_2,
              size: 18,
              color: AppColors.warningColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Additional Notes',
                  style: TextStyle(
                    color: AppColors.warningColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
              Text(
                ride.notes!,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                ),
              ),
            ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedActionButtons(Ride ride) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showRideDetails(ride),
                icon: const Icon(Icons.info_outline, size: 18),
                label: const Text('View Details'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryColor,
                  side: BorderSide(color: AppColors.primaryColor, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: _buildEnhancedRequestButton(ride),
            ),
          ],
        ),
        // Driver offer button
        if (ride.driverId == null && !_isMyRide(ride) && _currentUser?.isDriver == true) ...[
            const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _offerToDrive(ride),
              icon: const Icon(Icons.directions_car, size: 20),
              label: const Text('Offer to Drive This Ride'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.info,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 4,
                shadowColor: AppColors.info.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEnhancedStatusChip(String status) {
    Color color;
    IconData icon;
    
    switch (status.toLowerCase()) {
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color,
            color.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            status.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedDetailChip(IconData icon, String text, Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
              children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                text,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.7),
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedRequestButton(Ride ride) {
    final myRequest = _getMyRequestForRide(ride.id);
    final isRequested = _hasRequestedRide(ride.id);

    if (isRequested && myRequest != null) {
      return _buildRequestStatusButton(myRequest);
    }

    return ElevatedButton.icon(
                  onPressed: ride.currentPassengers >= ride.maxPassengers 
                      ? null 
          : () async {
              await _requestRide(ride);
            },
      icon: Icon(
        ride.currentPassengers >= ride.maxPassengers 
            ? Icons.block 
            : Icons.add_circle_outline,
        size: 20,
      ),
      label: Text(
        ride.currentPassengers >= ride.maxPassengers 
            ? 'Ride Full' 
            : 'Request to Join',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
                  style: ElevatedButton.styleFrom(
        backgroundColor: ride.currentPassengers >= ride.maxPassengers 
            ? AppColors.textSecondaryColor
            : AppColors.primaryColor,
                    foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        elevation: 6,
        shadowColor: ride.currentPassengers >= ride.maxPassengers 
            ? AppColors.textSecondaryColor.withOpacity(0.3)
            : AppColors.primaryColor.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildExpandableHeader(Ride ride, bool isExpanded) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.route,
                      size: 18,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                  child: Text(
                      '${ride.pickupLocation} → ${ride.destination}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                  ),
                ),
              ],
              ),
              if (ride.scheduledTime != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const SizedBox(width: 42), // Align with route text
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: AppColors.warningColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Scheduled: ${ride.scheduledTime!.hour}:${ride.scheduledTime!.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: AppColors.warningColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
            ),
          ],
        ),
              ],
            ],
          ),
        ),
        // Expand/Collapse indicator
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primaryColor.withOpacity(0.3)),
          ),
          child: Icon(
            isExpanded ? Icons.expand_less : Icons.expand_more,
            color: AppColors.primaryColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        _buildEnhancedStatusChip(ride.status),
      ],
    );
  }

  Widget _buildCompactRideInfo(Ride ride) {
    return Column(
      children: [
        // Compact route info
        Row(
          children: [
            Icon(
              Icons.my_location,
              size: 16,
              color: AppColors.successColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                ride.pickupLocation,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        Container(
          width: 2,
          height: 16,
          margin: const EdgeInsets.only(left: 7),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.3),
          ),
        ),
        Row(
          children: [
            Icon(
              Icons.location_on,
              size: 16,
              color: AppColors.errorColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                ride.destination,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Compact metrics
        Row(
          children: [
            _buildCompactChip(
              Icons.people,
              '${ride.currentPassengers}/${ride.maxPassengers}',
              AppColors.primaryColor,
            ),
            const SizedBox(width: 8),
            if (ride.distance != null)
              _buildCompactChip(
                Icons.straighten,
                '${ride.distance!.toStringAsFixed(1)} km',
                AppColors.info,
              ),
            if (ride.fare != null) ...[
              const SizedBox(width: 8),
              _buildCompactChip(
                Icons.attach_money,
                '\$${ride.fare!.toStringAsFixed(2)}',
                AppColors.successColor,
              ),
            ],
          ],
        ),
        // Compact creator info
        const SizedBox(height: 12),
        Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.info,
              child: Text(
                (ride.riderName?.isNotEmpty == true) 
                    ? ride.riderName!.substring(0, 1).toUpperCase()
                    : 'U',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ride.riderName ?? 'Anonymous User',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Created ${_formatRelativeTime(ride.createdAt)}',
                    style: TextStyle(
                      color: AppColors.textSecondaryColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        // Compact notes if available
        if (ride.notes != null && ride.notes!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.warningColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.warningColor.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.note,
                  size: 12,
                  color: AppColors.warningColor,
                ),
                const SizedBox(width: 4),
                Text(
                  ride.notes!,
                  style: TextStyle(
                    color: AppColors.warningColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCompactChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactActionButtons(Ride ride) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showRideDetails(ride),
            icon: const Icon(Icons.info_outline, size: 16),
            label: const Text('Details'),
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
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: _buildCompactRequestButton(ride),
        ),
      ],
    );
  }

  Widget _buildCompactRequestButton(Ride ride) {
    final myRequest = _getMyRequestForRide(ride.id);
    final isRequested = _hasRequestedRide(ride.id);

    if (isRequested && myRequest != null) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: _getRequestStatusColor(myRequest.status).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _getRequestStatusColor(myRequest.status).withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getRequestStatusIcon(myRequest.status),
              size: 16,
              color: _getRequestStatusColor(myRequest.status),
            ),
            const SizedBox(width: 6),
            Text(
              _getRequestStatusText(myRequest.status),
              style: TextStyle(
                color: _getRequestStatusColor(myRequest.status),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: ride.currentPassengers >= ride.maxPassengers 
          ? null 
          : () async {
              await _requestRide(ride);
            },
      icon: Icon(
        ride.currentPassengers >= ride.maxPassengers 
            ? Icons.block 
            : Icons.add_circle_outline,
        size: 16,
      ),
      label: Text(
        ride.currentPassengers >= ride.maxPassengers 
            ? 'Full' 
            : 'Join',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: ride.currentPassengers >= ride.maxPassengers 
            ? AppColors.textSecondaryColor
            : AppColors.primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Color _getRequestStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.warningColor;
      case 'accepted':
        return AppColors.successColor;
      case 'declined':
        return AppColors.errorColor;
      case 'cancelled':
        return AppColors.textSecondaryColor;
      default:
        return AppColors.textSecondaryColor;
    }
  }

  IconData _getRequestStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.schedule;
      case 'accepted':
        return Icons.check_circle;
      case 'declined':
        return Icons.cancel;
      case 'cancelled':
        return Icons.block;
      default:
        return Icons.help;
    }
  }

  String _getRequestStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'declined':
        return 'Declined';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }



  Widget _buildRideCreatorSection(Ride ride) {
    // Keep the old method for backward compatibility
    return _buildEnhancedRideCreatorSection(ride);
  }

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}
