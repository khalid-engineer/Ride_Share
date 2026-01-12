import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Process payment for ride booking
  Future<bool> processPayment({
    required String rideId,
    required String riderId,
    required String driverId,
    required int seatsBooked,
    required double amount,
    required String paymentMethod,
  }) async {
    try {
      // Create payment record
      final paymentId = _firestore.collection('payments').doc().id;

      final paymentData = {
        'paymentId': paymentId,
        'rideId': rideId,
        'riderId': riderId,
        'driverId': driverId,
        'seatsBooked': seatsBooked,
        'amount': amount,
        'paymentMethod': paymentMethod,
        'status': 'completed', // In real app, this would be 'pending' initially
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      };

      await _firestore.collection('payments').doc(paymentId).set(paymentData);

      // In a real app, you would integrate with a payment gateway here
      // For now, we'll simulate successful payment

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get payment history for a user
  Stream<List<Map<String, dynamic>>> watchUserPayments(String userId) {
    return _firestore
        .collection('payments')
        .where('riderId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => doc.data()).toList();
        });
  }

  /// Get payments received by driver
  Stream<List<Map<String, dynamic>>> watchDriverPayments(String driverId) {
    return _firestore
        .collection('payments')
        .where('driverId', isEqualTo: driverId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => doc.data()).toList();
        });
  }

  /// Calculate total earnings for driver
  Future<double> getDriverTotalEarnings(String driverId) async {
    try {
      final payments = await _firestore
          .collection('payments')
          .where('driverId', isEqualTo: driverId)
          .where('status', isEqualTo: 'completed')
          .get();

      double total = 0;
      for (var doc in payments.docs) {
        total += (doc.data()['amount'] as num).toDouble();
      }

      return total;
    } catch (e) {
      return 0;
    }
  }

  /// Refund payment (for cancellations)
  Future<bool> processRefund({
    required String paymentId,
    required double refundAmount,
  }) async {
    try {
      await _firestore.collection('payments').doc(paymentId).update({
        'status': 'refunded',
        'refundAmount': refundAmount,
        'refundTimestamp': DateTime.now().toUtc().toIso8601String(),
      });

      return true;
    } catch (e) {
      return false;
    }
  }
}