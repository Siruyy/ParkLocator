import 'package:mobile/api/api.dart' as api;
import 'package:mobile/venues/models/venue.dart';

class VenuesRepository {
  VenuesRepository({required api.ApiClient apiClient}) : _apiClient = apiClient;

  final api.ApiClient _apiClient;

  Future<List<Venue>> getNearbyVenues({
    required double lat,
    required double lng,
    required double radius,
  }) async {
    final apiVenues = await _apiClient.getNearbyVenues(
      lat: lat,
      lng: lng,
      radius: radius,
    );
    return apiVenues.map((v) => Venue.fromApi(v)).toList();
  }
}
