import 'package:equatable/equatable.dart';

enum SpotStatus {
  available,
  occupied,
  reserved,
  maintenance,
}

class Spot extends Equatable {
  const Spot({
    required this.id,
    required this.spotNumber,
    required this.status,
    this.isActive = true,
    this.section,
    this.vehicleType = 'Car',
  });

  factory Spot.fromJson(Map<String, dynamic> json) {
    return Spot(
      id: json['id'] as String,
      spotNumber: json['spotNumber'] as String,
      status: _parseStatus(json['status'] as String?),
      isActive: json['isActive'] as bool? ?? true,
      section: json['section'] as String?,
      vehicleType: json['vehicleType'] as String? ?? 'Car',
    );
  }

  final String id;
  final String spotNumber;
  final SpotStatus status;
  final bool isActive;
  final String? section;
  final String vehicleType;

  static SpotStatus _parseStatus(String? status) {
    switch (status) {
      case 'available':
        return SpotStatus.available;
      case 'occupied':
        return SpotStatus.occupied;
      case 'reserved':
        return SpotStatus.reserved;
      case 'maintenance':
        return SpotStatus.maintenance;
      default:
        return SpotStatus.available;
    }
  }

  @override
  List<Object?> get props => [id, spotNumber, status, isActive, section, vehicleType];
}
