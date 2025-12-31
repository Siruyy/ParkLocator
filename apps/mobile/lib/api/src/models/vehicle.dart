import 'package:equatable/equatable.dart';

class Vehicle extends Equatable {
  const Vehicle({
    required this.id,
    required this.plateNumber,
    this.make,
    this.model,
    this.color,
    this.isDefault = false,
    this.type = 'car',
    this.photoUrl,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] as String,
      plateNumber: json['plateNumber'] as String,
      make: json['make'] as String?,
      model: json['model'] as String?,
      color: json['color'] as String?,
      isDefault: json['isDefault'] as bool? ?? false,
      type: json['type'] as String? ?? 'car',
      photoUrl: json['photoUrl'] as String?,
    );
  }

  final String id;
  final String plateNumber;
  final String? make;
  final String? model;
  final String? color;
  final bool isDefault;
  final String type;
  final String? photoUrl;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plateNumber': plateNumber,
      'make': make,
      'model': model,
      'color': color,
      'isDefault': isDefault,
      'type': type,
      'photoUrl': photoUrl,
    };
  }

  @override
  List<Object?> get props => [
    id,
    plateNumber,
    make,
    model,
    color,
    isDefault,
    type,
    photoUrl,
  ];
}
