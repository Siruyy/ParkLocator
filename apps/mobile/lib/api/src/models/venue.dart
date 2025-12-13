import 'package:equatable/equatable.dart';

class Venue extends Equatable {
  const Venue({
    required this.id,
    required this.name,
    required this.address,
    this.imageUrl,
    this.distance,
    this.availableSpots = 0,
  });

  factory Venue.fromJson(Map<String, dynamic> json) {
    return Venue(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      distance: (json['distance'] as num?)?.toDouble(),
      availableSpots: (json['availableSpots'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final String name;
  final String address;
  final String? imageUrl;
  final double? distance;
  final int availableSpots;

  @override
  List<Object?> get props => [id, name, address, imageUrl, distance, availableSpots];
}
