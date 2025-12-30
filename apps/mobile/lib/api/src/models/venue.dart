import 'package:equatable/equatable.dart';
import 'package:mobile/api/src/models/level.dart';
import 'package:mobile/api/src/models/venue_configuration.dart';

class Venue extends Equatable {
  const Venue({
    required this.id,
    required this.name,
    required this.address,
    this.imageUrl,
    this.distance,
    this.availableSpots = 0,
    this.levels,
    this.latitude,
    this.longitude,
    this.configuration,
    this.supportsRealTimeBooking = true,
    this.supportsFutureBooking = false,
    this.requireVehicleDetails = true,
    this.hasCoveredParking = false,
    this.hasCCTV = false,
  });

  final bool supportsRealTimeBooking;
  final bool supportsFutureBooking;
  final bool requireVehicleDetails;
  final bool hasCoveredParking;
  final bool hasCCTV;

  factory Venue.fromJson(Map<String, dynamic> json) {
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }

    final levels = (json['levels'] as List<dynamic>?)
        ?.map((e) => Level.fromJson(e as Map<String, dynamic>))
        .toList();

    final configuration = json['configuration'] != null
        ? VenueConfiguration.fromJson(
            json['configuration'] as Map<String, dynamic>)
        : null;

    var availableSpots = parseInt(json['availableSpots']);

    // If availableSpots is missing (detail view) and we have levels, calculate it
    if (availableSpots == null && levels != null) {
      availableSpots =
          levels.fold<int>(0, (sum, level) => sum + level.availableSpots);
    }

    double? latitude;
    double? longitude;

    if (json['location'] != null) {
      if (json['location'] is Map) {
        final coords = json['location']['coordinates'] as List;
        if (coords.length >= 2) {
          longitude = parseDouble(coords[0]);
          latitude = parseDouble(coords[1]);
        }
      } else if (json['location'] is String) {
        final location = json['location'] as String;
        if (location.startsWith('POINT')) {
          final match =
              RegExp(r'POINT\(([^ ]+) ([^)]+)\)').firstMatch(location);
          if (match != null) {
            longitude = parseDouble(match.group(1));
            latitude = parseDouble(match.group(2));
          }
        }
      }
    }

    if (latitude == null) {
      latitude = parseDouble(json['latitude']);
    }
    if (longitude == null) {
      longitude = parseDouble(json['longitude']);
    }

    return Venue(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      distance: parseDouble(json['distance']),
      availableSpots: availableSpots ?? 0,
      levels: levels,
      latitude: latitude,
      longitude: longitude,
      configuration: configuration,
      supportsRealTimeBooking: json['supportsRealTimeBooking'] as bool? ?? true,
      supportsFutureBooking: json['supportsFutureBooking'] as bool? ?? false,
      requireVehicleDetails: json['requireVehicleDetails'] as bool? ?? true,
      hasCoveredParking: json['hasCoveredParking'] as bool? ?? false,
      hasCCTV: json['hasCCTV'] as bool? ?? false,
    );
  }

  final String id;
  final String name;
  final String address;
  final String? imageUrl;
  final double? distance;
  final int availableSpots;
  final List<Level>? levels;
  final double? latitude;
  final double? longitude;
  final VenueConfiguration? configuration;

  @override
  List<Object?> get props => [
        id,
        name,
        address,
        imageUrl,
        distance,
        availableSpots,
        levels,
        latitude,
        longitude,
        configuration,
      ];
}
