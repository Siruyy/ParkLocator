import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mobile/api/api.dart';
import 'package:mobile/auth/repository/src/auth_repository.dart';

part 'sign_up_state.dart';

/// Cubit for handling sign up form state
class SignUpCubit extends Cubit<SignUpState> {
  SignUpCubit({
    required AuthRepository authRepository,
  }) : _authRepository = authRepository,
       super(const SignUpState());

  final AuthRepository _authRepository;

  /// Update email field
  void emailChanged(String value) {
    emit(state.copyWith(email: value));
  }

  /// Update password field
  void passwordChanged(String value) {
    emit(state.copyWith(password: value));
  }

  /// Update confirm password field
  void confirmPasswordChanged(String value) {
    emit(state.copyWith(confirmPassword: value));
  }

  /// Toggle password visibility
  void togglePasswordVisibility() {
    emit(state.copyWith(isPasswordVisible: !state.isPasswordVisible));
  }

  /// Submit sign up form
  Future<void> signUp() async {
    if (state.email.isEmpty ||
        state.password.isEmpty ||
        state.confirmPassword.isEmpty) {
      emit(state.copyWith(errorMessage: 'Please fill in all fields'));
      return;
    }

    if (!_isValidEmail(state.email)) {
      emit(state.copyWith(errorMessage: 'Please enter a valid email'));
      return;
    }

    if (state.password.length < 6) {
      emit(
        state.copyWith(
          errorMessage: 'Password must be at least 6 characters',
        ),
      );
      return;
    }

    if (state.password != state.confirmPassword) {
      emit(state.copyWith(errorMessage: 'Passwords do not match'));
      return;
    }

    emit(state.copyWith(status: SignUpStatus.loading));

    try {
      await _authRepository.register(
        email: state.email,
        password: state.password,
      );
      emit(state.copyWith(status: SignUpStatus.success));
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: SignUpStatus.failure,
          errorMessage: e.message,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: SignUpStatus.failure,
          errorMessage: 'An unexpected error occurred',
        ),
      );
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}
