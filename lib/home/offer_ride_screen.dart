import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../src/services/ride_service.dart';
import '../src/services/user_service.dart';
import '../src/models/user_profile.dart';

class OfferRideScreen extends StatefulWidget {
  const OfferRideScreen({super.key});

  @override
  State<OfferRideScreen> createState() => _OfferRideScreenState();
}

class _OfferRideScreenState extends State<OfferRideScreen> {
  final _formKey = GlobalKey<FormState>();
  final _rideService = RideService();
  final _userService = UserService();

  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _seatsController = TextEditingController();
  final _priceController = TextEditingController();
  final _vehicleController = TextEditingController();

  DateTime _departureTime = DateTime.now().add(const Duration(hours: 1));
  bool _isLoading = false;

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _seatsController.dispose();
    _priceController.dispose();
    _vehicleController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _departureTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_departureTime),
      );

      if (pickedTime != null) {
        setState(() {
          _departureTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _submitRide() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to offer a ride')),
        );
        return;
      }

      final userProfile = await _userService.getUserProfile(user.uid);
      if (userProfile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User profile not found')),
        );
        return;
      }

      await _rideService.createDriverRide(
        driverId: user.uid,
        driverName: userProfile.name,
        fromLocation: _fromController.text.trim(),
        toLocation: _toController.text.trim(),
        availableSeats: int.parse(_seatsController.text),
        pricePerSeat: double.parse(_priceController.text),
        vehicleType: _vehicleController.text.trim(),
        departureTime: _departureTime,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ride posted successfully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error posting ride: $e')),
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
        title: const Text('Offer a Ride'),
      ),
      body: Container(
        color: Theme.of(context).colorScheme.surface,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Post Your Ride',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Fill in the details to offer a ride to fellow students',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // From location
                  _buildTextField(
                    controller: _fromController,
                    label: 'From',
                    hint: 'Enter pickup location',
                    prefixWidget: Icon(Icons.location_on, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter pickup location';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // To location
                  _buildTextField(
                    controller: _toController,
                    label: 'To',
                    hint: 'Enter destination',
                    prefixWidget: Icon(Icons.location_on, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter destination';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Seats and Price row
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _seatsController,
                          label: 'Available Seats',
                          hint: '4',
                          prefixWidget: Icon(Icons.people, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Required';
                            }
                            final seats = int.tryParse(value!);
                            if (seats == null || seats <= 0) {
                              return 'Invalid';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _priceController,
                          label: 'Price per Seat',
                          hint: '50',
                          prefixWidget: Text('₨', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Required';
                            }
                            final price = double.tryParse(value!);
                            if (price == null || price <= 0) {
                              return 'Invalid';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Vehicle type
                  _buildTextField(
                    controller: _vehicleController,
                    label: 'Vehicle Type',
                    hint: 'e.g., Sedan, SUV, Hatchback',
                    prefixWidget: Icon(Icons.directions_car, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter vehicle type';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Departure time
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Departure Time',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectDateTime(context),
                          child: Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${_departureTime.day}/${_departureTime.month}/${_departureTime.year} ${_departureTime.hour}:${_departureTime.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitRide,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text(
                              'Post Ride',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required Widget prefixWidget,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          hintText: hint,
          hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7)),
          prefixIcon: prefixWidget,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        validator: validator,
      ),
    );
  }
}