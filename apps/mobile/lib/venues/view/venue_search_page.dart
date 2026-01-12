import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile/common/config.dart';
import 'package:mobile/common/widgets/custom_header.dart';

import 'package:mobile/venues/models/venue.dart';
import 'package:mobile/venues/repository/venues_repository.dart';
import 'package:mobile/venues/widgets/filter_chips.dart';
import 'package:mobile/venues/widgets/venue_card.dart';
import 'package:mobile/venues/view/triangle_clipper.dart';

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
  LatLng? _searchLocation; // Coordinates from geocoding
  double _searchRadius = 20.0; // Default radius in km

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
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    return Geolocator.getCurrentPosition();
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      LatLng? userLocation;
      if (_currentPosition != null) {
        userLocation = LatLng(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );
      }

      final coordinates = await context
          .read<VenuesRepository>()
          .searchDestination(query, userLocation: userLocation);

      if (coordinates != null) {
        setState(() {
          _searchLocation = coordinates;
          // Clear the text filter so we show ALL venues near this location
          // (not just venues whose name contains the search term)
          _searchQuery = '';
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Found Parking Near',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white70,
                          ),
                        ),
                        Text(
                          query,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF137FEC),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 3),
            ),
          );
        }

        // Fetch venues near the new location
        if (mounted) {
          await _fetchVenues();
          // Move map to new location
          if (_isMapView) {
            _mapController.move(coordinates, 14);
          }
        }
      } else {
        // Fallback to text filter if no location found (optional, or show error)
        setState(() => _isLoading = false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not find location "$query"'),
              duration: const Duration(seconds: 3),
              backgroundColor: Colors.red[700],
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Could not find location: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchVenues({bool isRefresh = false}) async {
    try {
      if (!isRefresh) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }

      // Only get current position if we haven't searched for a specific location
      if (_searchLocation == null && _currentPosition == null) {
        try {
          final position = await _determinePosition();
          _currentPosition = position;
        } catch (e) {
          debugPrint('Error getting location: $e');
        }
      }

      if (!mounted) return;

      final lat =
          _searchLocation?.latitude ??
          _currentPosition?.latitude ??
          _initialLat;
      final lng =
          _searchLocation?.longitude ??
          _currentPosition?.longitude ??
          _initialLng;

      debugPrint(
        'Fetching venues at: lat=$lat, lng=$lng, radius=$_searchRadius',
      );

      final venues = await context.read<VenuesRepository>().getNearbyVenues(
        lat: lat,
        lng: lng,
        radius: _searchRadius,
      );

      debugPrint('Received ${venues.length} venues from API');

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
        filtered.sort(
          (a, b) => (a.apiVenue.distance ?? double.infinity).compareTo(
            b.apiVenue.distance ?? double.infinity,
          ),
        );
      case 'Cheapest':
        filtered.sort((a, b) => a.pricePerHour.compareTo(b.pricePerHour));
      case 'Covered':
        filtered = filtered.where((v) => v.hasCoveredParking).toList();
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
              decoration: BoxDecoration(
                color: const Color(0xFFF6F7F8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
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
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              textInputAction: TextInputAction.search,
                              onSubmitted: _performSearch,
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value;
                                });
                              },
                              decoration: InputDecoration(
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: Color(0xFF137FEC),
                                ),
                                suffixIcon: IconButton(
                                  icon: const Icon(
                                    Icons.tune,
                                    color: Colors.grey,
                                  ),
                                  onPressed: _showFilterOptions,
                                ),
                                hintText: 'Search destination or venue...',
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
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
                        initialCenter:
                            _searchLocation ??
                            (_currentPosition != null
                                ? LatLng(
                                    _currentPosition!.latitude,
                                    _currentPosition!.longitude,
                                  )
                                : const LatLng(_initialLat, _initialLng)),
                        initialZoom: 14,
                      ),
                      children: [
                        TileLayer(
                          // Mapbox Dynamic Theme: Streets (Colorful) vs Dark (Night)
                          urlTemplate:
                              'https://api.mapbox.com/styles/v1/${MediaQuery.of(context).platformBrightness == Brightness.dark ? 'mapbox/dark-v11' : 'mapbox/streets-v12'}/tiles/256/{z}/{x}/{y}@2x?access_token=${AppConfig.mapboxAccessToken}',
                          userAgentPackageName: 'com.parklocator.mobile',
                        ),
                        // Layer for User Location (Blue Dot)
                        MarkerLayer(
                          markers: _currentPosition != null
                              ? [
                                  Marker(
                                    point: LatLng(
                                      _currentPosition!.latitude,
                                      _currentPosition!.longitude,
                                    ),
                                    width: 24,
                                    height: 24,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 3,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.2,
                                            ),
                                            blurRadius: 6,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ]
                              : [],
                        ),
                        // Layer for Parking Venues
                        MarkerLayer(
                          markers: displayVenues
                              .where(
                                (v) =>
                                    v.latitude != null && v.longitude != null,
                              )
                              .map((venue) {
                                return Marker(
                                  point: LatLng(
                                    venue.latitude!,
                                    venue.longitude!,
                                  ),
                                  width: 50,
                                  height: 50,
                                  child: GestureDetector(
                                    onTap: () {
                                      // Show Tooltip / Bottom Sheet
                                      showModalBottomSheet<void>(
                                        context: context,
                                        backgroundColor: Colors.transparent,
                                        builder: (context) => Container(
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(24),
                                            ),
                                          ),
                                          padding: const EdgeInsets.only(
                                            top: 8,
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 40,
                                                height: 4,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[300],
                                                  borderRadius:
                                                      BorderRadius.circular(2),
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
                                    child: Column(
                                      children: [
                                        // "P" Icon Marker
                                        Container(
                                          decoration: BoxDecoration(
                                            color: venue.availableSpots > 0
                                                ? const Color(0xFF137FEC)
                                                : Colors.red,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(
                                                  alpha: 0.3,
                                                ),
                                                blurRadius: 6,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          width: 36,
                                          height: 36,
                                          child: const Center(
                                            child: Text(
                                              'P',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 18,
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Triangle pointer (optional simple styling)
                                        ClipPath(
                                          clipper: TriangleClipper(),
                                          child: Container(
                                            color: venue.availableSpots > 0
                                                ? const Color(0xFF137FEC)
                                                : Colors.red,
                                            width: 10,
                                            height: 6,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              })
                              .toList(),
                        ),
                      ],
                    )
                  else
                    RefreshIndicator(
                      onRefresh: () => _fetchVenues(isRefresh: true),
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: displayVenues.length + 1, // +1 for header
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
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

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Search Settings',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Search Radius',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${_searchRadius.toInt()} km',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF137FEC),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: _searchRadius,
                    min: 1,
                    max: 50,
                    divisions: 49,
                    label: '${_searchRadius.toInt()} km',
                    activeColor: const Color(0xFF137FEC),
                    onChanged: (value) {
                      setModalState(() {
                        _searchRadius = value;
                      });
                      // Also update parent state to persist the value
                      setState(() {
                        _searchRadius = value;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _performSearch(_searchQuery); // Refresh search
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF137FEC),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Apply Filters',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
