import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/api/api.dart' as api;
import 'package:mobile/reservations/view/checkout_page.dart';
import 'package:mobile/venues/models/venue.dart';
import 'package:mobile/venues/repository/venues_repository.dart';
import 'package:mobile/venues/view/vehicle_selection_page.dart';
import 'package:mobile/venues/widgets/level_card.dart';
import 'package:mobile/profile/view/add_vehicle_page.dart';
import 'package:mobile/profile/repository/vehicles_repository.dart';

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
  List<api.Level>?
  _availabilityLevels; // Levels with date-specific availability
  bool _isLoading = true;
  bool _isQuickReserving = false;
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
        availability = await context
            .read<VenuesRepository>()
            .getVenueAvailability(
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
      return _availabilityLevels!.fold(
        0,
        (sum, level) => sum + level.availableSpots,
      );
    }
    // Fall back to venue's default
    return _venue!.availableSpots;
  }

  Future<void> _onQuickReserve() async {
    if (_venue == null) return;

    setState(() {
      _isQuickReserving = true;
    });

    try {
      // 1. Fetch User Vehicles
      final vehicles = await context.read<VehiclesRepository>().getVehicles();

      if (!mounted) return;

      // 2. Handle No Vehicles
      if (vehicles.isEmpty) {
        setState(() => _isQuickReserving = false);
        final result = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('No Vehicle Found'),
            content: const Text(
              'You need to add a vehicle before you can use Quick Reserve.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Add Vehicle'),
              ),
            ],
          ),
        );

        if (result == true && mounted) {
          Navigator.push(context, AddVehiclePage.route());
        }
        return;
      }

      // 3. Determine Vehicle Type
      api.Vehicle? selectedVehicle;

      // If multiple vehicles, ask user to select one
      if (vehicles.length > 1) {
        selectedVehicle = await showModalBottomSheet<api.Vehicle>(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
                    child: Text(
                      'Select Vehicle for Quick Reserve',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: vehicles.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final vehicle = vehicles[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 8,
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _getVehicleIcon(vehicle.type),
                              color: const Color(0xFF137FEC),
                            ),
                          ),
                          title: Text(
                            '${vehicle.make ?? ''} ${vehicle.model ?? ''}'
                                    .trim()
                                    .isEmpty
                                ? vehicle.plateNumber
                                : '${vehicle.make ?? ''} ${vehicle.model ?? ''}'
                                      .trim(),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(vehicle.plateNumber),
                          trailing: vehicle.isDefault
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Default',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                )
                              : null,
                          onTap: () => Navigator.pop(context, vehicle),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );

        if (selectedVehicle == null) {
          // User cancelled selection
          setState(() => _isQuickReserving = false);
          return;
        }
      } else {
        // Only one vehicle
        selectedVehicle = vehicles.first;
      }

      final vehicleType = _normalizeVehicleType(selectedVehicle.type);

      // 4. Find Best Spot
      api.Spot? bestSpot;
      api.Level? bestLevel;

      // Iterate levels to find a spot
      final levels = _venue!.levels ?? [];
      for (final level in levels) {
        if (level.availableSpots <= 0) continue;

        // We need full level details to see spots
        final levelDetails = await context
            .read<VenuesRepository>()
            .getLevelDetails(
              level.id,
              startAt: widget.startDate,
              endAt: widget.endDate,
            );

        final spots = levelDetails.spots ?? [];
        final availableSpot = spots.firstWhere(
          (s) =>
              s.status == api.SpotStatus.available &&
              s.vehicleType.toLowerCase() == vehicleType.toLowerCase(),
          orElse: () => const api.Spot(
            id: 'dummy',
            spotNumber: '',
            status: api.SpotStatus.occupied,
          ),
        );

        if (availableSpot.id != 'dummy') {
          bestSpot = availableSpot;
          bestLevel = level;
          break; // Found one!
        }
      }

      if (!mounted) return;

      if (bestSpot != null && bestLevel != null) {
        // 5. Navigate to Checkout
        setState(() => _isQuickReserving = false);
        Navigator.push(
          context,
          CheckoutPage.route(
            venue: _venue!.apiVenue,
            level: bestLevel,
            spot: bestSpot,
            startDate: widget.startDate,
            endDate: widget.endDate,
          ),
        );
      } else {
        // No spot found
        setState(() => _isQuickReserving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No available ${vehicleType.toLowerCase()} spots found.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isQuickReserving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Quick Reserve failed: $e')),
        );
      }
    }
  }

  String _normalizeVehicleType(String type) {
    switch (type.toLowerCase()) {
      case 'car':
        return 'Car';
      case 'motorcycle':
        return 'Motorcycle';
      case 'truck':
        return 'Truck';
      default:
        return type;
    }
  }

  IconData _getVehicleIcon(String type) {
    switch (type.toLowerCase()) {
      case 'motorcycle':
        return Icons.two_wheeler;
      case 'truck':
        return Icons.local_shipping;
      default:
        return Icons.directions_car;
    }
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
                          overrideAvailableSpots: _isBookForLater
                              ? availableSpots
                              : null,
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
                  onPressed: _isQuickReserving ? null : _onQuickReserve,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF137FEC),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    shadowColor: const Color(0xFF137FEC).withValues(alpha: 0.4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'QUICK RESERVE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                              color: Colors.white70,
                            ),
                          ),
                          _isQuickReserving
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Book Best Available Spot',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
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
