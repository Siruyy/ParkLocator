import 'package:equatable/equatable.dart';

enum ReservationStatus {
  pending,
  confirmed,
  checkedIn,
  completed,
  cancelled,
  expired,
  noShow,
}

class Reservation extends Equatable {
  const Reservation({
    required this.id,
    required this.status,
    required this.amount,
    required this.durationHours,
    required this.arrivalWindowMinutes,
    required this.expiresAt,
    this.checkedInAt,
    this.checkedOutAt,
    this.qrCode,
    this.createdAt,
    this.updatedAt,
    this.venue,
    this.level,
    this.spot,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: json['id'] as String,
      status: _parseStatus(json['status'] as String?),
      amount: (json['amount'] as num).toDouble(),
      durationHours: json['durationHours'] as int? ?? 1,
      arrivalWindowMinutes: json['arrivalWindowMinutes'] as int? ?? 60,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      checkedInAt: json['checkedInAt'] != null
          ? DateTime.parse(json['checkedInAt'] as String)
          : null,
      checkedOutAt: json['checkedOutAt'] != null
          ? DateTime.parse(json['checkedOutAt'] as String)
          : null,
      qrCode: json['qrCode'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      venue: json['venue'] != null
          ? ReservationVenue.fromJson(json['venue'] as Map<String, dynamic>)
          : null,
      level: json['level'] != null
          ? ReservationLevel.fromJson(json['level'] as Map<String, dynamic>)
          : null,
      spot: json['spot'] != null
          ? ReservationSpot.fromJson(json['spot'] as Map<String, dynamic>)
          : null,
    );
  }

  final String id;
  final ReservationStatus status;
  final double amount;
  final int durationHours;
  final int arrivalWindowMinutes;
  final DateTime expiresAt;
  final DateTime? checkedInAt;
  final DateTime? checkedOutAt;
  final String? qrCode;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final ReservationVenue? venue;
  final ReservationLevel? level;
  final ReservationSpot? spot;

  static ReservationStatus _parseStatus(String? status) {
    switch (status) {
      case 'pending':
        return ReservationStatus.pending;
      case 'confirmed':
        return ReservationStatus.confirmed;
      case 'checked_in':
        return ReservationStatus.checkedIn;
      case 'completed':
        return ReservationStatus.completed;
      case 'cancelled':
        return ReservationStatus.cancelled;
      case 'expired':
        return ReservationStatus.expired;
      case 'no_show':
        return ReservationStatus.noShow;
      default:
        return ReservationStatus.pending;
    }
  }

  @override
  List<Object?> get props => [
        id,
        status,
        amount,
        durationHours,
        arrivalWindowMinutes,
        expiresAt,
        checkedInAt,
        checkedOutAt,
        qrCode,
        createdAt,
        updatedAt,
        venue,
        level,
        spot,
      ];
}

class ReservationVenue extends Equatable {
  const ReservationVenue({
    required this.id,
    required this.name,
    required this.address,
    this.latitude,
    this.longitude,
    this.imageUrl,
  });

  factory ReservationVenue.fromJson(Map<String, dynamic> json) {
    double? latitude;
    double? longitude;

    if (json['location'] != null && json['location'] is Map) {
      final coords = json['location']['coordinates'] as List;
      if (coords.length >= 2) {
        longitude = (coords[0] as num).toDouble();
        latitude = (coords[1] as num).toDouble();
      }
    }

    return ReservationVenue(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String? ?? '',
      latitude: latitude,
      longitude: longitude,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  final String id;
  final String name;
  final String address;
  final double? latitude;
  final double? longitude;
  final String? imageUrl;

  @override
  List<Object?> get props => [id, name, address, latitude, longitude, imageUrl];
}

class ReservationLevel extends Equatable {
  const ReservationLevel({
    required this.id,
    required this.name,
    required this.levelNumber,
  });

  factory ReservationLevel.fromJson(Map<String, dynamic> json) {
    return ReservationLevel(
      id: json['id'] as String,
      name: json['name'] as String,
      levelNumber: json['levelNumber'] as int? ?? 0,
    );
  }

  final String id;
  final String name;
  final int levelNumber;

  @override
  List<Object?> get props => [id, name, levelNumber];
}

class ReservationSpot extends Equatable {
  const ReservationSpot({
    required this.id,
    required this.spotNumber,
  });

  factory ReservationSpot.fromJson(Map<String, dynamic> json) {
    return ReservationSpot(
      id: json['id'] as String,
      spotNumber: json['spotNumber'] as String,
    );
  }

  final String id;
  final String spotNumber;

  @override
  List<Object?> get props => [id, spotNumber];
}
