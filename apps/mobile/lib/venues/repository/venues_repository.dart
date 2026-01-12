import 'package:mobile/api/api.dart' as api;
import 'package:mobile/common/services/geocoding_service.dart';
import 'package:mobile/venues/models/venue.dart';
import 'package:latlong2/latlong.dart';

class VenuesRepository {
  VenuesRepository({required api.ApiClient apiClient}) : _apiClient = apiClient;

  final api.ApiClient _apiClient;
  final GeocodingService _geocodingService = GeocodingService();

  Future<LatLng?> searchDestination(
    String query, {
    LatLng? userLocation,
  }) async {
    return _geocodingService.getCoordinates(query, userLocation: userLocation);
  }

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
    return apiVenues
        .map((v) => Venue.fromApi(v, baseUrl: _apiClient.assetBaseUrl))
        .toList();
  }

  Future<Venue> getVenueDetails(
    String id, {
    DateTime? startAt,
    DateTime? endAt,
  }) async {
    final apiVenue = await _apiClient.getVenue(
      id,
      startAt: startAt,
      endAt: endAt,
    );
    return Venue.fromApi(apiVenue, baseUrl: _apiClient.assetBaseUrl);
  }

  /// Get venue availability for a specific date range.
  /// Returns levels with accurate available spots count for the given time period.
  Future<List<api.Level>> getVenueAvailability(
    String venueId, {
    DateTime? startAt,
    DateTime? endAt,
  }) async {
    return _apiClient.getVenueAvailability(
      venueId,
      startAt: startAt,
      endAt: endAt,
    );
  }

  Future<api.Level> getLevelDetails(
    String id, {
    DateTime? startAt,
    DateTime? endAt,
  }) async {
    return _apiClient.getLevel(id, startAt: startAt, endAt: endAt);
  }
}
