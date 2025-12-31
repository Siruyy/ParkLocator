import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/api/api.dart' as api;
import 'package:mobile/venues/models/venue.dart';
import 'package:mobile/venues/repository/venues_repository.dart';
import 'package:mobile/venues/view/vehicle_selection_page.dart';
import 'package:mobile/venues/widgets/level_card.dart';

class VenueDetailPage extends StatefulWidget {
  const VenueDetailPage({
    required this.venueId,
    this.startDate,
    this.endDate,
    super.key,
  });

  final String venueId;
  final DateTime? startDate;
  final DateTime? endDate;

  static Route<void> route({
    required String venueId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return MaterialPageRoute<void>(
      builder: (_) => VenueDetailPage(
        venueId: venueId,
        startDate: startDate,
        endDate: endDate,
      ),
    );
  }

  @override
  State<VenueDetailPage> createState() => _VenueDetailPageState();
}

class _VenueDetailPageState extends State<VenueDetailPage> {
  Venue? _venue;
  List<api.Level>? _availabilityLevels; // Levels with date-specific availability
  bool _isLoading = true;
  String? _error;

  bool get _isBookForLater => widget.startDate != null;

  @override
  void initState() {
    super.initState();
    _fetchVenueDetails();
  }

  Future<void> _fetchVenueDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final venue = await context.read<VenuesRepository>().getVenueDetails(
        widget.venueId,
        startAt: widget.startDate,
        endAt: widget.endDate,
      );

      // If booking for later, fetch availability for the specific date range
      List<api.Level>? availability;
      if (_isBookForLater) {
        availability = await context.read<VenuesRepository>().getVenueAvailability(
          widget.venueId,
          startAt: widget.startDate,
          endAt: widget.endDate,
        );
      }

      setState(() {
        _venue = venue;
        _availabilityLevels = availability;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Get the available spots count for a level, considering date range if booking for later
  int _getAvailableSpotsForLevel(api.Level level) {
    if (_availabilityLevels != null) {
      // Find the matching level from availability data
      final availLevel = _availabilityLevels!.firstWhere(
        (l) => l.id == level.id,
        orElse: () => level,
      );
      return availLevel.availableSpots;
    }
    return level.availableSpots;
  }

  /// Get total available spots across all levels
  int _getTotalAvailableSpots() {
    if (_venue == null) return 0;
    
    if (_availabilityLevels != null) {
      // Sum from date-specific availability
      return _availabilityLevels!.fold(0, (sum, level) => sum + level.availableSpots);
    }
    // Fall back to venue's default
    return _venue!.availableSpots;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $_error')),
      );
    }

    if (_venue == null) {
      return const Scaffold(body: Center(child: Text('Venue not found')));
    }

    final venue = _venue!;
    final levels = venue.levels ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          venue.name,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.grey),
            onPressed: () {},
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey[200], height: 1),
        ),
      ),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Text(
                        '${_getTotalAvailableSpots()} Spots ${_isBookForLater ? "Available" : "Total"}',
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF137FEC),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Last updated: Just now',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Filter Chips
              SliverToBoxAdapter(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      _DetailFilterChip(
                        label: 'Sort',
                        icon: Icons.sort,
                        backgroundColor: Colors.grey[200]!,
                        textColor: Colors.black87,
                      ),
                      const SizedBox(width: 12),
                      const _DetailFilterChip(
                        label: 'Most Available',
                        backgroundColor: Color(0xFF137FEC),
                        textColor: Colors.white,
                      ),
                      const SizedBox(width: 12),
                      _DetailFilterChip(
                        label: 'Closest to Entrance',
                        backgroundColor: Colors.grey[200]!,
                        textColor: Colors.black87,
                      ),
                    ],
                  ),
                ),
              ),
              // Levels List
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final level = levels[index];
                      final availableSpots = _getAvailableSpotsForLevel(level);
                      return GestureDetector(
                        onTap: () {
                          VehicleSelectionPage.navigateToSpotSelection(
                            context,
                            venue: _venue!,
                            initialLevelId: level.id,
                            startDate: widget.startDate,
                            endDate: widget.endDate,
                          );
                        },
                        child: LevelCard(
                          level: level,
                          overrideAvailableSpots: _isBookForLater ? availableSpots : null,
                        ),
                      );
                    },
                    childCount: levels.length,
                  ),
                ),
              ),
            ],
          ),
          // Bottom Floating Action Button
          if (widget.startDate == null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    const Color(0xFFF6F7F8),
                    const Color(0xFFF6F7F8).withValues(alpha: 0.8),
                    const Color(0xFFF6F7F8).withValues(alpha: 0),
                  ],
                ),
              ),
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF137FEC),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                  shadowColor: const Color(0xFF137FEC).withValues(alpha: 0.4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'QUICK RESERVE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                            color: Colors.white70,
                          ),
                        ),
                        Text(
                          'Book Best Spot (B1)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '₱${(venue.apiVenue.configuration != null ? (venue.apiVenue.configuration!.baseRate + venue.apiVenue.configuration!.reservationFee) : 40).toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward, size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailFilterChip extends StatelessWidget {
  const _DetailFilterChip({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: textColor),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
