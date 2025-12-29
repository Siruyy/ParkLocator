import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/api/src/models/venue.dart';

void main() {
  group('Venue', () {
    test('fromJson parses GeoJSON map correctly', () {
      final json = {
        'id': '1',
        'name': 'Test Venue',
        'address': '123 Test St',
        'location': {
          'type': 'Point',
          'coordinates': [-122.4194, 37.7749]
        },
        'distance': 1.5,
        'availableSpots': 10,
      };

      final venue = Venue.fromJson(json);
      expect(venue.latitude, 37.7749);
      expect(venue.longitude, -122.4194);
    });

    test('fromJson parses WKT string correctly', () {
      final json = {
        'id': '1',
        'name': 'Test Venue',
        'address': '123 Test St',
        'location': 'POINT(-122.4194 37.7749)',
        'distance': 1.5,
        'availableSpots': 10,
      };

      final venue = Venue.fromJson(json);
      expect(venue.latitude, 37.7749);
      expect(venue.longitude, -122.4194);
    });

    test('fromJson parses direct lat/lng correctly', () {
      final json = {
        'id': '1',
        'name': 'Test Venue',
        'address': '123 Test St',
        'latitude': 37.7749,
        'longitude': -122.4194,
        'distance': 1.5,
        'availableSpots': 10,
      };

      final venue = Venue.fromJson(json);
      expect(venue.latitude, 37.7749);
      expect(venue.longitude, -122.4194);
    });

    test('fromJson handles null location', () {
      final json = {
        'id': '1',
        'name': 'Test Venue',
        'address': '123 Test St',
        'distance': 1.5,
        'availableSpots': 10,
      };

      final venue = Venue.fromJson(json);
      expect(venue.latitude, null);
      expect(venue.longitude, null);
    });
  });
}
