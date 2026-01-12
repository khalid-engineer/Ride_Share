// // Test for seat booking functionality
// // This test verifies the scenario: Driver posts 5 seats, rider books 2, system shows 3 remaining

// import 'package:flutter_test/flutter_test.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
// import 'package:uniride_new/src/services/ride_service.dart';

// void main() {
//   group('Seat Booking Tests', () {
//     late RideService rideService;
//     late FakeFirebaseFirestore fakeFirestore;

//     setUp(() {
//       fakeFirestore = FakeFirebaseFirestore();
//       rideService = RideService();
//     });

//     test('Driver posts 5 seats, rider books 2 seats, 3 seats remain', () async {
//       // Step 1: Driver posts a ride with 5 available seats
//       final driverId = 'driver123';
//       final rideId = await rideService.createDriverRide(
//         driverId: driverId,
//         fromLocation: {"lat": 40.7128, "lng": -74.0060},
//         toLocation: {"lat": 34.0522, "lng": -118.2437},
//         fromAddress: 'New York, NY',
//         toAddress: 'Los Angeles, CA',
//         availableSeats: 5,
//         pricePerSeat: 100,
//         vehicleType: 'Sedan',
//       );

//       // Step 2: Verify initial state (5 seats available)
//       final initialRideDoc = await fakeFirestore.collection('rides').doc(rideId).get();
//       final initialData = initialRideDoc.data() as Map<String, dynamic>;
//       expect(initialData['totalSeats'], 5);
//       expect(initialData['availableSeats'], 5);

//       // Step 3: First rider books 2 seats
//       final firstRiderId = 'rider456';
//       final success1 = await rideService.bookSeats(
//         rideId: rideId,
//         riderId: firstRiderId,
//         seatsToBook: 2,
//       );

//       // Step 4: Verify booking was successful
//       expect(success1, true);

//       // Step 5: Verify 3 seats remain available
//       final rideDoc1 = await fakeFirestore.collection('rides').doc(rideId).get();
//       final rideData1 = rideDoc1.data() as Map<String, dynamic>;
//       expect(rideData1['availableSeats'], 3);
//       expect(rideData1['totalSeats'], 5);

//       // Step 6: Second rider books 1 seat
//       final secondRiderId = 'rider789';
//       final success2 = await rideService.bookSeats(
//         rideId: rideId,
//         riderId: secondRiderId,
//         seatsToBook: 1,
//       );

//       // Step 7: Verify second booking was successful
//       expect(success2, true);

//       // Step 8: Verify 2 seats remain available
//       final rideDoc2 = await fakeFirestore.collection('rides').doc(rideId).get();
//       final rideData2 = rideDoc2.data() as Map<String, dynamic>;
//       expect(rideData2['availableSeats'], 2);
//       expect(rideData2['totalSeats'], 5);

//       print('✅ Test passed: Driver posts 5 seats → Rider 1 books 2 → 3 remaining');
//       print('✅ Test passed: Driver posts 5 seats → Rider 1 books 2 → Rider 2 books 1 → 2 remaining');
//     });

//     test('Booking fails when not enough seats available', () async {
//       // Step 1: Driver posts a ride with only 2 available seats
//       final driverId = 'driver123';
//       final rideId = await rideService.createDriverRide(
//         driverId: driverId,
//         fromLocation: {"lat": 40.7128, "lng": -74.0060},
//         toLocation: {"lat": 34.0522, "lng": -118.2437},
//         fromAddress: 'New York, NY',
//         toAddress: 'Los Angeles, CA',
//         availableSeats: 2,
//         pricePerSeat: 100,
//         vehicleType: 'Sedan',
//       );

//       // Step 2: Try to book 3 seats (should fail)
//       final riderId = 'rider456';
//       final success = await rideService.bookSeats(
//         rideId: rideId,
//         riderId: riderId,
//         seatsToBook: 3,
//       );

//       // Step 3: Verify booking failed
//       expect(success, false);

//       // Step 4: Verify seats remain unchanged
//       final rideDoc = await fakeFirestore.collection('rides').doc(rideId).get();
//       final rideData = rideDoc.data() as Map<String, dynamic>;
//       expect(rideData['availableSeats'], 2);
//       expect(rideData['totalSeats'], 2);

//       print('✅ Test passed: Booking 3 seats when only 2 available correctly failed');
//     });

//     test('Real-time updates work correctly', () async {
//       // This test would require setting up streams and listening for changes
//       // In a real scenario, you would test with actual Firebase listeners
      
//       final driverId = 'driver123';
//       final rideId = await rideService.createDriverRide(
//         driverId: driverId,
//         fromLocation: {"lat": 40.7128, "lng": -74.0060},
//         toLocation: {"lat": 34.0522, "lng": -118.2437},
//         fromAddress: 'New York, NY',
//         toAddress: 'Los Angeles, CA',
//         availableSeats: 5,
//         pricePerSeat: 100,
//         vehicleType: 'Sedan',
//       );

//       // Verify stream method exists and can be called
//       final stream = rideService.watchRideDetails(rideId);
//       expect(stream, isNotNull);

//       print('✅ Test passed: Real-time stream methods are available');
//     });
//   });
// }