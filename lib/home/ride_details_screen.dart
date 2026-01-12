import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../src/services/ride_service.dart';
import '../src/services/user_service.dart';
import '../src/models/ride.dart';
import '../src/models/user_profile.dart';

class RideDetailsScreen extends StatefulWidget {
  final String rideId;

  const RideDetailsScreen({super.key, required this.rideId});

  @override
  State<RideDetailsScreen> createState() => _RideDetailsScreenState();
}

class _RideDetailsScreenState extends State<RideDetailsScreen> {
  final _rideService = RideService();
  final _userService = UserService();
  int _seatsToBook = 1;
  bool _isBooking = false;
  String _pickupLocation = '';
  String _phoneNumber = '';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final profile = await _userService.getUserProfile(user.uid);
      if (profile != null) {
        setState(() {
          _phoneNumber = profile.phone;
        });
      }
    }
  }

  // Using theme colors
  Color get pastelMint => Theme.of(context).colorScheme.primary.withOpacity(0.2);
  Color get pastelPeach => Theme.of(context).colorScheme.secondary.withOpacity(0.2);
  Color get pastelBlue => Theme.of(context).colorScheme.tertiary.withOpacity(0.2);
  Color get pastelPink => Theme.of(context).colorScheme.surface.withOpacity(0.8);
  Color get pastelPrimary => Theme.of(context).colorScheme.primary;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ride Details',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
      ),
      body: StreamBuilder<Ride?>(
        stream: _rideService.watchRideDetails(widget.rideId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildGradientContainer(
              const Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError) {
            return _buildGradientContainer(
              Center(child: Text("Error: ${snapshot.error}")),
            );
          }

          final ride = snapshot.data;
          if (ride == null) {
            return _buildGradientContainer(
              const Center(child: Text("Ride not found")),
            );
          }

          final user = FirebaseAuth.instance.currentUser;
          final isDriver = user?.uid == ride.driverId;
          final hasBooked = user != null && ride.bookedRiders.contains(user.uid);

          return _buildGradientContainer(
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildRouteCard(ride),
                    const SizedBox(height: 20),
                    _buildInfoCard(ride),
                    const SizedBox(height: 25),

                    // Booking card
                    if (!isDriver && user != null)
                      _buildBookingSection(ride, hasBooked),

                    if (isDriver) ...[
                      _buildDriverInfo(),
                      const SizedBox(height: 20),
                      _buildBookedRidersSection(ride),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Background wrapper
  Widget _buildGradientContainer(Widget child) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: child,
    );
  }

  // ✨ Route Card (From → To)
  Widget _buildRouteCard(Ride ride) {
    return _buildSoftCard(
      Column(
        children: [
          _buildRouteRow("From", ride.fromLocation, pastelMint),
          const SizedBox(height: 16),
          Divider(color: Colors.grey.shade300),
          const SizedBox(height: 16),
          _buildRouteRow("To", ride.toLocation, pastelBlue),
        ],
      ),
    );
  }

  Widget _buildRouteRow(String label, String loc, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.35),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.location_on, color: Theme.of(context).colorScheme.onSurface, size: 26),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  )),
              Text(loc,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  )),
            ],
          ),
        ),
      ],
    );
  }

  // ✨ Ride Info Card
  Widget _buildInfoCard(Ride ride) {
    return _buildSoftCard(
      Column(
        children: [
          _buildInfoRow("Driver", ride.driverName, Icons.person),
          const Divider(),
          _buildInfoRow("Vehicle", ride.vehicleType, Icons.directions_car),
          const Divider(),
          _buildInfoRow(
            "Departure",
            "${ride.departureTime.day}/${ride.departureTime.month}/${ride.departureTime.year} "
            "${ride.departureTime.hour}:${ride.departureTime.minute.toString().padLeft(2, '0')}",
            Icons.access_time,
          ),
          const Divider(),
          _buildInfoRow(
            "Seats",
            "${ride.availableSeats} / ${ride.totalSeats}",
            Icons.event_seat,
          ),
          const Divider(),
          _buildInfoRow(
            "Price",
            "Rs. ${ride.pricePerSeat}",
            Icons.monetization_on,
          ),
        ],
      ),
    );
  }

  // Soft pastel card style
  Widget _buildSoftCard(Widget child) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 24),
        const SizedBox(width: 16),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  // ✨ Booking Section
  Widget _buildBookingSection(Ride ride, bool hasBooked) {
    if (hasBooked) {
      final user = FirebaseAuth.instance.currentUser;
      final pickupLocation = user != null ? ride.riderPickupLocations[user.uid] ?? 'Not specified' : 'Not specified';

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: pastelMint.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.green, size: 32),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    "You have already booked this ride!",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on, color: const Color.fromARGB(255, 239, 235, 235), size: 20),
                const SizedBox(width: 8),
                Text(
                  'Pickup: $pickupLocation',
                  style: TextStyle(
                    color: const Color.fromARGB(255, 221, 218, 218),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return _buildSoftCard(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Book Seats",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Phone number field
          TextField(
            decoration: InputDecoration(
              labelText: 'Phone Number',
              hintText: 'Enter your phone number',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
            controller: TextEditingController(text: _phoneNumber),
            onChanged: (value) => _phoneNumber = value,
          ),

          const SizedBox(height: 16),

          // Pickup location field
          TextField(
            decoration: InputDecoration(
              labelText: 'Pickup Location',
              hintText: 'Enter pickup location',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.location_on),
            ),
            controller: TextEditingController(text: _pickupLocation),
            onChanged: (value) => _pickupLocation = value,
          ),

          const SizedBox(height: 16),

          // Seats dropdown
          Row(
            children: [
              const Text("Number of seats:"),
              const SizedBox(width: 16),
              DropdownButton<int>(
                value: _seatsToBook,
                borderRadius: BorderRadius.circular(12),
                items: List.generate(
                  ride.availableSeats > 4 ? 4 : ride.availableSeats,
                  (i) => DropdownMenuItem(
                    value: i + 1,
                    child: Text("${i + 1}"),
                  ),
                ),
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _seatsToBook = v);
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: 16),
          Text(
            "Total: Rs. ${ride.pricePerSeat * _seatsToBook}",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),

          const SizedBox(height: 20),

          // Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isBooking ? null : () => _bookRide(ride),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isBooking
                  ? CircularProgressIndicator(color: Theme.of(context).colorScheme.onPrimary)
                  : const Text(
                      "Book Now",
                      style: TextStyle(fontSize: 18),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ✨ Driver-only message
  Widget _buildDriverInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: pastelMint.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: const [
          Icon(Icons.info, color: Colors.teal, size: 32),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              "This is your ride. Passengers can book seats.",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✨ Booked riders list for drivers
  Widget _buildBookedRidersSection(Ride ride) {
    if (ride.bookedRiders.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: pastelBlue.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: const [
            Icon(Icons.people, color: Colors.blue, size: 32),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                "No riders have booked seats yet.",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return _buildSoftCard(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Booked Riders",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...ride.bookedRiders.map((riderId) => FutureBuilder<UserProfile?>(
                future: _userService.getUserProfile(riderId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: CircularProgressIndicator(),
                    );
                  }

                  final profile = snapshot.data;
                  final seats = ride.riderBookings[riderId] ?? 0;
                  final pickup = ride.riderPickupLocations[riderId] ?? 'Not specified';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 70, 66, 66),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.person, color: Colors.grey.shade600, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              profile?.name ?? 'Unknown Rider',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.phone, color: Colors.grey.shade600, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              profile?.phone ?? 'No phone',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on, color: Colors.grey.shade600, size: 16),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Pickup: $pickup',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.flag, color: Colors.grey.shade600, size: 16),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Drop: ${ride.toLocation}',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.event_seat, color: Colors.grey.shade600, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Seats booked: $seats',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              )),
        ],
      ),
    );
  }

  // Booking logic
  Future<void> _bookRide(Ride ride) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Validate inputs
    if (_phoneNumber.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your phone number.")),
      );
      return;
    }

    if (_pickupLocation.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter pickup location.")),
      );
      return;
    }

    setState(() => _isBooking = true);

    try {
      // Update user profile with phone if changed
      final currentProfile = await _userService.getUserProfile(user.uid);
      if (currentProfile != null && currentProfile.phone != _phoneNumber.trim()) {
        final updatedProfile = currentProfile.copyWith(phone: _phoneNumber.trim());
        await _userService.updateUserProfile(updatedProfile);
      }

      final success = await _rideService.bookSeats(
        rideId: ride.id,
        riderId: user.uid,
        seatsToBook: _seatsToBook,
        pickupLocation: _pickupLocation.trim(),
      );

      if (success && mounted) {
        Navigator.pushNamed(
          context,
          '/payment',
          arguments: {
            'rideId': ride.id,
            'seatsBooked': _seatsToBook,
            'amount': ride.pricePerSeat * _seatsToBook,
            'pickupLocation': _pickupLocation.trim(),
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to book seats.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _isBooking = false);
    }
  }
}
