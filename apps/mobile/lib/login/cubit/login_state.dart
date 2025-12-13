part of 'login_cubit.dart';

/// Status of the login form
enum LoginStatus {
  initial,
  loading,
  success,
  failure,
}

/// State for the login form
final class LoginState extends Equatable {
  const LoginState({
    this.status = LoginStatus.initial,
    this.email = '',
    this.password = '',
    this.isPasswordVisible = false,
    this.errorMessage,
  });

  final LoginStatus status;
  final String email;
  final String password;
  final bool isPasswordVisible;
  final String? errorMessage;

  LoginState copyWith({
    LoginStatus? status,
    String? email,
    String? password,
    bool? isPasswordVisible,
    String? errorMessage,
  }) {
    return LoginState(
      status: status ?? this.status,
      email: email ?? this.email,
      password: password ?? this.password,
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        email,
        password,
        isPasswordVisible,
        errorMessage,
      ];
}
