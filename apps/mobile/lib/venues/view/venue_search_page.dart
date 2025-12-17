import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile/venues/models/venue.dart';
import 'package:mobile/venues/repository/venues_repository.dart';
import 'package:mobile/venues/widgets/filter_chips.dart';
import 'package:mobile/venues/widgets/venue_card.dart';

class VenueSearchPage extends StatefulWidget {
  const VenueSearchPage({super.key, this.isRoot = false});

  final bool isRoot;

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const VenueSearchPage());
  }

  @override
  State<VenueSearchPage> createState() => _VenueSearchPageState();
}

class _VenueSearchPageState extends State<VenueSearchPage> {
  List<Venue>? _venues;
  bool _isLoading = true;
  String? _error;
  bool _isMapView = false;
  final MapController _mapController = MapController();

  // Mock location for now (Manila approx)
  static const _initialLat = 14.5995;
  static const _initialLng = 120.9842;

  @override
  void initState() {
    super.initState();
    _fetchVenues();
  }

  Future<void> _fetchVenues({bool isRefresh = false}) async {
    try {
      if (!isRefresh) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }
      
      const radius = 5000.0; // 5km

      final venues = await context.read<VenuesRepository>().getNearbyVenues(
        lat: _initialLat,
        lng: _initialLng,
        radius: radius,
      );

      setState(() {
        _venues = venues;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8), // background-light
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            Container(
              color: Colors.white,
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                children: [
                  // Headline
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        if (widget.isRoot == false && Navigator.canPop(context))
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.black),
                              onPressed: () => Navigator.pop(context),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ),
                        const Expanded(
                          child: Text(
                            'Find Parking',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A), // slate-900
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined),
                          onPressed: () {},
                          color: const Color(0xFF475569), // slate-600
                        ),
                      ],
                    ),
                  ),
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9), // slate-100
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const TextField(
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.search, color: Color(0xFF137FEC)),
                                hintText: 'Search destination or venue...',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          height: 48,
                          width: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9), // slate-100
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.tune),
                            onPressed: () {},
                            color: const Color(0xFF475569), // slate-600
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Filter Chips
                  const FilterChips(),
                ],
              ),
            ),
            // Main Content Area
            Expanded(
              child: Stack(
                children: [
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_error != null)
                    Center(child: Text('Error: $_error'))
                  else if (_venues == null || _venues!.isEmpty)
                    const Center(child: Text('No venues found nearby.'))
                  else if (_isMapView)
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: const LatLng(_initialLat, _initialLng),
                        initialZoom: 14.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.parklocator.mobile',
                        ),
                        MarkerLayer(
                          markers: _venues!.where((v) => v.latitude != null && v.longitude != null).map((venue) {
                            return Marker(
                              point: LatLng(venue.latitude!, venue.longitude!),
                              width: 50,
                              height: 50,
                              child: GestureDetector(
                                onTap: () {
                                  // Show venue details or navigate
                                  showModalBottomSheet(
                                    context: context,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) => Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                                      ),
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 4,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[300],
                                              borderRadius: BorderRadius.circular(2),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          VenueCard(venue: venue),
                                          const SizedBox(height: 24),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: venue.availableSpots > 0 ? const Color(0xFF137FEC) : Colors.red,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${venue.availableSpots}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    )
                  else
                    RefreshIndicator(
                      onRefresh: () => _fetchVenues(isRefresh: true),
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: _venues!.length + 2, // +1 for header, +1 for footer
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return const Padding(
                              padding: EdgeInsets.only(bottom: 8, left: 4),
                              child: Text(
                                'NEARBY RESULTS',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF94A3B8), // slate-400
                                  letterSpacing: 1.0,
                                ),
                              ),
                            );
                          }
                          if (index == _venues!.length + 1) {
                            // Footer
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 32),
                              child: Column(
                                children: [
                                  Icon(Icons.travel_explore, size: 48, color: Color(0xFFCBD5E1)),
                                  SizedBox(height: 12),
                                  Text(
                                    "That's all the nearby spots.",
                                    style: TextStyle(color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            );
                          }
                          return VenueCard(venue: _venues![index - 1]);
                        },
                      ),
                    ),
                  // Map Toggle (Floating)
                  Positioned(
                    bottom: 24,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _isMapView = !_isMapView;
                          });
                        },
                        icon: Icon(_isMapView ? Icons.list : Icons.map),
                        label: Text(_isMapView ? 'List View' : 'Map View'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E293B), // slate-800
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: const StadiumBorder(),
                          elevation: 8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}



