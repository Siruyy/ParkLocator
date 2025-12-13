import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile/api/src/api_exception.dart';
import 'package:mobile/api/src/models/models.dart';

/// Client for communicating with the ParkLocator API
class ApiClient {
  ApiClient({
    http.Client? httpClient,
    String? baseUrl,
  })  : _httpClient = httpClient ?? http.Client(),
        _baseUrl = baseUrl ?? 'http://10.0.2.2:3000'; // Android emulator localhost

  final http.Client _httpClient;
  final String _baseUrl;
  String? _authToken;

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
}
