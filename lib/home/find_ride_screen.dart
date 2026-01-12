import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../src/services/ride_service.dart';
import '../src/models/ride.dart';

class FindRideScreen extends StatefulWidget {
  const FindRideScreen({super.key});

  @override
  State<FindRideScreen> createState() => _FindRideScreenState();
}

class _FindRideScreenState extends State<FindRideScreen> {
  final _rideService = RideService();
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  // Using theme colors
  Color get pastelMint => Theme.of(context).colorScheme.primary;
  Color get pastelMintSoft => Theme.of(context).colorScheme.primary.withOpacity(0.2);
  Color get pastelPink => Theme.of(context).colorScheme.secondary;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find a Ride'),
        elevation: 0,
      ),
      body: Container(
        color: Theme.of(context).colorScheme.surface,
        child: SafeArea(
          child: Column(
            children: [
              // Search section
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Where are you going?',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // From field
                    _buildSearchField(
                      controller: _fromController,
                      hint: "From (optional)",
                    ),
                    const SizedBox(height: 16),

                    // To field
                    _buildSearchField(
                      controller: _toController,
                      hint: "To (optional)",
                    ),
                  ],
                ),
              ),

              // Available rides list
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  child: StreamBuilder<List<Ride>>(
                    stream: _rideService.watchAvailableRides(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      final rides = snapshot.data ?? [];

                      if (rides.isEmpty) {
                        return _buildEmptyState();
                      }

                      // Filter rides
                      final filteredRides = rides.where((ride) {
                        final fromMatch = _fromController.text.isEmpty ||
                            ride.fromLocation.toLowerCase().contains(_fromController.text.toLowerCase());
                        final toMatch = _toController.text.isEmpty ||
                            ride.toLocation.toLowerCase().contains(_toController.text.toLowerCase());
                        return fromMatch && toMatch;
                      }).toList();

                      return ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: filteredRides.length,
                        itemBuilder: (context, index) {
                          final ride = filteredRides[index];
                          return _buildRideCard(ride);
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------
  // BEAUTIFUL NEW SEARCH FIELD
  // ---------------------------
  Widget _buildSearchField({required TextEditingController controller, required String hint}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          prefixIcon: Icon(Icons.location_on, color: Theme.of(context).colorScheme.onSurfaceVariant),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  // ---------------------------
  // EMPTY STATE UI
  // ---------------------------
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_car, size: 70, color: Theme.of(context).colorScheme.onSurfaceVariant),
          SizedBox(height: 18),
          Text('No rides available', style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.onSurface)),
          SizedBox(height: 6),
          Text('Try different locations', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  // ---------------------------
  // BEAUTIFUL MODERN RIDE CARD
  // ---------------------------
  Widget _buildRideCard(Ride ride) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ROUTE
            Row(
              children: [
                Icon(Icons.location_on, color: pastelMint, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${ride.fromLocation} → ${ride.toLocation}',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // DRIVER INFO
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: pastelMintSoft,
                  child: Icon(Icons.person, color: pastelMint),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ride.driverName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface)),
                      Text(
                        ride.vehicleType,
                        style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),

                // SEATS BADGE
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: pastelMint,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${ride.availableSeats} seats',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // PRICE + TIME
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Rs. ${ride.pricePerSeat}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: pastelMint,
                  ),
                ),
                Text(
                  '${ride.departureTime.day}/${ride.departureTime.month} '
                  '${ride.departureTime.hour}:${ride.departureTime.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // ACTION BUTTONS
            Row(
              children: [
                // DETAILS BUTTON
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/ride-details', arguments: ride.id);
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: pastelMint),
                      foregroundColor: pastelMint,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Details'),
                  ),
                ),
                const SizedBox(width: 12),

                // BOOK BUTTON
                Expanded(
                  child: ElevatedButton(
                    onPressed: (ride.availableSeats > 0 && ride.driverId != user?.uid)
                        ? () => _showBookingDialog(ride)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ride.driverId == user?.uid ? Colors.grey : pastelPink,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(ride.driverId == user?.uid ? 'Your Ride' : 'Book'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------
  // BOOKING DIALOG
  // ---------------------------
  void _showBookingDialog(Ride ride) {
    int selectedSeats = 1;
    final _pickupController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Book Seats'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Available seats: ${ride.availableSeats}'),
              const SizedBox(height: 16),

              // Seat counter
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: selectedSeats > 1 ? () => setState(() => selectedSeats--) : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Text(
                    '$selectedSeats',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: selectedSeats < ride.availableSeats
                        ? () => setState(() => selectedSeats++)
                        : null,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Pickup location field
              TextField(
                controller: _pickupController,
                decoration: const InputDecoration(
                  labelText: 'Pickup Location',
                  hintText: 'Enter your pickup location',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Total: Rs. ${ride.pricePerSeat * selectedSeats}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _proceedToPayment(ride, selectedSeats, _pickupController.text.trim());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              child: const Text('Book Now'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------
// PAYMENT NAVIGATION
// ---------------------------
  void _proceedToPayment(Ride ride, int seats, String pickupLocation) {
    Navigator.pushNamed(
      context,
      '/payment',
      arguments: {
        'rideId': ride.id,
        'seatsBooked': seats,
        'amount': ride.pricePerSeat * seats,
        'pickupLocation': pickupLocation,
      },
    );
  }
}
