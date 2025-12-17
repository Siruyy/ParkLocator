import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:mobile/api/api.dart' as api;
import 'package:mobile/notifications/notifications.dart';
import 'package:mobile/reservations/repository/reservations_repository.dart';
import 'package:mobile/reservations/view/booking_expired_page.dart';
import 'package:mobile/reservations/view/reservation_detail_page.dart';
import 'package:mobile/venues/view/venue_search_page.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Home page - Dashboard with active booking
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const HomePage());
  }

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  api.Reservation? _activeReservation;
  List<api.Reservation> _upcomingReservations = [];
  List<api.Reservation> _recentActivity = [];
  bool _isLoading = true;
  Timer? _timer;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _activeReservation != null) {
        setState(_calculateTimeLeft);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      setState(() => _isLoading = true);

      final repo = context.read<ReservationsRepository>();
      final active = await repo.getActiveReservations();
      final all = await repo.getReservations();

      // Filter out active reservations that are actually expired by time
      final now = DateTime.now();
      final trulyActive = active
          .where((r) => r.expiresAt.isAfter(now))
          .toList();
      final expiredActive = active
          .where((r) => r.expiresAt.isBefore(now))
          .toList();

      // Sort active reservations by creation time descending (Newest first)
      // This ensures the most recently booked spot is shown as the active one
      trulyActive.sort((a, b) {
        final aTime = a.createdAt ?? DateTime.now();
        final bTime = b.createdAt ?? DateTime.now();
        return bTime.compareTo(aTime); // Descending: Newest first
      });

      setState(() {
        if (trulyActive.isNotEmpty) {
          _activeReservation = trulyActive.first;
          _upcomingReservations = trulyActive.skip(1).toList();
        } else {
          _activeReservation = null;
          _upcomingReservations = [];
        }

        // Include time-expired reservations in recent activity
        // even if their status is still 'confirmed'
        _recentActivity = [
          ...expiredActive,
          ...all.where(
            (r) =>
                r.status == api.ReservationStatus.completed ||
                r.status == api.ReservationStatus.cancelled ||
                r.status == api.ReservationStatus.expired ||
                r.status == api.ReservationStatus.noShow,
          ),
        ];

        // Sort by date desc and take 5
        _recentActivity.sort(
          (a, b) => (b.createdAt ?? DateTime.now()).compareTo(
            a.createdAt ?? DateTime.now(),
          ),
        );
        _recentActivity = _recentActivity.take(5).toList();

        _isLoading = false;
        _calculateTimeLeft();
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Handle error silently or show snackbar
    }
  }

  void _calculateTimeLeft() {
    if (_activeReservation == null) return;
    final now = DateTime.now();
    // Use endAt (base duration end) for countdown, fallback to expiresAt
    final endAt = _activeReservation!.endAt ?? _activeReservation!.expiresAt;
    final difference = endAt.difference(now);

    if (difference.isNegative) {
      _timeLeft = Duration.zero;
    } else {
      _timeLeft = difference;
    }
  }

  Future<void> _onMapPressed(api.Reservation reservation) async {
    if (reservation.venue == null) return;

    final lat = reservation.venue!.latitude;
    final lng = reservation.venue!.longitude;

    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Venue location not available')),
      );
      return;
    }

    try {
      final availableMaps = await MapLauncher.installedMaps;

      if (!mounted) return;

      if (availableMaps.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No map apps installed')),
        );
        return;
      }

      await showModalBottomSheet<void>(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Text(
                        'Open in Maps',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Wrap(
                      children: <Widget>[
                        for (final map in availableMaps)
                          ListTile(
                            onTap: () {
                              Navigator.pop(context);
                              map.showMarker(
                                coords: Coords(lat, lng),
                                title:
                                    reservation.venue?.name ?? 'Parking Spot',
                              );
                            },
                            title: Text(map.mapName),
                            leading: SvgPicture.asset(
                              map.icon,
                              height: 30,
                              width: 30,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error launching maps: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopAppBar(),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Current Booking',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_activeReservation != null)
                  _buildActiveBookingCard()
                else
                  _buildNoActiveBookingCard(),

                if (_upcomingReservations.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Your Bookings',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildUpcomingBookingsList(),
                ],

                const SizedBox(height: 24),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Recent Activity',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildRecentActivityList(),
                const SizedBox(height: 80), // Bottom spacer
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey[300]!),
                  image: const DecorationImage(
                    image: NetworkImage(
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuDm5c2sSpmv-qGIGemqCCLfHFVGggRwGhFl-dEClUSROu_yMZu97wrzl6HpO-WfCbKn58d1zbwbPIsay4qMl2wHAQ3RMTTaN60QHXVb-JnqZ0E4pjanQQ3UGc3X8gqnXYaz_n2_-ZoKdnNscD7Z61sDcTl_8KVonDjnfXfq019lKHJg5RJmrt41qYwKbqIKnbZ3R6jCFJXkmfnojEIb0TC0ivzhvGVsgAkLeRlIpWK9qYQRHjW2V9V_Ln5bZ4QYqNOE9Iwi-HAElHNk',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'ParkLocator',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: IconButton(
              icon: const Icon(Icons.notifications_outlined, size: 24),
              color: const Color(0xFF0F172A),
              onPressed: () {
                Navigator.of(context).push(NotificationsPage.route());
              },
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveBookingCard() {
    final reservation = _activeReservation!;
    final isMultiDay = reservation.isMultiDay;
    final isFuture = reservation.isFutureReservation;
    final isArrivalWindowActive = reservation.isArrivalWindowActive;

    // Only show countdown for non-multi-day reservations when arrival window is active
    final shouldShowCountdown = !isMultiDay && isArrivalWindowActive;

    final hours = _timeLeft.inHours.toString().padLeft(2, '0');
    final minutes = _timeLeft.inMinutes
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    final seconds = _timeLeft.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');

    // Calculate progress
    final totalDuration = reservation.expiresAt.difference(
      reservation.createdAt ??
          DateTime.now().subtract(const Duration(hours: 1)),
    );
    final elapsed = DateTime.now().difference(
      reservation.createdAt ??
          DateTime.now().subtract(const Duration(hours: 1)),
    );
    final progress = (elapsed.inSeconds / totalDuration.inSeconds).clamp(
      0.0,
      1.0,
    );

    // Determine status label and color
    String statusLabel;
    Color statusColor;
    if (_timeLeft == Duration.zero) {
      statusLabel = 'EXPIRED';
      statusColor = Colors.red;
    } else if (isFuture && !isArrivalWindowActive) {
      statusLabel = 'RESERVED';
      statusColor = const Color(0xFF4CAF50);
    } else {
      statusLabel = 'ACTIVE NOW';
      statusColor = Colors.green;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // Map/Image Header
            Stack(
              children: [
                Container(
                  height: 192,
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
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey[100]!),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          statusLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Venue Info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              reservation.venue?.name ?? 'Venue Name',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 18,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${reservation.level?.name ?? 'Level'}, Slot ${reservation.spot?.spotNumber ?? '--'}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₱ ${reservation.amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF137FEC),
                            ),
                          ),
                          const Text(
                            'reservation fee',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Timer Widget or Reservation Info
                  if (shouldShowCountdown)
                    _buildCountdownWidget(
                      reservation,
                      hours,
                      minutes,
                      seconds,
                      progress,
                    )
                  else
                    _buildReservationInfoWidget(
                      reservation,
                      isMultiDay,
                      isFuture,
                    ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () => _showQrCode(context, reservation),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF137FEC),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.qr_code_2),
                              SizedBox(width: 8),
                              Text(
                                'Show Pass',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _onMapPressed(reservation),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: Colors.grey[200]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.near_me, color: Color(0xFF137FEC)),
                              SizedBox(width: 8),
                              Text(
                                'Map',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
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
    );
  }

  Widget _buildNoActiveBookingCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_parking,
                size: 48,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Active Booking',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Find a parking spot near you',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(context, VenueSearchPage.route());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF137FEC),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Find Parking'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingBookingsList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _upcomingReservations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final reservation = _upcomingReservations[index];
        final startAt =
            reservation.startAt ?? reservation.createdAt ?? DateTime.now();

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              ReservationDetailPage.route(reservation: reservation),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.event_available,
                    color: Color(0xFF4CAF50),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reservation.venue?.name ?? 'Unknown Venue',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 14,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('MMM d, h:mm a').format(startAt),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: startAt.isBefore(DateTime.now())
                        ? const Color(0xFF137FEC).withValues(alpha: 0.1)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    startAt.isBefore(DateTime.now()) ? 'Active' : 'Upcoming',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: startAt.isBefore(DateTime.now())
                          ? const Color(0xFF137FEC)
                          : const Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentActivityList() {
    if (_recentActivity.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Text('No recent activity', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _recentActivity.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final reservation = _recentActivity[index];
        return GestureDetector(
          onTap: () {
            if (reservation.status == api.ReservationStatus.expired ||
                reservation.status == api.ReservationStatus.cancelled ||
                reservation.status == api.ReservationStatus.noShow) {
              Navigator.push(
                context,
                BookingExpiredPage.route(reservation: reservation),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[100]!),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.local_parking, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reservation.venue?.name ?? 'Unknown Venue',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        DateFormat(
                          'MMM d • h:mm a',
                        ).format(reservation.createdAt ?? DateTime.now()),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₱ ${reservation.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    if (reservation.status == api.ReservationStatus.expired)
                      const Text(
                        'EXPIRED',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCountdownWidget(
    api.Reservation reservation,
    String hours,
    String minutes,
    String seconds,
    double progress,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TIME REMAINING',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.5,
                ),
              ),
              if (_timeLeft.inMinutes < 15 && _timeLeft > Duration.zero)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning, size: 12, color: Colors.orange),
                      SizedBox(width: 4),
                      Text(
                        'EXPIRING SOON',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              _buildTimeSegment(hours, 'HOURS'),
              _buildTimeSeparator(),
              _buildTimeSegment(minutes, 'MINS'),
              _buildTimeSeparator(),
              _buildTimeSegment(seconds, 'SECS', isPrimary: true),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF137FEC),
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Start: ${DateFormat('h:mm a').format(reservation.startAt ?? DateTime.now())}',
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'End: ${DateFormat('h:mm a').format(reservation.endAt ?? reservation.expiresAt)}',
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReservationInfoWidget(
    api.Reservation reservation,
    bool isMultiDay,
    bool isFuture,
  ) {
    final startAt = reservation.startAt;
    final endAt = reservation.endAt;

    // Format dates
    var dateRange = '';
    if (startAt != null && endAt != null) {
      final startDate = DateFormat('MMM d, yyyy').format(startAt);
      final endDate = DateFormat('MMM d, yyyy').format(endAt);
      final startTime = DateFormat('h:mm a').format(startAt);
      final endTime = DateFormat('h:mm a').format(endAt);

      if (isMultiDay) {
        dateRange = '$startDate $startTime\n→ $endDate $endTime';
      } else {
        dateRange = '$startDate\n$startTime - $endTime';
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isFuture
            ? const Color(0xFF4CAF50).withValues(alpha: 0.05)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFuture
              ? const Color(0xFF4CAF50).withValues(alpha: 0.2)
              : Colors.grey[200]!,
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
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'RESERVATION DETAILS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isFuture
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFF64748B),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          if (dateRange.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              dateRange,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isFuture
                  ? const Color(0xFF4CAF50).withValues(alpha: 0.1)
                  : const Color(0xFF137FEC).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              isMultiDay
                  ? 'Valid for the entire reservation period'
                  : isFuture
                  ? 'Arrival window opens 1 hour before start'
                  : 'Your spot is ready',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isFuture
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFF137FEC),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSegment(
    String value,
    String label, {
    bool isPrimary = false,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: isPrimary
                ? const Color(0xFF137FEC)
                : const Color(0xFF0F172A),
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSeparator() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        ':',
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w300,
          color: Color(0xFFCBD5E1),
          height: 1,
        ),
      ),
    );
  }

  void _showQrCode(BuildContext context, api.Reservation reservation) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Scan at Entry',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              QrImageView(
                data: reservation.qrCode ?? reservation.id,
                size: 200,
              ),
              const SizedBox(height: 24),
              Text(
                '#${reservation.id.substring(0, 8).toUpperCase()}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
