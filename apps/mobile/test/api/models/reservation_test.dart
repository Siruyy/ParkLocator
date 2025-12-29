import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/api/src/models/reservation.dart';

void main() {
  group('ReservationVenue', () {
    test('fromJson parses GeoJSON map correctly', () {
      final json = {
        'id': '1',
        'name': 'Test Venue',
        'address': '123 Test St',
        'location': {
          'type': 'Point',
          'coordinates': [-122.4194, 37.7749]
        }
      };

      final venue = ReservationVenue.fromJson(json);
      expect(venue.latitude, 37.7749);
      expect(venue.longitude, -122.4194);
    });

    test('fromJson parses WKT string correctly', () {
      final json = {
        'id': '1',
        'name': 'Test Venue',
        'address': '123 Test St',
        'location': 'POINT(-122.4194 37.7749)'
      };

      final venue = ReservationVenue.fromJson(json);
      expect(venue.latitude, 37.7749);
      expect(venue.longitude, -122.4194);
    });

    test('fromJson parses direct lat/lng correctly', () {
      final json = {
        'id': '1',
        'name': 'Test Venue',
        'address': '123 Test St',
        'latitude': 37.7749,
        'longitude': -122.4194
      };

      final venue = ReservationVenue.fromJson(json);
      expect(venue.latitude, 37.7749);
      expect(venue.longitude, -122.4194);
    });
    
    test('fromJson handles null location', () {
      final json = {
        'id': '1',
        'name': 'Test Venue',
        'address': '123 Test St',
      };

      final venue = ReservationVenue.fromJson(json);
      expect(venue.latitude, null);
      expect(venue.longitude, null);
    });
  });
}
