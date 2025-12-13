part of 'auth_bloc_impl.dart';

/// Status of authentication
enum AuthStatus {
  /// Initial state, checking for existing session
  unknown,
  /// User is authenticated
  authenticated,
  /// User is not authenticated
  unauthenticated,
}

/// State for the authentication bloc
final class AuthState extends Equatable {
  const AuthState._({
    this.status = AuthStatus.unknown,
    this.user,
  });

  const AuthState.unknown() : this._();

  const AuthState.authenticated(User user)
      : this._(status: AuthStatus.authenticated, user: user);

  const AuthState.unauthenticated()
      : this._(status: AuthStatus.unauthenticated);

  final AuthStatus status;
  final User? user;

  @override
  List<Object?> get props => [status, user];
}
