import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mobile/api/api.dart' as api;
import 'package:mobile/reservations/repository/reservations_repository.dart';
import 'package:mobile/reservations/view/reservation_confirmation_page.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({
    required this.venue,
    required this.level,
    required this.spot,
    this.startDate,
    this.endDate,
    super.key,
  });

  final api.Venue venue;
  final api.Level level;
  final api.Spot spot;
  final DateTime? startDate;
  final DateTime? endDate;

  static Route<void> route({
    required api.Venue venue,
    required api.Level level,
    required api.Spot spot,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return MaterialPageRoute<void>(
      builder: (_) => CheckoutPage(
        venue: venue,
        level: level,
        spot: spot,
        startDate: startDate,
        endDate: endDate,
      ),
    );
  }

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String _selectedPaymentMethod = 'wallet'; // Default to in-app wallet
  bool _isProcessing = false;

  Future<void> _processPaymentAndReserve() async {
    setState(() {
      _isProcessing = true;
    });

    // Simulate payment delay
    await Future<void>.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    try {
      final reservation = await context
          .read<ReservationsRepository>()
          .createReservation(
            venueId: widget.venue.id,
            levelId: widget.level.id,
            spotId: widget.spot.id,
            startAt: widget.startDate,
            endAt: widget.endDate,
          );

      if (mounted) {
        await Navigator.pushReplacement(
          context,
          ReservationConfirmationPage.route(reservation: reservation),
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to process reservation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat(
      'MMM d, yyyy • h:mm a',
    ).format(widget.startDate ?? DateTime.now());

    var durationStr = '1 hour';
    var totalPrice = 50; // Default reservation fee

    if (widget.startDate != null && widget.endDate != null) {
      final duration = widget.endDate!.difference(widget.startDate!);
      final hours = duration.inMinutes / 60.0;

      // Format duration string
      final d = duration.inDays;
      final h = duration.inHours % 24;
      final m = duration.inMinutes % 60;

      final parts = <String>[];
      if (d > 0) parts.add('$d days');
      if (h > 0) parts.add('$h hrs');
      if (m > 0) parts.add('$m mins');
      durationStr = parts.isEmpty ? '0 mins' : parts.join(' ');

      // Calculate price - For reservations, only the reservation fee is charged upfront.
      // The actual parking fees (baseRate, succeedingHourRate) will be calculated
      // by sensors when the user parks and checked out.
      if (widget.venue.configuration != null) {
        final config = widget.venue.configuration!;
        totalPrice = config.reservationFee;
      } else {
        // Fallback if no config - default reservation fee
        totalPrice = 50.0;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F7F8).withValues(alpha: 0.95),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Checkout',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Summary Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: const DecorationImage(
                              image: NetworkImage(
                                'https://lh3.googleusercontent.com/aida-public/AB6AXuDn8jr7dXwW1RBs0TlfATvS0Cn7mic98XzDNNYoFdH31wvQS7F1F2uAQqKiUrpFZwRLTWfcEWZD-nnTi4OZEnc66lllpU1W1Jl3KthcAYq77L_ay5BqA9EFc0X1-PqcVk3Gw9BtVBcp6Cccx--XXE4esqZ9YmlhWppxafClviWEsFMQBhzE-Yc5vQPghEuUiVFZ-xD5UuaAf-SYESDSlcmnuDSieK5SiYSkQlKO0lq6VBd17BSKafNq-U_PO2rTlB5yxgSmishsf4EO',
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.venue.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${widget.level.name}, Slot ${widget.spot.spotNumber.split('-').last}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF137FEC,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.local_parking,
                                      size: 14,
                                      color: Color(0xFF137FEC),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Reserved Spot',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF137FEC),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildSummaryRow('Date', dateStr),
                        const SizedBox(height: 12),
                        _buildSummaryRow('Duration', durationStr),
                        const SizedBox(height: 12),
                        _buildSummaryRow(
                          'Reservation Fee',
                          '₱${totalPrice.toStringAsFixed(2)}',
                        ),
                        const SizedBox(height: 12),
                        const Divider(color: Colors.transparent), // Spacer
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF334155),
                              ),
                            ),
                            Text(
                              '₱${totalPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Payment Method',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),
            _buildPaymentOption(
              id: 'wallet',
              title: 'In-App Wallet',
              subtitle: 'Balance: ₱500.00',
              icon: Icons.account_balance_wallet,
              color: Colors.purple,
            ),
            const SizedBox(height: 12),
            _buildPaymentOption(
              id: 'gcash',
              title: 'GCash',
              subtitle: 'Pay via mobile wallet',
              icon: Icons.account_balance_wallet, // Placeholder icon
              color: Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildPaymentOption(
              id: 'maya',
              title: 'Maya',
              subtitle: 'Scan or login to pay',
              icon: Icons.qr_code_scanner,
              color: Colors.green,
            ),
            const SizedBox(height: 12),
            _buildPaymentOption(
              id: 'card',
              title: 'Credit / Debit Card',
              subtitle: '',
              icon: Icons.credit_card,
              color: const Color(0xFF137FEC),
              isCard: true,
            ),
            const SizedBox(height: 100), // Bottom padding
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey[200]!)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _processPaymentAndReserve,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF137FEC),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Pay ₱${totalPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward, color: Colors.white),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, size: 14, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text(
                    'SECURED BY 128-BIT SSL',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[400],
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[500],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOption({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    bool isCard = false,
  }) {
    final isSelected = _selectedPaymentMethod == id;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = id;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF137FEC) : Colors.transparent,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF137FEC)
                          : Colors.grey[300]!,
                      width: isSelected ? 6 : 1,
                    ),
                  ),
                ),
              ],
            ),
            if (isCard && isSelected) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              // Simple Card Form
              TextField(
                decoration: InputDecoration(
                  labelText: 'Card Number',
                  hintText: '0000 0000 0000 0000',
                  prefixIcon: const Icon(Icons.payment),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Expiry Date',
                        hintText: 'MM / YY',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'CVV',
                        hintText: '123',
                        suffixIcon: const Icon(Icons.help_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                      ),
                      obscureText: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Cardholder Name',
                  hintText: 'Juan dela Cruz',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
