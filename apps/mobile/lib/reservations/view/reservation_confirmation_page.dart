import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile/api/api.dart' as api;
import 'package:qr_flutter/qr_flutter.dart';

class ReservationConfirmationPage extends StatefulWidget {
  const ReservationConfirmationPage({
    required this.reservation,
    super.key,
  });

  final api.Reservation reservation;

  static Route<void> route({required api.Reservation reservation}) {
    return MaterialPageRoute<void>(
      builder: (_) => ReservationConfirmationPage(reservation: reservation),
    );
  }

  @override
  State<ReservationConfirmationPage> createState() =>
      _ReservationConfirmationPageState();
}

class _ReservationConfirmationPageState
    extends State<ReservationConfirmationPage> {
  Timer? _timer;
  Duration _timeLeft = Duration.zero;

  bool get _shouldShowCountdown {
    // Don't show countdown for multi-day reservations
    if (widget.reservation.isMultiDay) return false;
    // Only show countdown when arrival window is active
    return widget.reservation.isArrivalWindowActive;
  }

  @override
  void initState() {
    super.initState();
    if (_shouldShowCountdown) {
      _calculateTimeLeft();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(_calculateTimeLeft);
        }
      });
    }
  }

  void _calculateTimeLeft() {
    final now = DateTime.now();
    final expiresAt = widget.reservation.expiresAt;
    final difference = expiresAt.difference(now);

    if (difference.isNegative) {
      _timeLeft = Duration.zero;
      _timer?.cancel();
    } else {
      _timeLeft = difference;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _buildCountdownSection(String minutes, String seconds) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF137FEC).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF137FEC).withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Entry window closes in:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF0D141B).withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                minutes,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF137FEC),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  ':',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF137FEC),
                  ),
                ),
              ),
              Text(
                seconds,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF137FEC),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Please arrive on time to secure your spot',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF137FEC).withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationStatusSection() {
    final reservation = widget.reservation;
    final startAt = reservation.startAt;
    final endAt = reservation.endAt;
    final isMultiDay = reservation.isMultiDay;
    final isFuture = reservation.isFutureReservation;

    // Format dates
    var dateRange = '';
    if (startAt != null && endAt != null) {
      final startDate =
          '${startAt.month}/${startAt.day}/${startAt.year}';
      final endDate =
          '${endAt.month}/${endAt.day}/${endAt.year}';
      final startTime = _formatTime(startAt);
      final endTime = _formatTime(endAt);

      if (isMultiDay) {
        dateRange = '$startDate $startTime - $endDate $endTime';
      } else {
        dateRange = '$startDate, $startTime - $endTime';
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isFuture
            ? const Color(0xFF4CAF50).withValues(alpha: 0.08)
            : const Color(0xFF137FEC).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFuture
              ? const Color(0xFF4CAF50).withValues(alpha: 0.2)
              : const Color(0xFF137FEC).withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isFuture ? Icons.event_available : Icons.local_parking,
                color: isFuture
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFF137FEC),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isFuture ? 'Reserved' : 'Active',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isFuture
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFF137FEC),
                ),
              ),
            ],
          ),
          if (dateRange.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              dateRange,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF0D141B).withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (isFuture && !isMultiDay && startAt != null) ...[
            const SizedBox(height: 8),
            Text(
              'Arrival window opens 1 hour before start time',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF4CAF50).withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (isMultiDay) ...[
            const SizedBox(height: 8),
            Text(
              'Valid for the entire reservation period',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF4CAF50).withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final minutes =
        _timeLeft.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds =
        _timeLeft.inSeconds.remainder(60).toString().padLeft(2, '0');

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                children: [
                  // Top Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context)
                              .popUntil((route) => route.isFirst),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.transparent,
                            ),
                            child: const Icon(Icons.close, color: Colors.black),
                          ),
                        ),
                        const Expanded(
                          child: Text(
                            'Ticket Details',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(width: 48), // Balance
                      ],
                    ),
                  ),

                  // Success Header
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_circle,
                            color: Colors.green[600],
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Booking Confirmed!',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D141B),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Payment successful! You're all set.",
                          style: TextStyle(
                            fontSize: 16,
                            color:
                                const Color(0xFF0D141B).withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // QR Code Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[100]!),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 24,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.qr_code_scanner,
                                  color: Color(0xFF137FEC), size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Scan at entry',
                                style: TextStyle(
                                  color: Color(0xFF137FEC),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Container(
                            width: 256,
                            height: 256,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[100]!),
                            ),
                            child: QrImageView(
                              data: widget.reservation.qrCode ??
                                  widget.reservation.id,
                              size: 220,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            '#${widget.reservation.id.substring(0, 8).toUpperCase()}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D141B),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const Text(
                            'Ticket ID',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF4C739A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Countdown Section or Reservation Status
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: _shouldShowCountdown
                        ? _buildCountdownSection(minutes, seconds)
                        : _buildReservationStatusSection(),
                  ),

                  // Location Details Card
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[100]!),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          // Map Placeholder
                          Container(
                            height: 128,
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              color: Colors.grey,
                              image: DecorationImage(
                                image: NetworkImage(
                                    'https://lh3.googleusercontent.com/aida-public/AB6AXuAhDcxIexqCtdbqp2w9vaXLf-kRv43kMXLTyNOjxCKX7Xc5DghgE8pHR2GaJuVqLwE4ypiJvgK-KV5NRtnLRFYMvK2cOKvHjDbQajUBrKv1l5oCy4h_RPP0Sh510gjp19bll-xwAOu7HEd_0JlSg-EdaDN2CH8Xy9ejg8bVIavvoChCZcPIM0ZVL1w9QIXYqHuj4mTx5rNL5toCxnelnOb4XU8OPrHsahU-NUS8Nwq_5FNJM8uYdZtBhnJKfQoIm82tZr6ja2qoltEV'),
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.location_on,
                                  color: Color(0xFF137FEC),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.reservation.venue?.name ??
                                            'Venue Name',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0D141B),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        widget.reservation.venue?.address ??
                                            'Address',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF4C739A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF6F7F8),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    children: [
                                      const Text(
                                        'SPOT',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF4C739A),
                                        ),
                                      ),
                                      Text(
                                        widget.reservation.spot?.spotNumber
                                                .split('-')
                                                .last ??
                                            '--',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF137FEC),
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
                  ),
                ],
              ),
            ),

            // Sticky Bottom Action Bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F7F8).withValues(alpha: 0.9),
                  border: Border(
                    top: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: Implement navigation
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF137FEC),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.navigation, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Navigate to Venue',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        // TODO: Implement save to photos
                      },
                      child: const Text(
                        'Save to Photos',
                        style: TextStyle(
                          color: Color(0xFF137FEC),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
