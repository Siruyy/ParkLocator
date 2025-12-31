import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mobile/api/api.dart' as api;
import 'package:mobile/reservations/repository/reservations_repository.dart';
import 'package:mobile/reservations/view/reservation_confirmation_page.dart';
import 'package:mobile/profile/repository/vehicles_repository.dart';

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
  api.Vehicle? _selectedVehicle;

  @override
  void initState() {
    super.initState();
    _fetchVehicles();
  }

  Future<void> _fetchVehicles() async {
    try {
      final vehicles = await context.read<VehiclesRepository>().getVehicles();
      if (mounted && vehicles.isNotEmpty) {
        setState(() {
          _selectedVehicle = vehicles.firstWhere(
            (v) => v.isDefault,
            orElse: () => vehicles.first,
          );
        });
      }
    } catch (e) {
      // Handle error silently - vehicle is optional for reservations
    }
  }

  Future<void> _processPaymentAndReserve() async {
    // Capture ScaffoldMessenger before any async operations
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    setState(() {
      _isProcessing = true;
    });

    // Simulate payment delay
    await Future<void>.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    if (widget.venue.requireVehicleDetails && _selectedVehicle == null) {
      setState(() => _isProcessing = false);
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Please select a vehicle')),
      );
      return;
    }

    try {
      final reservation = await context
          .read<ReservationsRepository>()
          .createReservation(
            venueId: widget.venue.id,
            levelId: widget.level.id,
            spotId: widget.spot.id,
            vehicleId: _selectedVehicle?.id,
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
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
      
      String errorMessage;
      String title = 'Booking Failed';

      if (e is api.ApiException) {
        errorMessage = e.message;
        if (e.statusCode == 409) {
          title = 'Booking Conflict';
        }
      } else {
        errorMessage = e.toString();
        if (errorMessage.contains('Exception:')) {
          errorMessage = errorMessage.replaceAll('Exception:', '').trim();
        }
        if (errorMessage.contains('ApiException:')) {
          errorMessage = errorMessage.replaceAll('ApiException:', '').trim();
        }
      }
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(errorMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
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

    // Get configuration values, with fallback defaults
    final config = widget.venue.configuration;
    final reservationFee = config?.reservationFee ?? 50.0;
    final baseDurationHours = config?.baseDuration ?? 1;

    // Format base duration for display
    String durationStr;
    if (baseDurationHours >= 24) {
      final days = baseDurationHours ~/ 24;
      final remainingHours = baseDurationHours % 24;
      if (remainingHours > 0) {
        durationStr = '$days ${days == 1 ? 'day' : 'days'} $remainingHours ${remainingHours == 1 ? 'hr' : 'hrs'}';
      } else {
        durationStr = '$days ${days == 1 ? 'day' : 'days'}';
      }
    } else {
      durationStr = '$baseDurationHours ${baseDurationHours == 1 ? 'hour' : 'hours'}';
    }

    double totalPrice = reservationFee;

    if (widget.startDate != null && widget.endDate != null) {
      final duration = widget.endDate!.difference(widget.startDate!);

      // Format duration string from actual selection
      final d = duration.inDays;
      final h = duration.inHours % 24;
      final m = duration.inMinutes % 60;

      final parts = <String>[];
      if (d > 0) parts.add('$d ${d == 1 ? 'day' : 'days'}');
      if (h > 0) parts.add('$h ${h == 1 ? 'hr' : 'hrs'}');
      if (m > 0) parts.add('$m mins');
      if (parts.isNotEmpty) {
        durationStr = parts.join(' ');
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
                            color: Colors.grey[200],
                            image: widget.venue.imageUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(
                                      '${context.read<api.ApiClient>().baseUrl.replaceAll('/api/v1', '')}${widget.venue.imageUrl}',
                                    ),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: widget.venue.imageUrl == null
                              ? const Icon(Icons.local_parking, size: 40, color: Colors.grey)
                              : null,
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
