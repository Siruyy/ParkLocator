import 'package:equatable/equatable.dart';
import 'package:mobile/api/src/models/user.dart';

/// Response from authentication endpoints (login/register)
class AuthResponse extends Equatable {
  const AuthResponse({
    required this.accessToken,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  final String accessToken;
  final User user;

  @override
  List<Object?> get props => [accessToken, user];
}
