import 'package:mobile/api/api.dart' as api;

class ReservationsRepository {
  ReservationsRepository({required api.ApiClient apiClient})
      : _apiClient = apiClient;

  final api.ApiClient _apiClient;

  Future<api.Reservation> createReservation({
    required String venueId,
    required String levelId,
    required String spotId,
    int durationHours = 1,
    DateTime? startAt,
    DateTime? endAt,
  }) async {
    return _apiClient.createReservation(
      venueId: venueId,
      levelId: levelId,
      spotId: spotId,
      durationHours: durationHours,
      startAt: startAt,
      endAt: endAt,
    );
  }

  Future<List<api.Reservation>> getReservations() async {
    return _apiClient.getReservations();
  }

  Future<List<api.Reservation>> getActiveReservations() async {
    return _apiClient.getActiveReservations();
  }

  Future<api.Reservation> getReservation(String id) async {
    return _apiClient.getReservation(id);
  }

  Future<api.Reservation> cancelReservation(String id) async {
    return _apiClient.cancelReservation(id);
  }
}
