import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/api/src/api_exception.dart';
import 'package:mobile/api/src/models/models.dart';

/// Client for communicating with the ParkLocator API
class ApiClient {
  ApiClient({
    http.Client? httpClient,
    String? baseUrl,
  }) : _httpClient = httpClient ?? http.Client(),
       // Use 10.0.2.2 for Android Emulator, localhost for iOS Simulator and Web
       _baseUrl = baseUrl ??
           (!kIsWeb && defaultTargetPlatform == TargetPlatform.android
               ? 'http://10.0.2.2:3000/api/v1'
               : 'http://localhost:3000/api/v1');

  final http.Client _httpClient;
  final String _baseUrl;
  String? _authToken;

  String get baseUrl => _baseUrl;
  String get assetBaseUrl => _baseUrl.replaceAll('/api/v1', '');

  /// Set the auth token for authenticated requests
  void setAuthToken(String? token) {
    _authToken = token;
  }

  /// Get default headers including auth token if set
  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  /// Register a new user
  Future<AuthResponse> register({
    required String email,
    required String password,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('$_baseUrl/auth/register'),
      headers: _headers,
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return AuthResponse.fromJson(json);
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw ApiException(
        message: body['message'] as String? ?? 'Registration failed',
        statusCode: response.statusCode,
      );
    }
  }

