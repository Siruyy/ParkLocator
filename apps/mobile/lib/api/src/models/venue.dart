import 'package:equatable/equatable.dart';
import 'package:mobile/api/src/models/level.dart';

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
  });

  factory Venue.fromJson(Map<String, dynamic> json) {
    final levels = (json['levels'] as List<dynamic>?)
        ?.map((e) => Level.fromJson(e as Map<String, dynamic>))
        .toList();

    int? availableSpots = (json['availableSpots'] as num?)?.toInt();

    // If availableSpots is missing (detail view) and we have levels, calculate it
    if (availableSpots == null && levels != null) {
      availableSpots =
          levels.fold<int>(0, (sum, level) => sum + level.availableSpots);
    }

    double? latitude;
    double? longitude;

    if (json['location'] != null && json['location'] is Map) {
      final coords = json['location']['coordinates'] as List;
      if (coords.length >= 2) {
        longitude = (coords[0] as num).toDouble();
        latitude = (coords[1] as num).toDouble();
      }
    }

    return Venue(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      distance: (json['distance'] as num?)?.toDouble(),
      availableSpots: availableSpots ?? 0,
      levels: levels,
      latitude: latitude,
      longitude: longitude,
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
      ];
}
