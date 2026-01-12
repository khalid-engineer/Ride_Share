import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { onCall } from 'firebase-functions/v2/https';
import { initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';
import * as logger from 'firebase-functions/logger';

// Initialize Firebase Admin SDK
initializeApp();

const db = getFirestore();
const messaging = getMessaging();

interface RideBookingData {
  rideId: string;
  riderId: string;
  seatsBooked: number;
  pickupLocation?: string;
}

interface UserProfile {
  name: string;
  email: string;
  role: string;
  fcmToken?: string;
}

interface RideData {
  driverId: string;
  driverName: string;
  fromLocation: string;
  toLocation: string;
  departureTime: FirebaseFirestore.Timestamp;
  pricePerSeat: number;
  vehicleType: string;
}

// Firestore trigger for when a ride booking is created
export const onRideBookingCreated = onDocumentCreated('rides/{rideId}', async (event) => {
  const rideId = event.params.rideId;
  const rideData = event.data?.data() as RideData | undefined;
  
  if (!rideData) {
    logger.error('Ride data not found', { rideId });
    return;
  }

  logger.info('Ride created', { rideId, driverId: rideData.driverId });
  
  // Notify potential riders about new ride (broadcast notification)
  try {
    await sendBroadcastNotification({
      title: 'New Ride Available!',
      body: `${rideData.driverName} posted a ride from ${rideData.fromLocation} to ${rideData.toLocation}`,
      data: {
        type: 'new_ride',
        rideId: rideId,
        driverName: rideData.driverName,
        fromLocation: rideData.fromLocation,
        toLocation: rideData.toLocation,
        departureTime: rideData.departureTime.toDate().toISOString(),
      }
    });
    
    logger.info('Broadcast notification sent for new ride', { rideId });
  } catch (error) {
    logger.error('Error sending broadcast notification', { rideId, error });
  }
});

// Callable function to send ride booking notification
export const sendRideBookingNotification = onCall< RideBookingData>(async (request) => {
  // Verify authentication
  if (!request.auth) {
    throw new Error('User must be authenticated');
  }

  const { rideId, riderId, seatsBooked, pickupLocation } = request.data;
  
  if (!rideId || !riderId || !seatsBooked) {
    throw new Error('Missing required parameters');
  }

  try {
    // Get ride details
    const rideDoc = await db.collection('rides').doc(rideId).get();
    if (!rideDoc.exists) {
      throw new Error('Ride not found');
    }
    
    const rideData = rideDoc.data() as RideData;

    // Get rider details
    const riderDoc = await db.collection('users').doc(riderId).get();
    if (!riderDoc.exists) {
      throw new Error('Rider not found');
    }
    
    const riderData = riderDoc.data() as UserProfile;

    // Get driver details
    const driverDoc = await db.collection('users').doc(rideData.driverId).get();
    if (!driverDoc.exists) {
      throw new Error('Driver not found');
    }
    
    const driverData = driverDoc.data() as UserProfile;

    if (!driverData.fcmToken) {
      logger.warn('Driver FCM token not found', { driverId: rideData.driverId });
      return { success: false, message: 'Driver notification token not found' };
    }

    // Send notification to driver
    const notificationMessage = {
      token: driverData.fcmToken,
      notification: {
        title: 'New Ride Booking!',
        body: `${riderData.name} booked ${seatsBooked} seat(s) for your ride from ${rideData.fromLocation} to ${rideData.toLocation}`,
      },
      data: {
        type: 'ride_booking',
        rideId: rideId,
        driverId: rideData.driverId,
        riderId: riderId,
        riderName: riderData.name,
        driverName: driverData.name,
        seatsBooked: seatsBooked.toString(),
        fromLocation: rideData.fromLocation,
        toLocation: rideData.toLocation,
        pickupLocation: pickupLocation || '',
        departureTime: rideData.departureTime.toDate().toISOString(),
        pricePerSeat: rideData.pricePerSeat.toString(),
        vehicleType: rideData.vehicleType,
      },
      android: {
        notification: {
          channelId: 'ride_notifications',
          priority: 'high',
          visibility: 'public',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
    };

    const response = await messaging.send(notificationMessage);
    
    logger.info('Ride booking notification sent successfully', { 
      rideId, 
      riderId, 
      driverId: rideData.driverId, 
      messageId: response 
    });

    return { 
      success: true, 
      messageId: response,
      message: 'Notification sent successfully' 
    };

  } catch (error) {
    logger.error('Error sending ride booking notification', { 
      rideId, 
      riderId, 
      error 
    });
    
    throw new Error(`Failed to send notification: ${error}`);
  }
});

// Callable function to send ride status updates
export const sendRideStatusNotification = onCall(async (request) => {
  // Verify authentication
  if (!request.auth) {
    throw new Error('User must be authenticated');
  }

  const { rideId, riderId, driverName, status } = request.data;
  
  if (!rideId || !riderId || !driverName || !status) {
    throw new Error('Missing required parameters');
  }

  try {
    // Get rider details
    const riderDoc = await db.collection('users').doc(riderId).get();
    if (!riderDoc.exists) {
      throw new Error('Rider not found');
    }
    
    const riderData = riderDoc.data() as UserProfile;

    if (!riderData.fcmToken) {
      logger.warn('Rider FCM token not found', { riderId });
      return { success: false, message: 'Rider notification token not found' };
    }

    // Get ride details for context
    const rideDoc = await db.collection('rides').doc(rideId).get();
    if (!rideDoc.exists) {
      throw new Error('Ride not found');
    }
    
    const rideData = rideDoc.data() as RideData;

    // Prepare notification based on status
    let title: string;
    let body: string;
    
    switch (status) {
      case 'accepted':
        title = 'Ride Accepted!';
        body = `${driverName} accepted your ride request from ${rideData.fromLocation} to ${rideData.toLocation}`;
        break;
      case 'cancelled':
        title = 'Ride Cancelled';
        body = `${driverName} cancelled the ride from ${rideData.fromLocation} to ${rideData.toLocation}`;
        break;
      case 'started':
        title = 'Ride Started';
        body = `${driverName} has started your ride from ${rideData.fromLocation} to ${rideData.toLocation}`;
        break;
      case 'completed':
        title = 'Ride Completed';
        body = `Your ride with ${driverName} from ${rideData.fromLocation} to ${rideData.toLocation} has been completed`;
        break;
      default:
        title = 'Ride Update';
        body = 'Your ride status has been updated';
    }

    // Send notification to rider
    const notificationMessage = {
      token: riderData.fcmToken,
      notification: {
        title: title,
        body: body,
      },
      data: {
        type: 'ride_status',
        rideId: rideId,
        status: status,
        driverName: driverName,
        fromLocation: rideData.fromLocation,
        toLocation: rideData.toLocation,
        departureTime: rideData.departureTime.toDate().toISOString(),
      },
      android: {
        notification: {
          channelId: 'ride_notifications',
          priority: 'high',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
    };

    const response = await messaging.send(notificationMessage);
    
    logger.info('Ride status notification sent successfully', { 
      rideId, 
      riderId, 
      status, 
      messageId: response 
    });

    return { 
      success: true, 
      messageId: response,
      message: 'Status notification sent successfully' 
    };

  } catch (error) {
    logger.error('Error sending ride status notification', { 
      rideId, 
      riderId, 
      status, 
      error 
    });
    
    throw new Error(`Failed to send status notification: ${error}`);
  }
});

// Helper function to send broadcast notifications
async function sendBroadcastNotification(notification: {
  title: string;
  body: string;
  data: Record<string, string>;
}) {
  try {
    // Get all users with FCM tokens
    const usersSnapshot = await db.collection('users')
      .where('fcmToken', '!=', null)
      .get();

    const tokens: string[] = [];
    usersSnapshot.forEach((doc) => {
      const userData = doc.data() as UserProfile;
      if (userData.fcmToken) {
        tokens.push(userData.fcmToken);
      }
    });

    if (tokens.length === 0) {
      logger.info('No FCM tokens found for broadcast');
      return;
    }

    // Send multicast message
    const message = {
      tokens: tokens,
      notification: {
        title: notification.title,
        body: notification.body,
      },
      data: notification.data,
      android: {
        notification: {
          channelId: 'ride_notifications',
          priority: 'high',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
    };

    const response = await messaging.sendEachForMulticast(message);
    
    logger.info('Broadcast notification sent', { 
      tokensCount: tokens.length, 
      successCount: response.successCount,
      failureCount: response.failureCount 
    });

    // Handle failed tokens
    if (response.failureCount > 0) {
      const failedTokens: string[] = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          failedTokens.push(tokens[idx]);
          logger.error('Failed to send to token', { 
            token: tokens[idx], 
            error: resp.error 
          });
        }
      });

      // Optionally remove invalid tokens
      if (failedTokens.length > 0) {
        await removeInvalidTokens(failedTokens);
      }
    }

  } catch (error) {
    logger.error('Error sending broadcast notification', { error });
    throw error;
  }
}

// Helper function to remove invalid FCM tokens
async function removeInvalidTokens(invalidTokens: string[]) {
  try {
    const batch = db.batch();
    
    for (const token of invalidTokens) {
      const usersSnapshot = await db.collection('users')
        .where('fcmToken', '==', token)
        .get();
      
      usersSnapshot.forEach((doc) => {
        batch.update(doc.ref, {
          fcmToken: null,
          tokenUpdatedAt: new Date(),
        });
      });
    }
    
    await batch.commit();
    logger.info('Invalid tokens removed', { count: invalidTokens.length });
  } catch (error) {
    logger.error('Error removing invalid tokens', { error });
  }
}

// Scheduled function to clean up old FCM tokens (optional)
export const cleanupOldTokens = onCall(async (request) => {
  // Only allow admin users to call this function
  if (!request.auth || request.auth.token.role !== 'admin') {
    throw new Error('Only admins can cleanup tokens');
  }

  try {
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    const usersSnapshot = await db.collection('users')
      .where('tokenUpdatedAt', '<', thirtyDaysAgo)
      .where('fcmToken', '!=', null)
      .get();

    const batch = db.batch();
    let count = 0;

    usersSnapshot.forEach((doc) => {
      batch.update(doc.ref, {
        fcmToken: null,
        tokenUpdatedAt: new Date(),
      });
      count++;
    });

    if (count > 0) {
      await batch.commit();
      logger.info('Cleaned up old tokens', { count });
    }

    return { success: true, cleanedCount: count };
  } catch (error) {
    logger.error('Error cleaning up old tokens', { error });
    throw error;
  }
});