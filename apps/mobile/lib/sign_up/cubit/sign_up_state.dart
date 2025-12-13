part of 'sign_up_cubit.dart';

/// Status of the sign up form
enum SignUpStatus {
  initial,
  loading,
  success,
  failure,
}

/// State for the sign up form
final class SignUpState extends Equatable {
  const SignUpState({
    this.status = SignUpStatus.initial,
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.isPasswordVisible = false,
    this.errorMessage,
  });

  final SignUpStatus status;
  final String email;
  final String password;
  final String confirmPassword;
  final bool isPasswordVisible;
  final String? errorMessage;

  SignUpState copyWith({
    SignUpStatus? status,
    String? email,
    String? password,
    String? confirmPassword,
    bool? isPasswordVisible,
    String? errorMessage,
  }) {
    return SignUpState(
      status: status ?? this.status,
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        email,
        password,
        confirmPassword,
        isPasswordVisible,
        errorMessage,
      ];
}
