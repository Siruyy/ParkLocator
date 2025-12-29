import 'package:equatable/equatable.dart';

class VenueConfiguration extends Equatable {
  const VenueConfiguration({
    required this.reservationFee,
    required this.baseRate,
    required this.baseDuration,
    required this.succeedingHourRate,
    required this.overnightFlatRate,
    required this.weekendSurcharge,
    required this.isWeekendSurchargeActive,
    required this.motorcycleFlatRate,
    required this.isMotorcycleFlatRateActive,
    required this.entryGracePeriod,
    required this.maxReservationHold,
  });

  factory VenueConfiguration.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value, double defaultValue) {
      if (value == null) return defaultValue;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    int parseInt(dynamic value, int defaultValue) {
      if (value == null) return defaultValue;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    return VenueConfiguration(
      reservationFee: parseDouble(json['reservationFee'], 50),
      baseRate: parseDouble(json['baseRate'], 0),
      baseDuration: parseInt(json['baseDuration'], 1),
      succeedingHourRate: parseDouble(json['succeedingHourRate'], 20),
      overnightFlatRate: parseDouble(json['overnightFlatRate'], 300),
      weekendSurcharge: parseDouble(json['weekendSurcharge'], 0),
      isWeekendSurchargeActive:
          json['isWeekendSurchargeActive'] as bool? ?? false,
      motorcycleFlatRate: parseDouble(json['motorcycleFlatRate'], 30),
      isMotorcycleFlatRateActive:
          json['isMotorcycleFlatRateActive'] as bool? ?? false,
      entryGracePeriod: parseInt(json['entryGracePeriod'], 15),
      maxReservationHold: parseInt(json['maxReservationHold'], 30),
    );
  }

  final double reservationFee;
  final double baseRate;
  final int baseDuration;
  final double succeedingHourRate;
  final double overnightFlatRate;
  final double weekendSurcharge;
  final bool isWeekendSurchargeActive;
  final double motorcycleFlatRate;
  final bool isMotorcycleFlatRateActive;
  final int entryGracePeriod;
  final int maxReservationHold;

  @override
  List<Object?> get props => [
    reservationFee,
    baseRate,
    baseDuration,
    succeedingHourRate,
    overnightFlatRate,
    weekendSurcharge,
    isWeekendSurchargeActive,
    motorcycleFlatRate,
    isMotorcycleFlatRateActive,
    entryGracePeriod,
    maxReservationHold,
  ];
}
