import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/api/api.dart' as api;
import 'package:mobile/profile/repository/vehicles_repository.dart';
import 'package:mobile/venues/models/venue.dart';
import 'package:mobile/venues/view/spot_selection_page.dart';

/// Page for selecting vehicle type before choosing a parking spot.
/// This ensures sections are filtered by the user's vehicle type.
class VehicleSelectionPage extends StatefulWidget {
  const VehicleSelectionPage({
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
      builder: (_) => VehicleSelectionPage(
        venue: venue,
        initialLevelId: initialLevelId,
        startDate: startDate,
        endDate: endDate,
      ),
    );
  }

  /// Smart navigation - skips vehicle selection if venue doesn't require vehicle details
  static void navigateToSpotSelection(
    BuildContext context, {
    required Venue venue,
    required String initialLevelId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    if (!venue.requireVehicleDetails) {
      // Skip vehicle selection, go directly to spot selection with no filter
      Navigator.push(
        context,
        SpotSelectionPage.route(
          venue: venue,
          initialLevelId: initialLevelId,
          startDate: startDate,
          endDate: endDate,
        ),
      );
    } else {
      // Show vehicle selection page
      Navigator.push(
        context,
        VehicleSelectionPage.route(
          venue: venue,
          initialLevelId: initialLevelId,
          startDate: startDate,
          endDate: endDate,
        ),
      );
    }
  }

  @override
  State<VehicleSelectionPage> createState() => _VehicleSelectionPageState();
}

class _VehicleSelectionPageState extends State<VehicleSelectionPage> {
  String? _selectedVehicleType;
  String? _selectedVehicleId;
  List<api.Vehicle>? _userVehicles;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserVehicles();
  }

  Future<void> _loadUserVehicles() async {
    try {
      final vehicles = await context.read<VehiclesRepository>().getVehicles();
      setState(() {
        _userVehicles = vehicles;
        _isLoading = false;

        // Pre-select default vehicle if exists
        final defaultVehicle = vehicles.where((v) => v.isDefault).firstOrNull;
        if (defaultVehicle != null) {
          _selectedVehicleId = defaultVehicle.id;
          _selectedVehicleType = _normalizeVehicleType(defaultVehicle.type);
        }
      });
    } catch (e) {
      setState(() {
        _userVehicles = [];
        _isLoading = false;
      });
    }
  }

  /// Normalize vehicle type to match backend format (Car, Motorcycle, Truck)
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

  void _onVehicleSelected(api.Vehicle vehicle) {
    final normalizedType = _normalizeVehicleType(vehicle.type);
    setState(() {
      // Toggle off if already selected
      if (_selectedVehicleId == vehicle.id) {
        _selectedVehicleId = null;
        _selectedVehicleType = null;
      } else {
        // Select this vehicle and its type
        _selectedVehicleId = vehicle.id;
        _selectedVehicleType = normalizedType;
      }
    });
  }

  void _continue() {
    if (_selectedVehicleType == null) return;

    Navigator.push(
      context,
      SpotSelectionPage.route(
        venue: widget.venue,
        initialLevelId: widget.initialLevelId,
        startDate: widget.startDate,
        endDate: widget.endDate,
        vehicleType: _selectedVehicleType,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? const Color(0xFF101922)
        : const Color(0xFFF6F7F8);
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subTextColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    const primaryColor = Color(0xFF137FEC);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: surfaceColor.withValues(alpha: 0.95),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Select Vehicle',
          style: GoogleFonts.inter(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: isDark ? Colors.grey[800] : Colors.grey[200],
            height: 1,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      'What are you driving?',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select your vehicle type to find compatible parking spots.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: subTextColor,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // User's saved vehicles
                    if (_userVehicles != null && _userVehicles!.isNotEmpty) ...[
                      Text(
                        'Your Vehicles',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._userVehicles!.map((vehicle) {
                        final normalizedType = _normalizeVehicleType(
                          vehicle.type,
                        );
                        final isSelected = _selectedVehicleId == vehicle.id;
                        return _buildVehicleCard(
                          title:
                              '${vehicle.make ?? ''} ${vehicle.model ?? ''}'
                                  .trim()
                                  .isEmpty
                              ? vehicle.plateNumber
                              : '${vehicle.make ?? ''} ${vehicle.model ?? ''}'
                                    .trim(),
                          subtitle: vehicle.plateNumber,
                          type: normalizedType,
                          icon: _getVehicleIcon(vehicle.type),
                          isSelected: isSelected,
                          isDefault: vehicle.isDefault,
                          onTap: () => _onVehicleSelected(vehicle),
                          isDark: isDark,
                          surfaceColor: surfaceColor,
                          textColor: textColor,
                          subTextColor: subTextColor,
                          primaryColor: primaryColor,
                        );
                      }),
                      const SizedBox(height: 100), // Space for button
                    ],
                  ],
                ),
              ),
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceColor,
          border: Border(
            top: BorderSide(
              color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
            ),
          ),
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _selectedVehicleType != null ? _continue : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              disabledBackgroundColor: isDark
                  ? Colors.grey[700]
                  : Colors.grey[300],
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Continue',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
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

  Widget _buildVehicleCard({
    required String title,
    required String subtitle,
    required String type,
    required IconData icon,
    required bool isSelected,
    required bool isDefault,
    required VoidCallback onTap,
    required bool isDark,
    required Color surfaceColor,
    required Color textColor,
    required Color subTextColor,
    required Color primaryColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withValues(alpha: 0.1)
              : surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? primaryColor
                : (isDark ? Colors.grey[700]! : Colors.grey[200]!),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? primaryColor.withValues(alpha: 0.2)
                    : (isDark ? Colors.grey[800] : Colors.grey[100]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? primaryColor : subTextColor,
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
                      Flexible(
                        child: Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Default',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: subTextColor,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              )
            else
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
                  ),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
