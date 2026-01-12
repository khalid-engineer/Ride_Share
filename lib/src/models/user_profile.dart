import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String role; // "driver" or "rider"
  final Map<String, dynamic>? vehicleInfo; // only for drivers
  final String? fcmToken; // FCM token for push notifications
  final DateTime? tokenUpdatedAt; // When FCM token was last updated

  const UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.vehicleInfo,
    this.fcmToken,
    this.tokenUpdatedAt,
  });

  factory UserProfile.fromMap(String uid, Map<String, dynamic> data) {
    return UserProfile(
      uid: uid,
      name: (data['name'] as String?)?.trim() ?? '',
      email: (data['email'] as String?)?.trim() ?? '',
      phone: (data['phone'] as String?)?.trim() ?? '',
      role: (data['role'] as String?)?.trim() ?? 'rider',
      vehicleInfo: data['vehicleInfo'] as Map<String, dynamic>?,
      fcmToken: data['fcmToken'] as String?,
      tokenUpdatedAt: (data['tokenUpdatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      if (vehicleInfo != null) 'vehicleInfo': vehicleInfo,
      if (fcmToken != null) 'fcmToken': fcmToken,
      if (tokenUpdatedAt != null) 'tokenUpdatedAt': Timestamp.fromDate(tokenUpdatedAt!),
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? uid,
    String? name,
    String? email,
    String? phone,
    String? role,
    Map<String, dynamic>? vehicleInfo,
    String? fcmToken,
    DateTime? tokenUpdatedAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      vehicleInfo: vehicleInfo ?? this.vehicleInfo,
      fcmToken: fcmToken ?? this.fcmToken,
      tokenUpdatedAt: tokenUpdatedAt ?? this.tokenUpdatedAt,
    );
  }

  /// Check if user is a driver
  bool get isDriver => role == 'driver';
  
  /// Check if user is a rider
  bool get isRider => role == 'rider';
  
  /// Get display name
  String get displayName => name.isNotEmpty ? name : email;
}
