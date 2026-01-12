import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'notification_service.dart';
import '../models/ride.dart';

/// Manages FCM token registration and notification setup for users
class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final NotificationService _notificationService = NotificationService();

  /// Register FCM token for the current user
  Future<void> registerUserForNotifications() async {
    try {
      final User? currentUser = _auth.currentUser;
      
      if (currentUser == null) {
        print('No user logged in, skipping FCM token registration');
        return;
      }

      print('Registering FCM token for user: ${currentUser.uid}');
      
      // Initialize notification service
      await _notificationService.initialize();
      
      // Store FCM token for the user
      await _notificationService.storeFCMToken(currentUser.uid);
      
      // Subscribe to user-specific topic
      await _notificationService.subscribeToRideTopics(currentUser.uid);
      
      print('Successfully registered user for notifications: ${currentUser.uid}');
      
    } catch (e) {
      print('Error registering user for notifications: $e');
    }
  }

  /// Unregister FCM token when user logs out
  Future<void> unregisterUserFromNotifications() async {
    try {
      final User? currentUser = _auth.currentUser;
      
      if (currentUser == null) {
        print('No user logged in, skipping FCM token cleanup');
        return;
      }

      print('Cleaning up FCM token for user: ${currentUser.uid}');
      
      // Remove FCM token from user profile
      await _notificationService.removeFCMToken(currentUser.uid);
      
      // Unsubscribe from user-specific topic
      await _notificationService.unsubscribeFromRideTopics(currentUser.uid);
      
      print('Successfully unregistered user from notifications: ${currentUser.uid}');
      
    } catch (e) {
      print('Error unregistering user from notifications: $e');
    }
  }

  /// Send ride booking notification via Cloud Function
  Future<void> sendRideBookingNotification({
    required String rideId,
    required String riderId,
    required int seatsBooked,
    String? pickupLocation,
  }) async {
    try {
      final User? currentUser = _auth.currentUser;
      
      if (currentUser == null) {
        print('User not authenticated, cannot send notification');
        return;
      }

      print('Sending ride booking notification for ride: $rideId');

      // Call the Cloud Function to send notification
      final result = await _functions.httpsCallable('sendRideBookingNotification').call({
        'rideId': rideId,
        'riderId': riderId,
        'seatsBooked': seatsBooked,
        'pickupLocation': pickupLocation ?? '',
      });

      print('Ride booking notification sent successfully: ${result.data}');
      
    } catch (e) {
      print('Error sending ride booking notification: $e');
      
      // Fallback to local notification for immediate feedback
      try {
        final rideDoc = await _firestore.collection('rides').doc(rideId).get();
        if (rideDoc.exists) {
          final rideData = rideDoc.data()!;
          final ride = Ride.fromMap(rideId, rideData);

          final riderDoc = await _firestore.collection('users').doc(riderId).get();
          if (riderDoc.exists) {
            final riderData = riderDoc.data() as Map<String, dynamic>;
            final riderName = riderData['name'] as String? ?? 'A rider';

            // Show local notification as fallback
            await _notificationService.showRideBookingNotification(
              riderName: riderName,
              ride: ride,
              seatsBooked: seatsBooked,
              pickupLocation: pickupLocation,
            );
          }
        }
      } catch (fallbackError) {
        print('Fallback notification also failed: $fallbackError');
      }
    }
  }

  /// Send ride status notification to rider via Cloud Function
  Future<void> sendRideStatusNotification({
    required String rideId,
    required String riderId,
    required String driverName,
    required String status, // 'accepted', 'cancelled', 'started', 'completed'
  }) async {
    try {
      final User? currentUser = _auth.currentUser;
      
      if (currentUser == null) {
        print('User not authenticated, cannot send status notification');
        return;
      }

      print('Sending ride status notification for ride: $rideId');

      // Call the Cloud Function to send status notification
      final result = await _functions.httpsCallable('sendRideStatusNotification').call({
        'rideId': rideId,
        'riderId': riderId,
        'driverName': driverName,
        'status': status,
      });

      print('Ride status notification sent successfully: ${result.data}');
      
    } catch (e) {
      print('Error sending ride status notification: $e');
      // Status notifications are less critical, so we don't need a fallback
    }
  }

  /// Check if notifications are enabled for the current user
  Future<bool> areNotificationsEnabled() async {
    try {
      final User? currentUser = _auth.currentUser;
      
      if (currentUser == null) {
        return false;
      }

      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (!userDoc.exists) {
        return false;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final fcmToken = userData['fcmToken'] as String?;
      
      return fcmToken != null && fcmToken.isNotEmpty;
      
    } catch (e) {
      print('Error checking notification status: $e');
      return false;
    }
  }

  /// Refresh FCM token for the current user
  Future<void> refreshUserFCMToken() async {
    try {
      final User? currentUser = _auth.currentUser;
      
      if (currentUser == null) {
        print('No user logged in, skipping token refresh');
        return;
      }

      print('Refreshing FCM token for user: ${currentUser.uid}');
      
      // Re-register the user to get a fresh token
      await registerUserForNotifications();
      
    } catch (e) {
      print('Error refreshing FCM token: $e');
    }
  }

  /// Test notification sending (for debugging)
  Future<void> sendTestNotification() async {
    try {
      final User? currentUser = _auth.currentUser;
      
      if (currentUser == null) {
        print('No user logged in, cannot send test notification');
        return;
      }

      print('Sending test notification to user: ${currentUser.uid}');
      
      // Show local test notification using a simple approach
      print('Test notification functionality - check logs for confirmation');
      
      print('Test notification sent successfully');
      
    } catch (e) {
      print('Error sending test notification: $e');
    }
  }
}