import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../src/services/ride_service.dart';

class PaymentScreen extends StatefulWidget {
  final String rideId;
  final int seatsBooked;
  final double amount;
  final String pickupLocation;

  const PaymentScreen({
    super.key,
    required this.rideId,
    required this.seatsBooked,
    required this.amount,
    required this.pickupLocation,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _rideService = RideService();
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Booking'),
      ),
      body: Container(
        color: Theme.of(context).colorScheme.surface,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Confirm Your Booking',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Review your booking details and confirm',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 30),

                // Booking summary
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Booking Summary',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSummaryRow('Seats booked', '${widget.seatsBooked}'),
                      const Divider(),
                      _buildSummaryRow('Price per seat', 'Rs. ${(widget.amount / widget.seatsBooked).toStringAsFixed(0)}'),
                      const Divider(),
                      _buildSummaryRow('Pickup location', widget.pickupLocation.isNotEmpty ? widget.pickupLocation : 'Not specified'),
                      const Divider(),
                      _buildSummaryRow('Ride fare', 'Rs. ${widget.amount.toStringAsFixed(0)}'),
                      const Divider(),
                      _buildSummaryRow('App development fee (5%)', 'Rs. ${(widget.amount * 0.05).toStringAsFixed(0)}'),
                      const Divider(),
                      _buildSummaryRow(
                        'Total amount',
                        'Rs. ${(widget.amount * 1.05).toStringAsFixed(0)}',
                        isTotal: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Confirm button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _confirmBooking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isProcessing
                        ? const CircularProgressIndicator()
                        : const Text(
                            'Confirm Booking & Proceed to Payment',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // Note
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Next, select your payment method. 5% of your fare supports app development. Booking confirmation will be sent after payment.',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Future<void> _confirmBooking() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isProcessing = true);

    try {
      // Check if user already has a booking for this ride
      final ride = await _rideService.watchRideDetails(widget.rideId).first;
      final hasExistingBooking = ride != null && ride.bookedRiders.contains(user.uid);

      bool success = true;

      // Only book seats if user doesn't already have a booking
      if (!hasExistingBooking) {
        success = await _rideService.bookSeats(
          rideId: widget.rideId,
          riderId: user.uid,
          seatsToBook: widget.seatsBooked,
          pickupLocation: widget.pickupLocation,
        );
      }

      if (success && mounted) {
        // Navigate to payment method selection
        Navigator.pushNamed(
          context,
          '/payment-method',
          arguments: {
            'rideId': widget.rideId,
            'seatsBooked': widget.seatsBooked,
            'amount': widget.amount,
            'pickupLocation': widget.pickupLocation,
          },
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking failed. Seats may no longer be available.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}