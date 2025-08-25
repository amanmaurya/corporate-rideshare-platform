import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/ride_service.dart';
import '../../services/location_service.dart';
import '../../utils/constants.dart';

class CreateRideScreen extends StatefulWidget {
  final VoidCallback? onRideCreated;
  
  const CreateRideScreen({Key? key, this.onRideCreated}) : super(key: key);

  @override
  State<CreateRideScreen> createState() => _CreateRideScreenState();
}

class _CreateRideScreenState extends State<CreateRideScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pickupController = TextEditingController();
  final _destinationController = TextEditingController();
  final _notesController = TextEditingController();
  final _fareController = TextEditingController();

  double? _pickupLat, _pickupLng;
  double? _destLat, _destLng;
  DateTime? _scheduledTime;
  int _vehicleCapacity = 4;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _destinationController.dispose();
    _notesController.dispose();
    _fareController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    final position = await LocationService.getCurrentPosition();
    if (position != null) {
      setState(() {
        _pickupLat = position.latitude;
        _pickupLng = position.longitude;
      });
    }
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        setState(() {
          _scheduledTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _createRide() async {
    if (!_formKey.currentState!.validate()) return;

    if (_pickupLat == null || _pickupLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set pickup location'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    if (_destLat == null || _destLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set destination location'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await RideService.createRide(
        pickupLocation: _pickupController.text,
        destination: _destinationController.text,
        pickupLatitude: _pickupLat!,
        pickupLongitude: _pickupLng!,
        destinationLatitude: _destLat!,
        destinationLongitude: _destLng!,
        scheduledTime: _scheduledTime,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        vehicleCapacity: _vehicleCapacity,
        fare: _fareController.text.isNotEmpty ? double.tryParse(_fareController.text) : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ride created successfully!'),
            backgroundColor: AppColors.successColor,
          ),
        );
        
        // Call the callback to refresh dashboard data
        widget.onRideCreated?.call();
        
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Ride'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pickup Location
              TextFormField(
                controller: _pickupController,
                decoration: InputDecoration(
                  labelText: 'Pickup Location',
                  prefixIcon: const Icon(Icons.location_on),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.my_location),
                    onPressed: _getCurrentLocation,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter pickup location';
                  }
                  return null;
                },
                onChanged: (value) {
                  // TODO: Implement geocoding
                  // For now, using dummy coordinates
                  _pickupLat = AppConstants.defaultLatitude;
                  _pickupLng = AppConstants.defaultLongitude;
                },
              ),
              const SizedBox(height: 16),

              // Destination
              TextFormField(
                controller: _destinationController,
                decoration: InputDecoration(
                  labelText: 'Destination',
                  prefixIcon: const Icon(Icons.flag),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter destination';
                  }
                  return null;
                },
                onChanged: (value) {
                  // TODO: Implement geocoding
                  // For now, using dummy coordinates
                  _destLat = AppConstants.defaultLatitude + 0.1;
                  _destLng = AppConstants.defaultLongitude + 0.1;
                },
              ),
              const SizedBox(height: 16),

              // Scheduled Time
              Card(
                child: ListTile(
                  leading: const Icon(Icons.schedule),
                  title: const Text('Scheduled Time'),
                  subtitle: Text(_scheduledTime == null 
                      ? 'Leave now' 
                      : '${_scheduledTime!.day}/${_scheduledTime!.month}/${_scheduledTime!.year} at ${_scheduledTime!.hour}:${_scheduledTime!.minute.toString().padLeft(2, '0')}'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: _selectDateTime,
                ),
              ),
              const SizedBox(height: 16),

              // Max Passengers
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vehicle Capacity: $_vehicleCapacity',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Slider(
                        value: _vehicleCapacity.toDouble(),
                        min: 1,
                        max: 6,
                        divisions: 5,
                        label: _vehicleCapacity.toString(),
                        onChanged: (value) {
                          setState(() => _vehicleCapacity = value.round());
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Fare (Optional)
              TextFormField(
                controller: _fareController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Fare (Optional)',
                  hintText: 'Enter fare amount...',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final fare = double.tryParse(value);
                    if (fare == null || fare <= 0) {
                      return 'Please enter a valid fare amount';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'Any additional information for passengers...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Create Ride Button
              ElevatedButton(
                onPressed: _isLoading ? null : _createRide,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
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
                    : const Text(
                        'Create Ride',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
