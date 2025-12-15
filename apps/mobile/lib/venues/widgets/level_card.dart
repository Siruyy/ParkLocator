import 'package:flutter/material.dart';
import 'package:mobile/api/api.dart' as api;

class LevelCard extends StatelessWidget {
  const LevelCard({
    required this.level,
    this.overrideAvailableSpots,
    super.key,
  });

  final api.Level level;
  /// Optional override for available spots count (used for date-specific availability)
  final int? overrideAvailableSpots;

  @override
  Widget build(BuildContext context) {
    // Use override if provided, otherwise use level's default
    final availableSpots = overrideAvailableSpots ?? level.availableSpots;
    
    final occupancy = level.totalCapacity > 0
        ? (level.totalCapacity - availableSpots) / level.totalCapacity
        : 1.0;
    
    final isFull = availableSpots == 0;
    final isFillingFast = !isFull && availableSpots < 10;
    
    Color statusColor;
    String statusText;
    Color iconBgColor;
    IconData iconData;

    if (isFull) {
      statusColor = Colors.grey;
      statusText = 'Full';
      iconBgColor = Colors.grey[200]!;
      iconData = Icons.looks_3; // Mock icon logic
    } else if (isFillingFast) {
      statusColor = Colors.orange;
      statusText = 'Filling Fast';
      iconBgColor = Colors.orange[50]!;
      iconData = Icons.looks_two;
    } else {
      statusColor = const Color(0xFF137FEC); // Primary
      statusText = 'Good Availability';
      iconBgColor = const Color(0xFFE3F2FD); // Blue 50
      iconData = Icons.looks_one;
    }

    // Mock logic for icon based on name
    if (level.name.toLowerCase().contains('basement')) {
      iconData = Icons.elevator;
    } else if (level.name.contains('1')) {
      iconData = Icons.looks_one;
    } else if (level.name.contains('2')) {
      iconData = Icons.looks_two;
    } else if (level.name.contains('3')) {
      iconData = Icons.looks_3;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isFull ? Colors.grey[50] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: isFull
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      iconData,
                      color: isFull ? Colors.grey : statusColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        level.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isFull ? Colors.grey[600] : Colors.black87,
                        ),
                      ),
                      Text(
                        'Covered', // Mock description
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    availableSpots.toString(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  Text(
                    isFull ? 'SPOTS' : 'AVAILABLE',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: occupancy,
                    backgroundColor: Colors.grey[100],
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
