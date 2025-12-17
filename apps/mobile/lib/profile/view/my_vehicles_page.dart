import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/profile/view/add_vehicle_page.dart';
import 'package:mobile/profile/view/edit_vehicle_page.dart';

class MyVehiclesPage extends StatelessWidget {
  const MyVehiclesPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const MyVehiclesPage());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF101922) : const Color(0xFFF6F7F8);
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    const primaryColor = Color(0xFF137FEC);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor.withOpacity(0.9),
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Add New Vehicle Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(AddVehiclePage.route());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shadowColor: primaryColor.withOpacity(0.4),
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
                        'Add New Vehicle',
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
                  'REGISTERED VEHICLES',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: subTextColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              // Vehicle List
              _VehicleCard(
                name: 'Toyota Vios',
                color: 'Silver Metallic',
                plateNumber: 'GAB 1234',
                icon: Icons.directions_car,
                isDefault: true,
                isDark: isDark,
                surfaceColor: surfaceColor,
                textColor: textColor,
                subTextColor: subTextColor,
                primaryColor: primaryColor,
              ),
              const SizedBox(height: 16),
              _VehicleCard(
                name: 'Mitsubishi Mirage',
                color: 'Red',
                plateNumber: 'CEC 5678',
                icon: Icons.directions_car,
                isDefault: false,
                isDark: isDark,
                surfaceColor: surfaceColor,
                textColor: textColor,
                subTextColor: subTextColor,
                primaryColor: primaryColor,
              ),
              const SizedBox(height: 16),
              _VehicleCard(
                name: 'Honda Click',
                color: 'Matte Black',
                plateNumber: '987 HYG',
                icon: Icons.two_wheeler,
                isDefault: false,
                isDark: isDark,
                surfaceColor: surfaceColor,
                textColor: textColor,
                subTextColor: subTextColor,
                primaryColor: primaryColor,
              ),

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
    required this.name,
    required this.color,
    required this.plateNumber,
    required this.icon,
    required this.isDefault,
    required this.isDark,
    required this.surfaceColor,
    required this.textColor,
    required this.subTextColor,
    required this.primaryColor,
  });

  final String name;
  final String color;
  final String plateNumber;
  final IconData icon;
  final bool isDefault;
  final bool isDark;
  final Color surfaceColor;
  final Color textColor;
  final Color subTextColor;
  final Color primaryColor;

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
            color: Colors.black.withOpacity(0.02),
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
                  ),
                  child: Icon(
                    icon,
                    size: 32,
                    color: isDark ? Colors.grey[400] : Colors.grey[400],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      Text(
                        color,
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
                            color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                          ),
                        ),
                        child: Text(
                          plateNumber,
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
                  onPressed: () {
                    Navigator.of(context).push(
                      EditVehiclePage.route(
                        make: name.split(' ').first, // Simple heuristic for now
                        model: name.split(' ').skip(1).join(' '),
                        plateNumber: plateNumber,
                        color: color,
                        isDefault: isDefault,
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.edit,
                    size: 20,
                    color: subTextColor,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: isDark ? Colors.grey[800] : Colors.grey[50],
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
                  color: isDark ? Colors.grey[700]!.withOpacity(0.5) : Colors.grey[100]!,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.blue[900]!.withOpacity(0.3) : Colors.blue[50],
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
                    onPressed: () {},
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
                  onPressed: () {},
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