  /// Login with email and password
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: _headers,
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return AuthResponse.fromJson(json);
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw ApiException(
        message: body['message'] as String? ?? 'Login failed',
        statusCode: response.statusCode,
      );
    }
  }

  /// Create a payment intent
  Future<Map<String, dynamic>> createPaymentIntent({
    required double amount,
    required String description,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('$_baseUrl/payments/intent'),
      headers: _headers,
      body: jsonEncode({
        'amount': amount,
        'description': description,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return json;
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw ApiException(
        message: body['message'] as String? ?? 'Failed to create payment intent',
        statusCode: response.statusCode,
      );
    }
  }

  /// Get current user profile (requires auth token)
  Future<User> getProfile() async {
    final response = await _httpClient.get(
      Uri.parse('$_baseUrl/profile'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return User.fromJson(json['user'] as Map<String, dynamic>);
    } else {
      throw ApiException(
        message: 'Failed to get profile',
        statusCode: response.statusCode,
      );
    }
  }

  /// Get nearby venues
  Future<List<Venue>> getNearbyVenues({
    required double lat,
    required double lng,
    required double radius,
  }) async {
    final response = await _httpClient.get(
      Uri.parse('$_baseUrl/venues/nearby?lat=$lat&lng=$lng&radius=$radius'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final jsonList = json['data'] as List<dynamic>;
      return jsonList
          .map((json) => Venue.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw ApiException(
        message: 'Failed to fetch venues',
        statusCode: response.statusCode,
      );
    }
  }

  /// Get venue details
  Future<Venue> getVenue(
    String id, {
    DateTime? startAt,
    DateTime? endAt,
  }) async {
    var url = '$_baseUrl/venues/$id';

    // If dates provided, append them as query params for availability calculation
    if (startAt != null && endAt != null) {
      final startParam = Uri.encodeComponent(startAt.toUtc().toIso8601String());
      final endParam = Uri.encodeComponent(endAt.toUtc().toIso8601String());
      url = '$url?startAt=$startParam&endAt=$endParam';
    }

    final response = await _httpClient.get(
      Uri.parse(url),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return Venue.fromJson(json['data'] as Map<String, dynamic>);
    } else {
      throw ApiException(
        message: 'Failed to fetch venue details',
        statusCode: response.statusCode,
      );
    }
  }

  /// Get venue availability for a specific date range
  Future<List<Level>> getVenueAvailability(
    String venueId, {
    DateTime? startAt,
    DateTime? endAt,
  }) async {
    var url = '$_baseUrl/venues/$venueId/availability';

    if (startAt != null && endAt != null) {
      final startParam = Uri.encodeComponent(startAt.toUtc().toIso8601String());
      final endParam = Uri.encodeComponent(endAt.toUtc().toIso8601String());
      url = '$url?startAt=$startParam&endAt=$endParam';
    }

    final response = await _httpClient.get(
      Uri.parse(url),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final jsonList = json['data'] as List<dynamic>;
      return jsonList
          .map((json) => Level.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw ApiException(
        message: 'Failed to fetch venue availability',
        statusCode: response.statusCode,
      );
    }
  }

  /// Get level details with spots
  Future<Level> getLevel(
    String id, {
    DateTime? startAt,
    DateTime? endAt,
  }) async {
    var url = '$_baseUrl/venues/levels/$id';

    if (startAt != null && endAt != null) {
      final startParam = Uri.encodeComponent(startAt.toUtc().toIso8601String());
      final endParam = Uri.encodeComponent(endAt.toUtc().toIso8601String());
      url = '$url?startAt=$startParam&endAt=$endParam';
    }

    final response = await _httpClient.get(
      Uri.parse(url),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return Level.fromJson(json['data'] as Map<String, dynamic>);
    } else {
      throw ApiException(
        message: 'Failed to fetch level details',
        statusCode: response.statusCode,
      );
    }
  }

  /// Create a reservation
  Future<Reservation> createReservation({
    required String venueId,
    required String levelId,
    required String spotId,
    String? vehicleId,
    int durationHours = 1,
    DateTime? startAt,
    DateTime? endAt,
  }) async {
    final body = <String, dynamic>{
      'venueId': venueId,
      'levelId': levelId,
      'spotId': spotId,
      'durationHours': durationHours,
    };

    if (vehicleId != null) {
      body['vehicleId'] = vehicleId;
    }

    if (startAt != null) {
      body['startAt'] = startAt.toUtc().toIso8601String();
    }
    if (endAt != null) {
      body['endAt'] = endAt.toUtc().toIso8601String();
    }

    final response = await _httpClient.post(
      Uri.parse('$_baseUrl/reservations'),
      headers: _headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return Reservation.fromJson(json['data'] as Map<String, dynamic>);
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw ApiException(
        message: body['message'] as String? ?? 'Failed to create reservation',
        statusCode: response.statusCode,
      );
    }
  }

  /// Get all reservations for the current user
  Future<List<Reservation>> getReservations() async {
    final response = await _httpClient.get(
      Uri.parse('$_baseUrl/reservations'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final jsonList = json['data'] as List<dynamic>;
      return jsonList
          .map((json) => Reservation.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw ApiException(
        message: 'Failed to fetch reservations',
        statusCode: response.statusCode,
      );
    }
  }

  /// Get active reservations for the current user
  Future<List<Reservation>> getActiveReservations() async {
    final response = await _httpClient.get(
      Uri.parse('$_baseUrl/reservations/active'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final jsonList = json['data'] as List<dynamic>;
      return jsonList
          .map((json) => Reservation.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw ApiException(
        message: 'Failed to fetch active reservations',
        statusCode: response.statusCode,
      );
    }
  }

  /// Get a single reservation by ID
  Future<Reservation> getReservation(String id) async {
    final response = await _httpClient.get(
      Uri.parse('$_baseUrl/reservations/$id'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return Reservation.fromJson(json['data'] as Map<String, dynamic>);
    } else {
      throw ApiException(
        message: 'Failed to fetch reservation',
        statusCode: response.statusCode,
      );
    }
  }

  /// Cancel a reservation
  Future<Reservation> cancelReservation(String id) async {
    final response = await _httpClient.delete(
      Uri.parse('$_baseUrl/reservations/$id'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return Reservation.fromJson(json['data'] as Map<String, dynamic>);
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw ApiException(
        message: body['message'] as String? ?? 'Failed to cancel reservation',
        statusCode: response.statusCode,
      );
    }
  }

  /// Check in a reservation via QR code
  Future<Reservation> checkIn(String qrCode) async {
    final response = await _httpClient.post(
      Uri.parse('$_baseUrl/reservations/check-in/$qrCode'),
      headers: _headers,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return Reservation.fromJson(json['data'] as Map<String, dynamic>);
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw ApiException(
        message: body['message'] as String? ?? 'Failed to check in',
        statusCode: response.statusCode,
      );
    }
  }
  /// Get notifications
  Future<List<Notification>> getNotifications() async {
    final response = await _httpClient.get(
      Uri.parse('$_baseUrl/notifications'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as List;
      return json
          .map((e) => Notification.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw ApiException(
        message: 'Failed to fetch notifications',
        statusCode: response.statusCode,
      );
    }
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String id) async {
    final response = await _httpClient.patch(
      Uri.parse('$_baseUrl/notifications/$id/read'),
      headers: _headers,
    );

    _checkResponse(
      response,
      errorMessage: 'Failed to mark notification as read',
    );
  }

  /// Mark all notifications as read
  Future<void> markAllNotificationsAsRead() async {
    final response = await _httpClient.post(
      Uri.parse('$_baseUrl/notifications/read-all'),
      headers: _headers,
    );

    _checkResponse(
      response,
      errorMessage: 'Failed to mark all notifications as read',
      allowedStatusCodes: [200, 201],
    );
  }

  void _checkResponse(
    http.Response response, {
    required String errorMessage,
    List<int> allowedStatusCodes = const [200],
  }) {
    if (!allowedStatusCodes.contains(response.statusCode)) {
      throw ApiException(
        message: errorMessage,
        statusCode: response.statusCode,
      );
    }
  }

  /// Get user vehicles
  Future<List<Vehicle>> getVehicles() async {
    final response = await _httpClient.get(
      Uri.parse('$_baseUrl/users/me/vehicles'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List;
      return list
          .map((e) => Vehicle.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw ApiException(
        message: 'Failed to fetch vehicles',
        statusCode: response.statusCode,
      );
    }
  }

  /// Create a vehicle
  Future<Vehicle> createVehicle({
    required String plateNumber,
    String? make,
    String? model,
    String? color,
    bool isDefault = false,
    String type = 'car',
  }) async {
    final body = <String, dynamic>{
      'plateNumber': plateNumber,
      'make': make,
      'model': model,
      'color': color,
      'isDefault': isDefault,
      'type': type,
    };

    final response = await _httpClient.post(
      Uri.parse('$_baseUrl/users/me/vehicles'),
      headers: _headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 201) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return Vehicle.fromJson(json);
    } else {
      String message = 'Failed to create vehicle';
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body.containsKey('message')) {
          message = body['message'] as String;
        }
      } catch (_) {}

      throw ApiException(
        message: message,
        statusCode: response.statusCode,
      );
    }
  }

  /// Upload vehicle photo
  Future<Vehicle> uploadVehiclePhoto(String vehicleId, String filePath) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/users/me/vehicles/$vehicleId/photo'),
    );

    if (_authToken != null) {
      request.headers['Authorization'] = 'Bearer $_authToken';
    }

    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    final streamedResponse = await _httpClient.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return Vehicle.fromJson(json);
    } else {
      throw ApiException(
        message: 'Failed to upload vehicle photo',
        statusCode: response.statusCode,
      );
    }
  }

  /// Update a vehicle
  Future<Vehicle> updateVehicle(
    String vehicleId, {
    String? plateNumber,
    String? make,
    String? model,
    String? color,
    bool? isDefault,
    String? type,
  }) async {
    final body = <String, dynamic>{};
    if (plateNumber != null) body['plateNumber'] = plateNumber;
    if (make != null) body['make'] = make;
    if (model != null) body['model'] = model;
    if (color != null) body['color'] = color;
    if (isDefault != null) body['isDefault'] = isDefault;
    if (type != null) body['type'] = type;

    final response = await _httpClient.patch(
      Uri.parse('$_baseUrl/users/me/vehicles/$vehicleId'),
      headers: _headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return Vehicle.fromJson(json);
    } else {
      String message = 'Failed to update vehicle';
      try {
        final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
        if (responseBody.containsKey('message')) {
          message = responseBody['message'] as String;
        }
      } catch (_) {}

      throw ApiException(
        message: message,
        statusCode: response.statusCode,
      );
    }
  }

  /// Delete a vehicle
  Future<void> deleteVehicle(String vehicleId) async {
    final response = await _httpClient.delete(
      Uri.parse('$_baseUrl/users/me/vehicles/$vehicleId'),
      headers: _headers,
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      String message = 'Failed to delete vehicle';
      try {
        final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
        if (responseBody.containsKey('message')) {
          message = responseBody['message'] as String;
        }
      } catch (_) {}

      throw ApiException(
        message: message,
        statusCode: response.statusCode,
      );
    }
  }
}
