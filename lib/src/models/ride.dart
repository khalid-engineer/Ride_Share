import 'package:cloud_firestore/cloud_firestore.dart';

class Ride {
  final String id;
  final String driverId;
  final String driverName;
  final String fromLocation;
  final String toLocation;
  final DateTime departureTime;
  final int totalSeats;
  final int availableSeats;
  final double pricePerSeat;
  final String vehicleType;
  final String? vehicleModel;
  final String? vehicleColor;
  final String? licensePlate;
  final DateTime createdAt;
  final List<String> bookedRiders; // List of rider IDs who booked
  final Map<String, int> riderBookings; // riderId -> seatsBooked
  final Map<String, String> riderPickupLocations; // riderId -> pickupLocation

  Ride({
    required this.id,
    required this.driverId,
    required this.driverName,
    required this.fromLocation,
    required this.toLocation,
    required this.departureTime,
    required this.totalSeats,
    required this.availableSeats,
    required this.pricePerSeat,
    required this.vehicleType,
    this.vehicleModel,
    this.vehicleColor,
    this.licensePlate,
    required this.createdAt,
    this.bookedRiders = const [],
    this.riderBookings = const {},
    this.riderPickupLocations = const {},
  });

  factory Ride.fromMap(String id, Map<String, dynamic> data) {
    return Ride(
      id: id,
      driverId: data['driverId'] ?? '',
      driverName: data['driverName'] ?? '',
      fromLocation: data['fromLocation'] is String ? data['fromLocation'] : 'Unknown Location',
      toLocation: data['toLocation'] is String ? data['toLocation'] : 'Unknown Location',
      departureTime: (data['departureTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalSeats: data['totalSeats'] ?? 0,
      availableSeats: data['availableSeats'] ?? 0,
      pricePerSeat: (data['pricePerSeat'] ?? 0).toDouble(),
      vehicleType: data['vehicleType'] ?? '',
      vehicleModel: data['vehicleModel'],
      vehicleColor: data['vehicleColor'],
      licensePlate: data['licensePlate'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      bookedRiders: List<String>.from(data['bookedRiders'] ?? []),
      riderBookings: Map<String, int>.from(data['riderBookings'] ?? {}),
      riderPickupLocations: Map<String, String>.from(data['riderPickupLocations'] ?? {}),
    );
  }

  int get bookedSeats => totalSeats - availableSeats;

  Map<String, dynamic> toMap() {
    return {
      'driverId': driverId,
      'driverName': driverName,
      'fromLocation': fromLocation,
      'toLocation': toLocation,
      'departureTime': Timestamp.fromDate(departureTime),
      'totalSeats': totalSeats,
      'availableSeats': availableSeats,
      'pricePerSeat': pricePerSeat,
      'vehicleType': vehicleType,
      'vehicleModel': vehicleModel,
      'vehicleColor': vehicleColor,
      'licensePlate': licensePlate,
      'createdAt': Timestamp.fromDate(createdAt),
      'bookedRiders': bookedRiders,
      'riderBookings': riderBookings,
      'riderPickupLocations': riderPickupLocations,
    };
  }

  Ride copyWith({
    String? id,
    String? driverId,
    String? driverName,
    String? fromLocation,
    String? toLocation,
    DateTime? departureTime,
    int? totalSeats,
    int? availableSeats,
    double? pricePerSeat,
    String? vehicleType,
    String? vehicleModel,
    String? vehicleColor,
    String? licensePlate,
    DateTime? createdAt,
    List<String>? bookedRiders,
    Map<String, int>? riderBookings,
    Map<String, String>? riderPickupLocations,
  }) {
    return Ride(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      fromLocation: fromLocation ?? this.fromLocation,
      toLocation: toLocation ?? this.toLocation,
      departureTime: departureTime ?? this.departureTime,
      totalSeats: totalSeats ?? this.totalSeats,
      availableSeats: availableSeats ?? this.availableSeats,
      pricePerSeat: pricePerSeat ?? this.pricePerSeat,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehicleColor: vehicleColor ?? this.vehicleColor,
      licensePlate: licensePlate ?? this.licensePlate,
      createdAt: createdAt ?? this.createdAt,
      bookedRiders: bookedRiders ?? this.bookedRiders,
      riderBookings: riderBookings ?? this.riderBookings,
      riderPickupLocations: riderPickupLocations ?? this.riderPickupLocations,
    );
  }
}