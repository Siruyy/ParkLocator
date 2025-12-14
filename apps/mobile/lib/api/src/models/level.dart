import 'package:equatable/equatable.dart';
import 'package:mobile/api/src/models/spot.dart';

class Level extends Equatable {
  const Level({
    required this.id,
    required this.name,
    required this.totalCapacity,
    required this.availableSpots,
    this.isActive = true,
    this.spots,
  });

  factory Level.fromJson(Map<String, dynamic> json) {
    return Level(
      id: json['id'] as String,
      name: json['name'] as String,
      totalCapacity: json['totalCapacity'] as int? ?? 0,
      availableSpots: json['availableSpots'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      spots: (json['spots'] as List<dynamic>?)
          ?.map((e) => Spot.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final String id;
  final String name;
  final int totalCapacity;
  final int availableSpots;
  final bool isActive;
  final List<Spot>? spots;

  @override
  List<Object?> get props => [id, name, totalCapacity, availableSpots, isActive, spots];
}
