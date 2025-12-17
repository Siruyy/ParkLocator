import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/api/api.dart' as api;
import 'package:mobile/reservations/view/checkout_page.dart';
import 'package:mobile/venues/models/venue.dart';
import 'package:mobile/venues/repository/venues_repository.dart';

class SpotSelectionPage extends StatefulWidget {
  const SpotSelectionPage({
    required this.venue,
    required this.initialLevelId,
    this.startDate,
    this.endDate,
    super.key,
  });

  final Venue venue;
  final String initialLevelId;
  final DateTime? startDate;
  final DateTime? endDate;

  static Route<void> route({
    required Venue venue,
    required String initialLevelId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return MaterialPageRoute<void>(
      builder: (_) => SpotSelectionPage(
        venue: venue,
        initialLevelId: initialLevelId,
        startDate: startDate,
        endDate: endDate,
      ),
    );
  }

  @override
  State<SpotSelectionPage> createState() => _SpotSelectionPageState();
}

class _SpotSelectionPageState extends State<SpotSelectionPage> {
  late String _selectedLevelId;
  List<Section>? _sections;
  bool _isLoading = false;
  Section? _selectedSection;
  StreamSubscription<dynamic>? _subscription;

  @override
  void initState() {
    super.initState();
    _selectedLevelId = widget.initialLevelId;
    _fetchSpots();
    _subscribeToRealtimeUpdates();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    context.read<api.RealtimeService>().unsubscribeFromLevel(_selectedLevelId);
    super.dispose();
  }

  void _subscribeToRealtimeUpdates() {
    final realtimeService = context.read<api.RealtimeService>();
    realtimeService.subscribeToLevel(_selectedLevelId);

    _subscription = realtimeService.levelUpdates.listen((data) {
      if (data['levelId'] == _selectedLevelId) {
        // Refresh spots when an update is received
        _fetchSpots(isRefresh: true);
      }
    });
  }

  Future<void> _fetchSpots({bool isRefresh = false}) async {
    if (!isRefresh) {
      setState(() {
        _isLoading = true;
        _sections = null;
        _selectedSection = null;
      });
    }

    try {
      final level = await context.read<VenuesRepository>().getLevelDetails(
        _selectedLevelId,
        startAt: widget.startDate,
        endAt: widget.endDate,
      );

      final spots = level.spots ?? [];
      final sectionA = <api.Spot>[];
      final sectionB = <api.Spot>[];

      for (var i = 0; i < spots.length; i++) {
        if (i.isEven) {
          sectionA.add(spots[i]);
        } else {
          sectionB.add(spots[i]);
        }
      }

      if (mounted) {
        setState(() {
          _sections = [
            Section(name: 'Section A', spots: sectionA),
            Section(name: 'Section B', spots: sectionB),
          ];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        if (!isRefresh) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load spots: $e')),
          );
        }
      }
    }
  }

  void _onLevelSelected(String levelId) {
    if (_selectedLevelId == levelId) return;
    setState(() {
      _selectedLevelId = levelId;
    });
    _fetchSpots();
  }

  void _onSectionSelected(Section section) {
    if (section.availableCount == 0) return;
    setState(() {
      _selectedSection = section;
    });
  }

  void _confirmReservation() {
    if (_selectedSection == null) return;

    final availableSpots = _selectedSection!.spots
        .where((s) => s.status == api.SpotStatus.available)
        .toList();

    if (availableSpots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No available spots in this section')),
      );
      return;
    }

    final random = Random();
    final spot = availableSpots[random.nextInt(availableSpots.length)];

    final levels = widget.venue.levels ?? [];
    final currentLevel = levels.firstWhere(
      (l) => l.id == _selectedLevelId,
      orElse: () => levels.first,
    );

    Navigator.push(
      context,
      CheckoutPage.route(
        venue: widget.venue.apiVenue,
        level: currentLevel,
        spot: spot,
        startDate: widget.startDate,
        endDate: widget.endDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final levels = widget.venue.levels ?? [];
    final currentLevel = levels.firstWhere(
      (l) => l.id == _selectedLevelId,
      orElse: () => levels.first,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Select Parking Spot',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Level Selector
          Container(
            color: const Color(0xFFF6F7F8).withValues(alpha: 0.95),
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: levels.map((level) {
                  final isSelected = level.id == _selectedLevelId;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () => _onLevelSelected(level.id),
                      child: Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF137FEC)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          border: isSelected
                              ? null
                              : Border.all(color: Colors.grey[300]!),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF137FEC,
                                    ).withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          level.name,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[600],
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Sections List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _sections == null || _sections!.isEmpty
                ? const Center(child: Text('No sections available'))
                : ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: _sections!.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final section = _sections![index];
                      return _buildSectionCard(section);
                    },
                  ),
          ),
        ],
      ),
      bottomSheet: _selectedSection != null
          ? _buildBottomSheet(currentLevel)
          : null,
    );
  }

  Widget _buildSectionCard(Section section) {
    final isSelected = _selectedSection == section;
    final availableCount = section.availableCount;
    final isAvailable = availableCount > 0;

    // Get unique vehicle types in this section
    final vehicleTypes = section.spots
        .map((s) => s.vehicleType)
        .toSet()
        .toList();

    return GestureDetector(
      onTap: () => _onSectionSelected(section),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF137FEC) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF137FEC) : Colors.grey[200]!,
            width: 2,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: const Color(0xFF137FEC).withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
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
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.2)
                    : const Color(0xFF137FEC).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.local_parking,
                color: isSelected ? Colors.white : const Color(0xFF137FEC),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        section.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      const Spacer(),
                      // Vehicle Type Icons
                      ...vehicleTypes.map((type) {
                        IconData iconData;
                        if (type.toLowerCase() == 'motorcycle') {
                          iconData = Icons.two_wheeler;
                        } else {
                          iconData = Icons.directions_car;
                        }

                        return Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Icon(
                            iconData,
                            size: 18,
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.8)
                                : Colors.grey[400],
                          ),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isAvailable ? '$availableCount spots available' : 'Full',
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.8)
                          : isAvailable
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFEF4444),
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheet(api.Level currentLevel) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_selectedSection!.name} Selected',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${currentLevel.name} • Standard',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 14,
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
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '₱${widget.venue.pricePerHour.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Color(0xFF16A34A),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _confirmReservation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF137FEC),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Select Best Spot',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Section {
  Section({required this.name, required this.spots});

  final String name;
  final List<api.Spot> spots;

  int get availableCount =>
      spots.where((s) => s.status == api.SpotStatus.available).length;
}
