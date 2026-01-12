import 'package:flutter/material.dart';

class PaymentMethodScreen extends StatefulWidget {
  final String rideId;
  final int seatsBooked;
  final double amount;
  final String pickupLocation;

  const PaymentMethodScreen({
    super.key,
    required this.rideId,
    required this.seatsBooked,
    required this.amount,
    required this.pickupLocation,
  });

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  String _selectedPaymentMethod = 'cash';

  Color get pastelMint => Theme.of(context).colorScheme.primary.withOpacity(0.2);
  Color get pastelPeach => Theme.of(context).colorScheme.secondary.withOpacity(0.2);
  Color get pastelBlue => Theme.of(context).colorScheme.tertiary.withOpacity(0.2);
  Color get pastelPrimary => Theme.of(context).colorScheme.primary;

  @override
  Widget build(BuildContext context) {
    // Calculate fees
    final rideAmount = widget.amount;
    final appFee = rideAmount * 0.05; // 5% app development fee
    final totalAmount = rideAmount + appFee;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Payment Method'),
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
                  'Choose Payment Method',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select how you would like to pay for your booking',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 30),

                // Payment Methods
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Methods',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 20),

                      // Cash Payment Option
                      _buildPaymentOption(
                        'cash',
                        'Cash',
                        'Pay the driver directly upon pickup',
                        Icons.money,
                        Colors.green,
                      ),
                      const SizedBox(height: 16),

                      // Card Payment Option
                      _buildPaymentOption(
                        'card',
                        'Credit/Debit Card',
                        'Pay securely with your card',
                        Icons.credit_card,
                        Colors.blue,
                      ),
                      const SizedBox(height: 16),

                      // Digital Wallet Option
                      _buildPaymentOption(
                        'wallet',
                        'Digital Wallet',
                        'Pay using digital wallet',
                        Icons.account_balance_wallet,
                        Colors.purple,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Amount Breakdown
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Amount Breakdown',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      _buildAmountRow('Seats booked', '${widget.seatsBooked}'),
                      const Divider(),
                      _buildAmountRow('Ride fare', 'Rs. ${rideAmount.toStringAsFixed(0)}'),
                      const Divider(),
                      _buildAmountRow('App development fee (5%)', 'Rs. ${appFee.toStringAsFixed(0)}'),
                      const Divider(),
                      _buildAmountRow(
                        'Total amount',
                        'Rs. ${totalAmount.toStringAsFixed(0)}',
                        isTotal: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Proceed to Payment Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _proceedToPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Proceed to Payment',
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
                          '5% of your ride fare goes towards app development and maintenance.',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
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

  Widget _buildPaymentOption(String value, String title, String subtitle, IconData icon, Color color) {
    final isSelected = _selectedPaymentMethod == value;

    return InkWell(
      onTap: () => setState(() => _selectedPaymentMethod = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  void _proceedToPayment() {
    // Navigate to payment form screen
    Navigator.pushNamed(
      context,
      '/payment-form',
      arguments: {
        'rideId': widget.rideId,
        'seatsBooked': widget.seatsBooked,
        'rideAmount': widget.amount,
        'appFee': widget.amount * 0.05,
        'totalAmount': widget.amount * 1.05,
        'pickupLocation': widget.pickupLocation,
        'paymentMethod': _selectedPaymentMethod,
      },
    );
  }
}