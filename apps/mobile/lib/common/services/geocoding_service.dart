import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class GeocodingService {
  // Using OpenStreetMap Nominatim for better POI coverage in Philippines
  static const String _baseUrl = 'https://nominatim.openstreetmap.org/search';

  Future<LatLng?> getCoordinates(String query, {LatLng? userLocation}) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);

      // Nominatim API with Philippines country code for better results
      String url =
          '$_baseUrl?q=$encodedQuery&format=json&limit=1&countrycodes=ph';

      // Add viewbox bias if user location is known (roughly 50km box around user)
      if (userLocation != null) {
        final minLon = userLocation.longitude - 0.5;
        final maxLon = userLocation.longitude + 0.5;
        final minLat = userLocation.latitude - 0.5;
        final maxLat = userLocation.latitude + 0.5;
        url += '&viewbox=$minLon,$maxLat,$maxLon,$minLat&bounded=0';
      }

      print('Geocoding URL: $url');
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'ParkLocator/1.0', // Required by Nominatim
        },
      );
      print('Geocoding status: ${response.statusCode}');
      print('Geocoding body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;

        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat'] as String);
          final lon = double.parse(data[0]['lon'] as String);
          final displayName = data[0]['display_name'];
          print('Found place: $displayName at $lat, $lon');
          return LatLng(lat, lon);
        } else {
          print('No results found in response');
        }
      }
      return null;
    } catch (e) {
      print('Geocoding error: $e');
      return null;
    }
  }
}
