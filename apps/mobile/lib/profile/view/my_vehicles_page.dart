import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/api/api.dart' as api;
import 'package:mobile/profile/repository/vehicles_repository.dart';
import 'package:mobile/profile/view/add_vehicle_page.dart';
import 'package:mobile/profile/view/edit_vehicle_page.dart';

class MyVehiclesPage extends StatefulWidget {
  const MyVehiclesPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const MyVehiclesPage());
  }

  @override
  State<MyVehiclesPage> createState() => _MyVehiclesPageState();
}

class _MyVehiclesPageState extends State<MyVehiclesPage> {
  List<api.Vehicle> _vehicles = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchVehicles();
  }

  Future<void> _fetchVehicles() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = context.read<VehiclesRepository>();
      final vehicles = await repository.getVehicles();
      if (mounted) {
        setState(() {
          _vehicles = vehicles;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteVehicle(api.Vehicle vehicle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Vehicle'),
        content: Text(
          'Are you sure you want to remove ${vehicle.make ?? ''} ${vehicle.model ?? ''} (${vehicle.plateNumber})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      try {
        final repository = context.read<VehiclesRepository>();
        await repository.deleteVehicle(vehicle.id);
        _fetchVehicles();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to remove vehicle: $e')),
          );
        }
      }
    }
  }

  Future<void> _setAsDefault(api.Vehicle vehicle) async {
    try {
      final repository = context.read<VehiclesRepository>();
      await repository.updateVehicle(vehicle.id, isDefault: true);
      _fetchVehicles();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to set default: $e')),
        );
      }
    }
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
        backgroundColor: backgroundColor.withValues(alpha: 0.9),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'My Vehicles',
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
      body: _buildBody(
        isDark: isDark,
        surfaceColor: surfaceColor,
        textColor: textColor,
        subTextColor: subTextColor,
        primaryColor: primaryColor,
        backgroundColor: backgroundColor,
      ),
    );
  }

  Widget _buildBody({
    required bool isDark,
    required Color surfaceColor,
    required Color textColor,
    required Color subTextColor,
    required Color primaryColor,
    required Color backgroundColor,
  }) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: subTextColor),
            const SizedBox(height: 16),
            Text('Failed to load vehicles', style: TextStyle(color: textColor)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _fetchVehicles,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchVehicles,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Add New Vehicle Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _vehicles.length >= 5
                      ? null
                      : () async {
                          await Navigator.of(
                            context,
                          ).push(AddVehiclePage.route());
                          _fetchVehicles(); // Refresh after returning
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey,
                    elevation: 2,
                    shadowColor: primaryColor.withValues(alpha: 0.4),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _vehicles.length >= 5
                            ? 'Vehicle Limit Reached (5/5)'
                            : 'Add New Vehicle',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Registered Vehicles Header
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 16),
                child: Text(
                  'REGISTERED VEHICLES (${_vehicles.length}/5)',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: subTextColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              // Vehicle List
              if (_vehicles.isEmpty)
                Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 32),
                      Icon(
                        Icons.directions_car_outlined,
                        size: 64,
                        color: subTextColor.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No vehicles yet',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: subTextColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add a vehicle to start booking parking spots',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: subTextColor.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                )
              else
                ...List.generate(_vehicles.length, (index) {
                  final vehicle = _vehicles[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index < _vehicles.length - 1 ? 16 : 0,
                    ),
                    child: _VehicleCard(
                      vehicle: vehicle,
                      assetBaseUrl: context.read<api.ApiClient>().assetBaseUrl,
                      isDefault: vehicle.isDefault,
                      isDark: isDark,
                      surfaceColor: surfaceColor,
                      textColor: textColor,
                      subTextColor: subTextColor,
                      primaryColor: primaryColor,
                      onEdit: () async {
                        await Navigator.of(context).push(
                          EditVehiclePage.route(
                            vehicleId: vehicle.id,
                            make: vehicle.make ?? '',
                            model: vehicle.model ?? '',
                            plateNumber: vehicle.plateNumber,
                            color: vehicle.color ?? '',
                            isDefault: vehicle.isDefault,
                            type: vehicle.type,
                          ),
                        );
                        _fetchVehicles();
                      },
                      onDelete: () => _deleteVehicle(vehicle),
                      onSetDefault: () => _setAsDefault(vehicle),
                    ),
                  );
                }),

              const SizedBox(height: 32),

              // Footer Text
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'Ensure your plate numbers are accurate to avoid issues with parking enforcement. You can manage up to 5 vehicles.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: subTextColor,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({
    required this.vehicle,
    required this.assetBaseUrl,
    required this.isDefault,
    required this.isDark,
    required this.surfaceColor,
    required this.textColor,
    required this.subTextColor,
    required this.primaryColor,
    required this.onEdit,
    required this.onDelete,
    required this.onSetDefault,
  });

  final api.Vehicle vehicle;
  final String assetBaseUrl;
  final bool isDefault;
  final bool isDark;
  final Color surfaceColor;
  final Color textColor;
  final Color subTextColor;
  final Color primaryColor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;

  IconData _getVehicleIcon() {
    switch (vehicle.type.toLowerCase()) {
      case 'motorcycle':
        return Icons.two_wheeler;
      case 'truck':
        return Icons.local_shipping;
      default:
        return Icons.directions_car;
    }
  }

  String _getDisplayName() {
    final make = vehicle.make ?? '';
    final model = vehicle.model ?? '';
    if (make.isEmpty && model.isEmpty) {
      return 'Vehicle';
    }
    return '$make $model'.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[700] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    image: vehicle.photoUrl != null
                        ? DecorationImage(
                            image: NetworkImage(
                              '$assetBaseUrl${vehicle.photoUrl}',
                            ),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: vehicle.photoUrl == null
                      ? Icon(
                          _getVehicleIcon(),
                          size: 32,
                          color: isDark ? Colors.grey[400] : Colors.grey[400],
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getDisplayName(),
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      if (vehicle.color != null && vehicle.color!.isNotEmpty)
                        Text(
                          vehicle.color!,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: subTextColor,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[900] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isDark
                                ? Colors.grey[700]!
                                : Colors.grey[200]!,
                          ),
                        ),
                        child: Text(
                          vehicle.plateNumber,
                          style: GoogleFonts.sourceCodePro(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.grey[300] : Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onEdit,
                  icon: Icon(
                    Icons.edit,
                    size: 20,
                    color: subTextColor,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: isDark
                        ? Colors.grey[800]
                        : Colors.grey[50],
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.grey[700]!.withValues(alpha: 0.5)
                      : Colors.grey[100]!,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.blue[900]!.withValues(alpha: 0.3)
                          : Colors.blue[50],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Default Vehicle',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: primaryColor,
                      ),
                    ),
                  )
                else
                  TextButton(
                    onPressed: onSetDefault,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: subTextColor,
                    ),
                    child: Text(
                      'Set as Default',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                TextButton(
                  onPressed: onDelete,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: Colors.red,
                  ),
                  child: Text(
                    'Remove',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
