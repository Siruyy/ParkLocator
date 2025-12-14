import 'package:mobile/api/api.dart' as api;

enum VenueStatus {
  available,
  fillingFast,
  full,
}

class Venue {
  const Venue({
    required this.apiVenue,
    this.pricePerHour = 30.0,
    this.availableSpots = 0,
    this.levels,
  });

  // Factory to create from API model with mocked data
  factory Venue.fromApi(api.Venue apiVenue) {
    return Venue(
      apiVenue: apiVenue,
      pricePerHour: 30.0 + (apiVenue.name.length % 3) * 10, // Still mocking price for now
      availableSpots: apiVenue.availableSpots,
      levels: apiVenue.levels,
    );
  }

  final api.Venue apiVenue;
  final double pricePerHour;
  final int availableSpots;
  final List<api.Level>? levels;

  String get id => apiVenue.id;
  String get name => apiVenue.name;
  String get address => apiVenue.address;
  String? get imageUrl => apiVenue.imageUrl;
  double? get distance => apiVenue.distance;

  VenueStatus get status {
    if (availableSpots == 0) return VenueStatus.full;
    if (availableSpots < 10) return VenueStatus.fillingFast;
    return VenueStatus.available;
  }
  
  String get distanceFormatted {
    if (distance == null) return '';
    if (distance! < 1000) {
      return '${distance!.toStringAsFixed(0)} m';
    }
    return '${(distance! / 1000).toStringAsFixed(1)} km';
  }
}
