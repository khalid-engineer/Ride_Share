# UniRide Push Notifications Setup Guide

This guide explains how to set up and use the push notification functionality in the UniRide app.

## 📱 Overview

The UniRide app now includes comprehensive push notification support that sends notifications to drivers when riders book seats. The system includes:

- **Firebase Cloud Messaging (FCM)** for push notifications
- **Local notifications** for immediate feedback
- **Cloud Functions** for secure notification delivery
- **Token management** for FCM device tokens
- **Permission handling** for notification access

## 🔧 Setup Instructions

### 1. Firebase Configuration

1. **Enable Firebase Cloud Messaging** in your Firebase project
2. **Download** `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
3. **Place** these files in the appropriate directories:
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`

### 2. Android Setup

#### Add Notification Channel
Add this to `android/app/src/main/AndroidManifest.xml`:

```xml
<!-- Add inside the <application> tag -->
<receiver android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
<receiver android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED"/>
    </intent-filter>
</receiver>
```

#### Add Permissions
```xml
<!-- Add outside the <application> tag -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
```

### 3. iOS Setup

#### Add Capabilities
1. Open `ios/Runner.xcworkspace`
2. Go to **Signing & Capabilities**
3. Add **Push Notifications** capability

#### Configure Info.plist
Add to `ios/Runner/Info.plist`:

```xml
<key>NSUserNotificationAlertStyle</key>
<string>alert</string>
```

### 4. Cloud Functions Deployment

#### Install Dependencies
```bash
cd functions
npm install
```

#### Deploy Functions
```bash
# Login to Firebase
firebase login

# Initialize Firebase (if not already done)
firebase init functions

# Deploy functions
firebase deploy --only functions
```

## 🚀 Usage

### Automatic Notification Setup

The notification system is automatically integrated into the ride booking flow:

1. **User registers/logs in** → FCM token automatically stored
2. **Rider books a seat** → Driver receives push notification
3. **Ride status changes** → Relevant party receives notifications

### Manual Integration

#### Register User for Notifications
```dart
import 'package:uniride_new/src/services/notification_manager.dart';

// Call this when user logs in or registers
await NotificationManager().registerUserForNotifications();
```

#### Unregister User (Logout)
```dart
import 'package:uniride_new/src/services/notification_manager.dart';

// Call this when user logs out
await NotificationManager().unregisterUserFromNotifications();
```

#### Send Custom Notifications
```dart
import 'package:uniride_new/src/services/notification_manager.dart';

final notificationManager = NotificationManager();

// Send ride booking notification
await notificationManager.sendRideBookingNotification(
  rideId: 'ride_123',
  riderId: 'rider_456',
  seatsBooked: 2,
  pickupLocation: 'Main Street',
);

// Send ride status notification
await notificationManager.sendRideStatusNotification(
  rideId: 'ride_123',
  riderId: 'rider_456',
  driverName: 'John Doe',
  status: 'accepted', // 'accepted', 'cancelled', 'started', 'completed'
);
```

## 📋 Notification Types

### 1. Ride Booking Notifications
- **Trigger**: When a rider books seats on a driver's ride
- **Recipient**: Driver
- **Content**: Rider name, seats booked, pickup location, ride details
- **Data**: rideId, riderId, driverId, seatsBooked, pickupLocation

### 2. Ride Status Notifications
- **Trigger**: When driver updates ride status
- **Recipient**: Rider(s)
- **Content**: Status-specific messages (accepted, cancelled, started, completed)
- **Data**: rideId, status, driverName, fromLocation, toLocation

### 3. New Ride Broadcast
- **Trigger**: When a driver creates a new ride
- **Recipient**: All users (broadcast)
- **Content**: New ride availability notification
- **Data**: rideId, driverName, fromLocation, toLocation, departureTime

## 🔍 Cloud Functions

### Available Functions

1. **`sendRideBookingNotification`**
   - Sends notification when rider books a seat
   - Callable function with authentication

2. **`sendRideStatusNotification`**
   - Sends status updates to riders
   - Supports: accepted, cancelled, started, completed

3. **`onRideBookingCreated`**
   - Firestore trigger for new ride creation
   - Sends broadcast notifications

4. **`cleanupOldTokens`**
   - Scheduled function to clean invalid FCM tokens
   - Admin only access

### Function Invocation
```javascript
// From Flutter app
final result = await FirebaseFunctions.instance
  .httpsCallable('sendRideBookingNotification')
  .call({
    'rideId': 'ride_123',
    'riderId': 'rider_456',
    'seatsBooked': 2,
    'pickupLocation': 'Main Street'
  });
```

## 🛠️ Configuration

### Notification Service Configuration

Edit `lib/src/services/notification_service.dart`:

```dart
// Customize notification channels
static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
  'ride_notifications',
  'Ride Notifications',
  description: 'Notifications for ride bookings and updates',
  importance: Importance.high,
);
```

### User Profile Schema Update

The `UserProfile` model now includes:
- `fcmToken`: String? - FCM device token
- `tokenUpdatedAt`: DateTime? - Last token update time

## 🧪 Testing

### Test Notifications

1. **Enable debug logging** in notification service
2. **Use Firebase Console** to send test messages
3. **Test with multiple devices** to verify cross-device delivery

### Debug Commands

```bash
# Check Firebase functions logs
firebase functions:log

# Test Cloud Function locally
firebase emulators:start --only functions

# Check FCM token status
# Use the NotificationManager.areNotificationsEnabled() method
```

## 🔒 Security

- **Authentication Required**: All Cloud Functions require valid Firebase Auth
- **Token Validation**: Invalid FCM tokens are automatically cleaned up
- **User Isolation**: Users can only send notifications for their own rides
- **Permission Checks**: Ride ownership verification before sending notifications

## 🐛 Troubleshooting

### Common Issues

1. **Notifications not received**
   - Check FCM token registration
   - Verify notification permissions
   - Check Firebase Console for error logs

2. **iOS notifications not working**
   - Ensure Push Notifications capability is added
   - Check Info.plist configuration
   - Test with physical device (simulator limitations)

3. **Android notifications not showing**
   - Check notification channel configuration
   - Verify AndroidManifest.xml permissions
   - Test with release build (some limitations in debug)

### Debug Steps

1. **Enable verbose logging**:
```dart
// In notification_service.dart, change print statements to debugPrint
```

2. **Check Firebase Console**:
   - Cloud Functions logs
   - FCM delivery reports
   - Authentication logs

3. **Test token registration**:
```dart
final enabled = await NotificationManager().areNotificationsEnabled();
print('Notifications enabled: $enabled');
```

## 📚 Additional Resources

- [Firebase Cloud Messaging Documentation](https://firebase.google.com/docs/cloud-messaging)
- [Flutter Local Notifications Plugin](https://pub.dev/packages/flutter_local_notifications)
- [Firebase Functions Documentation](https://firebase.google.com/docs/functions)
- [FCM Best Practices](https://firebase.google.com/docs/cloud-messaging/concept-options)

## 🎯 Next Steps

1. **Deploy Cloud Functions** to production
2. **Set up notification preferences** in user settings
3. **Add rich notification actions** (Accept/Reject booking)
4. **Implement notification history** in the app
5. **Add analytics** for notification delivery rates

---

## Support

For issues or questions about the notification system:
1. Check the troubleshooting section above
2. Review Firebase Console logs
3. Test with the provided debug methods
4. Consult the Firebase documentation