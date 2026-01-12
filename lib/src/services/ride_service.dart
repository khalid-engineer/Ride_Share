import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ride.dart';
import 'notification_manager.dart';

class RideService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationManager _notificationManager = NotificationManager();

  /// Create a new ride posted by a driver
  Future<String> createDriverRide({
    required String driverId,
    required String driverName,
    required String fromLocation,
    required String toLocation,
    required int availableSeats,
    required double pricePerSeat,
    required String vehicleType,
    DateTime? departureTime,
  }) async {
    final rideId = _firestore.collection('rides').doc().id;

    final ride = Ride(
      id: rideId,
      driverId: driverId,
      driverName: driverName,
      fromLocation: fromLocation,
      toLocation: toLocation,
      totalSeats: availableSeats,
      availableSeats: availableSeats,
      pricePerSeat: pricePerSeat,
      vehicleType: vehicleType,
      departureTime: departureTime ?? DateTime.now().add(const Duration(hours: 1)),
      createdAt: DateTime.now(),
      bookedRiders: [],
      riderBookings: {},
    );

    await _firestore.collection('rides').doc(rideId).set(ride.toMap());

    return rideId;
  }

  /// Book seats for a rider with notification
  Future<bool> bookSeats({
    required String rideId,
    required String riderId,
    required int seatsToBook,
    String? pickupLocation,
  }) async {
    Ride? ride;
    String? riderName;
    
    // Get rider name for notification
    try {
      final riderDoc = await _firestore.collection('users').doc(riderId).get();
      if (riderDoc.exists) {
        final riderData = riderDoc.data() as Map<String, dynamic>;
        riderName = riderData['name'] as String? ?? 'A rider';
      }
    } catch (e) {
      print('Error fetching rider name: $e');
      riderName = 'A rider';
    }

    final success = await _firestore.runTransaction((transaction) async {
      final rideRef = _firestore.collection('rides').doc(rideId);
      final rideSnapshot = await transaction.get(rideRef);

      if (!rideSnapshot.exists) {
        return false;
      }

      final rideData = rideSnapshot.data()!;
      final currentAvailableSeats = rideData['availableSeats'] as int;

      if (currentAvailableSeats < seatsToBook) {
        return false; // Not enough seats available
      }

      // Create Ride object for notification
      ride = Ride.fromMap(rideId, rideData);

      // Update available seats
      final newAvailableSeats = currentAvailableSeats - seatsToBook;

      // Update booked riders list
      final bookedRiders = List<String>.from(rideData['bookedRiders'] ?? []);
      if (!bookedRiders.contains(riderId)) {
        bookedRiders.add(riderId);
      }

      // Update rider bookings map
      final riderBookings = Map<String, int>.from(rideData['riderBookings'] ?? {});
      riderBookings[riderId] = (riderBookings[riderId] ?? 0) + seatsToBook;

      // Update rider pickup locations
      final riderPickupLocations = Map<String, String>.from(rideData['riderPickupLocations'] ?? {});
      if (pickupLocation != null && pickupLocation.isNotEmpty) {
        riderPickupLocations[riderId] = pickupLocation;
      }

      transaction.update(rideRef, {
        'availableSeats': newAvailableSeats,
        'bookedRiders': bookedRiders,
        'riderBookings': riderBookings,
        'riderPickupLocations': riderPickupLocations,
      });

      return true;
    });

    // If booking was successful, send notification to driver
    if (success && ride != null && riderName != null) {
      try {
        await _notificationManager.sendRideBookingNotification(
          rideId: rideId,
          riderId: riderId,
          seatsBooked: seatsToBook,
          pickupLocation: pickupLocation,
        );
      } catch (e) {
        print('Error sending notification: $e');
        // Don't fail the booking if notification fails
      }
    }

    return success;
  }

  /// Watch ride details for real-time updates
  Stream<Ride?> watchRideDetails(String rideId) {
    return _firestore
        .collection('rides')
        .doc(rideId)
        .snapshots()
        .map((snapshot) {
          if (snapshot.exists) {
            return Ride.fromMap(snapshot.id, snapshot.data()!);
          }
          return null;
        });
  }

  /// Get all available rides
  Stream<List<Ride>> watchAvailableRides() {
    return _firestore
        .collection('rides')
        .where('availableSeats', isGreaterThan: 0)
        .orderBy('availableSeats', descending: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          final now = DateTime.now();
          return snapshot.docs
              .map((doc) => Ride.fromMap(doc.id, doc.data()))
              .where((ride) => ride.departureTime.isAfter(now) &&
                               ride.fromLocation != 'Unknown Location' &&
                               ride.toLocation != 'Unknown Location')
              .toList();
        });
  }

  /// Get rides posted by a specific driver
  Stream<List<Ride>> watchDriverRides(String driverId) {
    return _firestore
        .collection('rides')
        .where('driverId', isEqualTo: driverId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          final now = DateTime.now();
          return snapshot.docs
              .map((doc) => Ride.fromMap(doc.id, doc.data()))
              .where((ride) => ride.departureTime.isAfter(now) &&
                               ride.fromLocation != 'Unknown Location' &&
                               ride.toLocation != 'Unknown Location')
              .toList();
        });
  }

  /// Get rides booked by a specific rider
  Stream<List<Ride>> watchRiderBookedRides(String riderId) {
    return _firestore
        .collection('rides')
        .where('bookedRiders', arrayContains: riderId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          final now = DateTime.now();
          return snapshot.docs
              .map((doc) => Ride.fromMap(doc.id, doc.data()))
              .where((ride) => ride.departureTime.isAfter(now) &&
                               ride.fromLocation != 'Unknown Location' &&
                               ride.toLocation != 'Unknown Location')
              .toList();
        });
  }

  /// Cancel seat booking with notification
  Future<bool> cancelBooking({
    required String rideId,
    required String riderId,
    required int seatsToCancel,
  }) async {
    Ride? ride;
    
    final success = await _firestore.runTransaction((transaction) async {
      final rideRef = _firestore.collection('rides').doc(rideId);
      final rideSnapshot = await transaction.get(rideRef);

      if (!rideSnapshot.exists) {
        return false;
      }

      final rideData = rideSnapshot.data()!;
      final riderBookings = Map<String, int>.from(rideData['riderBookings'] ?? {});
      final currentBookedSeats = riderBookings[riderId] ?? 0;

      if (currentBookedSeats < seatsToCancel) {
        return false; // Cannot cancel more seats than booked
      }

      // Create Ride object for potential notification
      ride = Ride.fromMap(rideId, rideData);

      final newBookedSeats = currentBookedSeats - seatsToCancel;
      final currentAvailableSeats = rideData['availableSeats'] as int;
      final newAvailableSeats = currentAvailableSeats + seatsToCancel;

      // Update rider bookings
      if (newBookedSeats <= 0) {
        riderBookings.remove(riderId);
      } else {
        riderBookings[riderId] = newBookedSeats;
      }

      // Update booked riders list
      final bookedRiders = List<String>.from(rideData['bookedRiders'] ?? []);
      if (riderBookings.isEmpty) {
        bookedRiders.remove(riderId);
      }

      transaction.update(rideRef, {
        'availableSeats': newAvailableSeats,
        'bookedRiders': bookedRiders,
        'riderBookings': riderBookings,
      });

      return true;
    });

    // If cancellation was successful, you could send notification to driver here
    // if (success && ride != null) {
    //   // Send cancellation notification to driver
    // }

    return success;
  }

  /// Delete a ride (only by the driver)
  Future<bool> deleteRide(String rideId, String driverId) async {
    try {
      final rideDoc = await _firestore.collection('rides').doc(rideId).get();
      if (!rideDoc.exists) return false;

      final rideData = rideDoc.data()!;
      if (rideData['driverId'] != driverId) return false;

      await _firestore.collection('rides').doc(rideId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get ride by ID
  Future<Ride?> getRideById(String rideId) async {
    try {
      final rideDoc = await _firestore.collection('rides').doc(rideId).get();
      if (rideDoc.exists) {
        return Ride.fromMap(rideDoc.id, rideDoc.data()!);
      }
    } catch (e) {
      print('Error fetching ride: $e');
    }
    return null;
  }

  /// Get all rides for a specific route (for finding similar rides)
  Future<List<Ride>> getRidesByRoute(String fromLocation, String toLocation) async {
    try {
      final querySnapshot = await _firestore
          .collection('rides')
          .where('fromLocation', isEqualTo: fromLocation)
          .where('toLocation', isEqualTo: toLocation)
          .where('availableSeats', isGreaterThan: 0)
          .orderBy('departureTime')
          .get();

      final now = DateTime.now();
      return querySnapshot.docs
          .map((doc) => Ride.fromMap(doc.id, doc.data()))
          .where((ride) => ride.departureTime.isAfter(now))
          .toList();
    } catch (e) {
      print('Error fetching rides by route: $e');
      return [];
    }
  }
}