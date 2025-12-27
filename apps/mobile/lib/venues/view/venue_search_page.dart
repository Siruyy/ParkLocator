import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile/common/widgets/custom_header.dart';
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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'Nearest';
  Position? _currentPosition;

  // Mock location for now (Manila approx) - used as fallback
  static const _initialLat = 14.5995;
  static const _initialLng = 120.9842;

  @override
  void initState() {
    super.initState();
    _fetchVenues();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return Geolocator.getCurrentPosition();
  }

  Future<void> _fetchVenues({bool isRefresh = false}) async {
    try {
      if (!isRefresh) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }
      
      Position? position;
      try {
        position = await _determinePosition();
        _currentPosition = position;
      } catch (e) {
        debugPrint('Error getting location: $e');
      }

      if (!mounted) return;

      final lat = position?.latitude ?? _initialLat;
      final lng = position?.longitude ?? _initialLng;
      
      const radius = 5000.0; // 5km

      final venues = await context.read<VenuesRepository>().getNearbyVenues(
        lat: lat,
        lng: lng,
        radius: radius,
      );

      setState(() {
        _venues = venues;
        _isLoading = false;
      });
      
      if (_isMapView && position != null) {
        _mapController.move(LatLng(lat, lng), 14);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Venue> get _filteredVenues {
    if (_venues == null) return [];
    
    var filtered = List<Venue>.from(_venues!);

    // Search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((venue) {
        return venue.apiVenue.name.toLowerCase().contains(query) ||
               venue.apiVenue.address.toLowerCase().contains(query);
      }).toList();
    }

    // Sort/Filter based on chips
    switch (_selectedFilter) {
      case 'Nearest':
        filtered.sort((a, b) => (a.apiVenue.distance ?? double.infinity)
            .compareTo(b.apiVenue.distance ?? double.infinity));
        break;
      case 'Cheapest':
        filtered.sort((a, b) => a.pricePerHour.compareTo(b.pricePerHour));
        break;
      case 'Covered':
        filtered = filtered.where((v) => v.hasCoveredParking).toList();
        break;
      // Other filters can be implemented here
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final displayVenues = _filteredVenues;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8), // background-light
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            Container(
              color: const Color(0xFFF6F7F8),
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                children: [
                  // Headline
                  CustomHeader(
                    title: 'Find Parking',
                    showBackButton: !widget.isRoot,
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
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value;
                                });
                              },
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.search, color: Color(0xFF137FEC)),
                                hintText: 'Search destination or venue...',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Filter Chips
                  FilterChips(
                    selectedFilter: _selectedFilter,
                    onSelected: (filter) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                  ),
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
                  else if (displayVenues.isEmpty)
                    const Center(child: Text('No venues found nearby.'))
                  else if (_isMapView)
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _currentPosition != null 
                            ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                            : const LatLng(_initialLat, _initialLng),
                        initialZoom: 14,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.parklocator.mobile',
                        ),
                        MarkerLayer(
                          markers: displayVenues.where((v) => v.latitude != null && v.longitude != null).map((venue) {
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
                        itemCount: displayVenues.length + 2, // +1 for header, +1 for footer
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
                                  letterSpacing: 1,
                                ),
                              ),
                            );
                          }
                          if (index == displayVenues.length + 1) {
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
                          return VenueCard(venue: displayVenues[index - 1]);
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



