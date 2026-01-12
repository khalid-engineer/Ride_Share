import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../src/services/ride_service.dart';
import '../src/models/ride.dart';

class MyRidesScreen extends StatefulWidget {
  const MyRidesScreen({super.key});

  @override
  State<MyRidesScreen> createState() => _MyRidesScreenState();
}

class _MyRidesScreenState extends State<MyRidesScreen> with SingleTickerProviderStateMixin {
  final _rideService = RideService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please login to view your rides')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Rides'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'As Driver'),
            Tab(text: 'As Passenger'),
          ],
        ),
      ),
      body: Container(
        color: Theme.of(context).colorScheme.surface,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildRidesList(
              stream: _rideService.watchDriverRides(user.uid),
              emptyMessage: 'You haven\'t posted any rides yet',
              emptySubtitle: 'Tap the + button to offer a ride',
            ),
            _buildRidesList(
              stream: _rideService.watchRiderBookedRides(user.uid),
              emptyMessage: 'You haven\'t booked any rides yet',
              emptySubtitle: 'Find rides to book',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRidesList({
    required Stream<List<Ride>> stream,
    required String emptyMessage,
    required String emptySubtitle,
  }) {
    return StreamBuilder<List<Ride>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final rides = snapshot.data ?? [];

        if (rides.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.directions_car,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  emptyMessage,
                  style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  emptySubtitle,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: rides.length,
          itemBuilder: (context, index) {
            final ride = rides[index];
            return _buildRideCard(ride);
          },
        );
      },
    );
  }

  Widget _buildRideCard(Ride ride) {
    final user = FirebaseAuth.instance.currentUser;
    final isDriver = user?.uid == ride.driverId;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/ride-details',
            arguments: ride.id,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// --- ROUTE TITLE SECTION ---
              Row(
                children: [
                  Icon(Icons.location_on, color: Theme.of(context).colorScheme.primary, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${ride.fromLocation} → ${ride.toLocation}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  _buildRoleBadge(isDriver),
                ],
              ),

              const SizedBox(height: 14),

              /// --- DATE & TIME ---
              Row(
                children: [
                  Icon(Icons.access_time, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    '${ride.departureTime.day}/${ride.departureTime.month}/${ride.departureTime.year} '
                    '${ride.departureTime.hour}:${ride.departureTime.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              /// --- VEHICLE & SEATS ---
              Row(
                children: [
                  Icon(Icons.directions_car, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 18),
                  const SizedBox(width: 6),
                  Text(ride.vehicleType,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14)),
                  const SizedBox(width: 20),
                  Icon(Icons.people, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    isDriver
                        ? '${ride.bookedSeats} booked, ${ride.availableSeats} left'
                        : '${ride.availableSeats}/${ride.totalSeats} seats',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              /// --- PRICE + BOOKINGS ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Rs. ${ride.pricePerSeat} / seat',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  if (isDriver && ride.bookedRiders.isNotEmpty)
                    _buildBookedBadge(ride.bookedRiders.length),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ------------------- BADGES -------------------

  Widget _buildRoleBadge(bool isDriver) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDriver ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Theme.of(context).colorScheme.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isDriver ? 'Driver' : 'Passenger',
        style: TextStyle(
          color: isDriver ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildBookedBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$count booked',
        style: TextStyle(
          color: Theme.of(context).colorScheme.tertiary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
