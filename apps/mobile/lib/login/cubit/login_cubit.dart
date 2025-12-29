import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mobile/api/api.dart';
import 'package:mobile/auth/repository/src/auth_repository.dart';

part 'login_state.dart';

/// Cubit for handling login form state
class LoginCubit extends Cubit<LoginState> {
  LoginCubit({
    required AuthRepository authRepository,
  })  : _authRepository = authRepository,
        super(const LoginState());

  final AuthRepository _authRepository;

  /// Update email field
  void emailChanged(String value) {
    emit(state.copyWith(email: value));
  }

  /// Update password field
  void passwordChanged(String value) {
    emit(state.copyWith(password: value));
  }

  /// Toggle password visibility
  void togglePasswordVisibility() {
    emit(state.copyWith(isPasswordVisible: !state.isPasswordVisible));
  }

  /// Submit login form
  Future<void> login() async {
    print('[LOGIN] Starting login with email: ${state.email}');
    if (state.email.isEmpty || state.password.isEmpty) {
      emit(state.copyWith(errorMessage: 'Please fill in all fields'));
      return;
    }

    emit(state.copyWith(status: LoginStatus.loading));
    print('[LOGIN] Status set to loading');

    try {
      print('[LOGIN] Calling authRepository.login...');
      await _authRepository.login(
        email: state.email,
        password: state.password,
      );
      print('[LOGIN] Login successful!');
      emit(state.copyWith(status: LoginStatus.success));
    } on ApiException catch (e) {
      print('[LOGIN] ApiException: ${e.message}');
      emit(state.copyWith(
        status: LoginStatus.failure,
        errorMessage: e.message,
      ));
    } catch (e) {
      print('[LOGIN] Unexpected error: $e');
      emit(state.copyWith(
        status: LoginStatus.failure,
        errorMessage: 'An unexpected error occurred: $e',
      ));
    }
  }
}
