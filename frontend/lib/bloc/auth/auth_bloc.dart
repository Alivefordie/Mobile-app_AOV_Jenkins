import 'package:flutter_application_1/bloc/auth/auth_event.dart';
import 'package:flutter_application_1/bloc/auth/auth_state.dart';
import 'package:flutter_application_1/repositories/auth_repository.dart';
import 'package:flutter_application_1/repositories/token_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// เขียน token + userId ลงเครื่องให้เรียบร้อยก่อน emit AuthAuthenticated
// หน้า login/register ถึงสั่งให้ตะกร้ากับหัวใจโหลดใหม่ได้ทันทีโดยอ่านเจอของคนใหม่
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._repository, {TokenStorage? tokenStorage})
    : _tokenStorage = tokenStorage ?? TokenStorage(),
      super(const AuthInitial()) {
    on<AuthLoginRequested>(_login);
    on<AuthRegisterRequested>(_register);
  }

  final AuthRepository _repository;
  final TokenStorage _tokenStorage;

  Future<void> _login(AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final response = await _repository.login(
        email: event.email,
        password: event.password,
      );
      await _tokenStorage.saveSession(
        accessToken: response.accessToken,
        userId: response.user.id,
      );
      emit(AuthAuthenticated(response));
    } on Exception catch (error) {
      emit(AuthFailure(error.toString()));
    }
  }

  Future<void> _register(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final response = await _repository.register(
        email: event.email,
        password: event.password,
        displayName: event.displayName,
      );
      await _tokenStorage.saveSession(
        accessToken: response.accessToken,
        userId: response.user.id,
      );
      emit(AuthAuthenticated(response));
    } on Exception catch (error) {
      emit(AuthFailure(error.toString()));
    }
  }
}
