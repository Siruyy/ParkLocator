part of 'auth_bloc_impl.dart';

/// Events for the authentication bloc
sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Event to check if there's an existing session
final class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// Event when authentication state changes
final class AuthStateChanged extends AuthEvent {
  const AuthStateChanged(this.user);

  final User? user;

  @override
  List<Object?> get props => [user];
}

/// Event to logout the user
final class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}
