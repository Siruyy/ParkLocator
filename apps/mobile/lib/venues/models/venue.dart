import 'package:mobile/api/api.dart' as api;

enum VenueStatus {
  available,
  fillingFast,
  full,
}

class Venue {
  const Venue({
    required this.apiVenue,
    this.pricePerHour = 50.0, // Default reservation fee
    this.availableSpots = 0,
    this.levels,
  });

  // Factory to create from API model with mocked data
  factory Venue.fromApi(api.Venue apiVenue, {String? baseUrl}) {
    // Fix image URL if it's relative
    var venue = apiVenue;
    if (baseUrl != null &&
        apiVenue.imageUrl != null &&
        apiVenue.imageUrl!.startsWith('/')) {
      venue = api.Venue(
        id: apiVenue.id,
        name: apiVenue.name,
        address: apiVenue.address,
        imageUrl: '$baseUrl${apiVenue.imageUrl}',
        distance: apiVenue.distance,
        availableSpots: apiVenue.availableSpots,
        levels: apiVenue.levels,
        latitude: apiVenue.latitude,
        longitude: apiVenue.longitude,
      );
    }

    double price = 50.0; // Default reservation fee
    if (apiVenue.configuration != null) {
      price = apiVenue.configuration!.reservationFee;
    }

    return Venue(
      apiVenue: venue,
      pricePerHour: price,
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
  double? get latitude => apiVenue.latitude;
  double? get longitude => apiVenue.longitude;

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
