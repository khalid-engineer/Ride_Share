import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/ride.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Notification channel for Android
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'ride_notifications',
    'Ride Notifications',
    description: 'Notifications for ride bookings and updates',
    importance: Importance.high,
  );

  /// Initialize notification service
  Future<void> initialize() async {
    // Request permissions
    await _requestPermissions();

    // Configure local notifications
    await _configureLocalNotifications();

    // Configure FCM
    await _configureFCM();

    print('Notification service initialized successfully');
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
    } else if (Platform.isAndroid) {
      await Permission.notification.request();
    }
  }

  /// Configure local notifications
  Future<void> _configureLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create notification channel for Android
    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
    }
  }

  /// Configure Firebase Cloud Messaging
  Future<void> _configureFCM() async {
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleForegroundMessage(message);
    });

    // Handle message opened from terminated state
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleMessageOpenedApp(message);
    });

    // Get initial message (when app is in terminated state)
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    if (message.notification != null) {
      _showLocalNotification(
        title: message.notification!.title ?? 'UniRide',
        body: message.notification!.body ?? '',
        payload: message.data.toString(),
      );
    }
  }

  /// Handle message opened from background/terminated state
  void _handleMessageOpenedApp(RemoteMessage message) {
    // Handle navigation to specific screens based on message data
    final data = message.data;
    if (data['type'] == 'ride_booking') {
      // Navigate to ride details or driver's rides screen
      print('Navigating to ride details for ride ID: ${data['rideId']}');
    }
  }

  /// Handle notification tap
  void _onNotificationTap(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // Handle navigation based on payload
  }

  /// Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    required String payload,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'ride_notifications',
      'Ride Notifications',
      channelDescription: 'Notifications for ride bookings and updates',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Store FCM token for user
  Future<void> storeFCMToken(String userId) async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': token,
          'tokenUpdatedAt': FieldValue.serverTimestamp(),
        });
        print('FCM token stored for user: $userId');
      }
    } catch (e) {
      print('Error storing FCM token: $e');
    }
  }

  /// Remove FCM token when user logs out
  Future<void> removeFCMToken(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': FieldValue.delete(),
        'tokenUpdatedAt': FieldValue.serverTimestamp(),
      });
      print('FCM token removed for user: $userId');
    } catch (e) {
      print('Error removing FCM token: $e');
    }
  }

  /// Subscribe to ride-related topics
  Future<void> subscribeToRideTopics(String userId) async {
    try {
      await _firebaseMessaging.subscribeToTopic('all_users');
      await _firebaseMessaging.subscribeToTopic('user_$userId');
      print('Subscribed to ride topics for user: $userId');
    } catch (e) {
      print('Error subscribing to topics: $e');
    }
  }

  /// Unsubscribe from ride-related topics
  Future<void> unsubscribeFromRideTopics(String userId) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic('all_users');
      await _firebaseMessaging.unsubscribeFromTopic('user_$userId');
      print('Unsubscribed from ride topics for user: $userId');
    } catch (e) {
      print('Error unsubscribing from topics: $e');
    }
  }

  /// Show immediate local notification for ride booking
  Future<void> showRideBookingNotification({
    required String riderName,
    required Ride ride,
    required int seatsBooked,
    String? pickupLocation,
  }) async {
    _showLocalNotification(
      title: 'New Ride Booking!',
      body: '$riderName booked $seatsBooked seat(s) for your ride from ${ride.fromLocation} to ${ride.toLocation}',
      payload: 'ride_booking:${ride.id}',
    );
  }

  /// Get current FCM token
  Future<String?> getCurrentToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    try {
      final settings = await _firebaseMessaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
             settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      print('Error checking notification status: $e');
      return false;
    }
  }

  /// Request notification permissions explicitly
  Future<NotificationSettings> requestPermissions() async {
    return await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: true,
      sound: true,
    );
  }

  /// Get notification settings
  Future<NotificationSettings> getNotificationSettings() async {
    return await _firebaseMessaging.getNotificationSettings();
  }

  /// Refresh FCM token
  Future<void> refreshToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      final newToken = await _firebaseMessaging.getToken();
      print('FCM token refreshed: $newToken');
    } catch (e) {
      print('Error refreshing FCM token: $e');
    }
  }
}

/// Background message handler for FCM
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
  
  // You can add additional background handling here if needed
  // Note: Firebase is already initialized in the main app
}