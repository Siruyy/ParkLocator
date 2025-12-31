import 'package:mobile/api/api.dart' as api;

class VehiclesRepository {
  VehiclesRepository({required api.ApiClient apiClient})
      : _apiClient = apiClient;

  final api.ApiClient _apiClient;

  Future<List<api.Vehicle>> getVehicles() async {
    return _apiClient.getVehicles();
  }

  Future<api.Vehicle> createVehicle({
    required String plateNumber,
    String? make,
    String? model,
    String? color,
    bool isDefault = false,
    String type = 'car',
  }) async {
    return _apiClient.createVehicle(
      plateNumber: plateNumber,
      make: make,
      model: model,
      color: color,
      isDefault: isDefault,
      type: type,
    );
  }

  Future<api.Vehicle> uploadVehiclePhoto(String vehicleId, String filePath) async {
    return _apiClient.uploadVehiclePhoto(vehicleId, filePath);
  }

  Future<api.Vehicle> updateVehicle(
    String vehicleId, {
    String? plateNumber,
    String? make,
    String? model,
    String? color,
    bool? isDefault,
    String? type,
  }) async {
    return _apiClient.updateVehicle(
      vehicleId,
      plateNumber: plateNumber,
      make: make,
      model: model,
      color: color,
      isDefault: isDefault,
      type: type,
    );
  }

  Future<void> deleteVehicle(String vehicleId) async {
    return _apiClient.deleteVehicle(vehicleId);
  }
}

