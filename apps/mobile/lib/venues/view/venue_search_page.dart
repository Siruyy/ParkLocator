import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/venues/models/venue.dart';
import 'package:mobile/venues/repository/venues_repository.dart';
import 'package:mobile/venues/widgets/filter_chips.dart';
import 'package:mobile/venues/widgets/venue_card.dart';

class VenueSearchPage extends StatefulWidget {
  const VenueSearchPage({super.key});

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

  @override
  void initState() {
    super.initState();
    _fetchVenues();
  }

  Future<void> _fetchVenues() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      
      // Mock location for now (Cebu IT Park approx)
      const lat = 10.329;
      const lng = 123.906;
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Find Parking',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A), // slate-900
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
                  else
                    ListView.builder(
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
                  // Map Toggle (Floating)
                  Positioned(
                    bottom: 24,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.map),
                        label: const Text('Map View'),
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
            // Bottom Navigation (Mock)
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  const _BottomNavItem(icon: Icons.search, label: 'Search', isActive: true),
                  const _BottomNavItem(icon: Icons.confirmation_number_outlined, label: 'Bookings'),
                  const _BottomNavItem(icon: Icons.account_balance_wallet_outlined, label: 'Wallet'),
                  const _BottomNavItem(icon: Icons.person_outline, label: 'Profile'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.label,
    this.isActive = false,
  });

  final IconData icon;
  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? const Color(0xFF137FEC) : const Color(0xFF94A3B8);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
