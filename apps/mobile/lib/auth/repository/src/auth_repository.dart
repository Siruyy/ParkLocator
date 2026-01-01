import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile/api/api.dart';

/// Repository for handling authentication operations
class AuthRepository {
  AuthRepository({
    ApiClient? apiClient,
    FlutterSecureStorage? secureStorage,
  }) : _apiClient = apiClient ?? ApiClient(),
       _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final ApiClient _apiClient;
  final FlutterSecureStorage _secureStorage;

  static const _tokenKey = 'auth_token';
  static const _userKey = 'user_data';

  final _authStateController = StreamController<User?>.broadcast();

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges => _authStateController.stream;

  /// Get current user if authenticated
  User? _currentUser;
  User? get currentUser => _currentUser;

  /// Check if there's a stored token and restore session
  Future<User?> tryRestoreSession() async {
    try {
      final token = await _secureStorage.read(key: _tokenKey);
      if (token == null) return null;

      _apiClient.authToken = token;
      final user = await _apiClient.getProfile();
      _currentUser = user;
      _authStateController.add(user);
      return user;
    } catch (_) {
      await _clearStorage();
      return null;
    }
  }

  /// Register a new user
  Future<User> register({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.register(
      email: email,
      password: password,
    );

    await _saveAuthData(response);
    return response.user;
  }

  /// Login with email and password
  Future<User> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.login(
      email: email,
      password: password,
    );

    await _saveAuthData(response);
    return response.user;
  }

  /// Logout the current user
  Future<void> logout() async {
    await _clearStorage();
    _currentUser = null;
    _authStateController.add(null);
  }

  Future<void> _saveAuthData(AuthResponse response) async {
    await _secureStorage.write(key: _tokenKey, value: response.accessToken);
    _apiClient.authToken = response.accessToken;
    _currentUser = response.user;
    _authStateController.add(response.user);
  }

  Future<void> _clearStorage() async {
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _userKey);
    _apiClient.authToken = null;
  }

  /// Dispose resources
  void dispose() {
    _authStateController.close();
  }
}
