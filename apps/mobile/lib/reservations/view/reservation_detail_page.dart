import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gal/gal.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:mobile/api/api.dart' as api;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';

class ReservationDetailPage extends StatefulWidget {
  const ReservationDetailPage({
    required this.reservation,
    super.key,
  });

  final api.Reservation reservation;

  static Route<void> route({required api.Reservation reservation}) {
    return MaterialPageRoute<void>(
      builder: (_) => ReservationDetailPage(reservation: reservation),
    );
  }

  @override
  State<ReservationDetailPage> createState() => _ReservationDetailPageState();
}

class _ReservationDetailPageState extends State<ReservationDetailPage> {
  final ScreenshotController _screenshotController = ScreenshotController();
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
      final startDate = '${startAt.month}/${startAt.day}/${startAt.year}';
      final endDate = '${endAt.month}/${endAt.day}/${endAt.year}';
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
    final minutes = _timeLeft.inMinutes
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    final seconds = _timeLeft.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Reservation Details',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                children: [
                  // QR Code Card
                  Padding(
                    padding: const EdgeInsets.all(24),
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
                              Icon(
                                Icons.qr_code_scanner,
                                color: Color(0xFF137FEC),
                                size: 20,
                              ),
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
                          Screenshot(
                            controller: _screenshotController,
                            child: Container(
                              width: 256,
                              height: 256,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[100]!),
                              ),
                              child: QrImageView(
                                data:
                                    widget.reservation.qrCode ??
                                    widget.reservation.id,
                                size: 220,
                              ),
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
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _shouldShowCountdown
                        ? _buildCountdownSection(minutes, seconds)
                        : _buildReservationStatusSection(),
                  ),

                  const SizedBox(height: 24),

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
                          // TODO: Replace with dynamic Google Maps Static API URL
                          Container(
                            height: 128,
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              color: Colors.grey,
                              image: DecorationImage(
                                image: NetworkImage(
                                  'https://lh3.googleusercontent.com/aida-public/AB6AXuAhDcxIexqCtdbqp2w9vaXLf-kRv43kMXLTyNOjxCKX7Xc5DghgE8pHR2GaJuVqLwE4ypiJvgK-KV5NRtnLRFYMvK2cOKvHjDbQajUBrKv1l5oCy4h_RPP0Sh510gjp19bll-xwAOu7HEd_0JlSg-EdaDN2CH8Xy9ejg8bVIavvoChCZcPIM0ZVL1w9QIXYqHuj4mTx5rNL5toCxnelnOb4XU8OPrHsahU-NUS8Nwq_5FNJM8uYdZtBhnJKfQoIm82tZr6ja2qoltEV',
                                ),
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
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
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
                                        widget.reservation.spot?.spotNumber ??
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
                        onPressed: () async {
                          final lat = widget.reservation.venue?.latitude;
                          final lng = widget.reservation.venue?.longitude;
                          final title =
                              widget.reservation.venue?.name ?? 'Venue';

                          if (lat == null || lng == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Venue location not available'),
                              ),
                            );
                            return;
                          }

                          try {
                            final availableMaps =
                                await MapLauncher.installedMaps;
                            if (!mounted) return;

                            if (availableMaps.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('No map apps installed'),
                                ),
                              );
                              return;
                            }

                            await showModalBottomSheet<void>(
                              context: context,
                              builder: (BuildContext context) {
                                return SafeArea(
                                  child: SingleChildScrollView(
                                    child: Wrap(
                                      children: <Widget>[
                                        for (final map in availableMaps)
                                          ListTile(
                                            onTap: () => map.showMarker(
                                              coords: Coords(lat, lng),
                                              title: title,
                                            ),
                                            title: Text(map.mapName),
                                            leading: SvgPicture.asset(
                                              map.icon,
                                              height: 30,
                                              width: 30,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error launching map: $e'),
                              ),
                            );
                          }
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
                      onPressed: () async {
                        try {
                          final image = await _screenshotController.capture();
                          if (image == null) return;

                          await Gal.putImageBytes(image);
                          if (!mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('QR Code saved to photos'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error saving to photos: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
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
