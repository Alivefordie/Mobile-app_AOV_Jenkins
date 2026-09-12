import 'package:flutter_application_1/bloc/auth/auth_event.dart';
import 'package:flutter_application_1/bloc/auth/auth_state.dart';
import 'package:flutter_application_1/repositories/auth_repository.dart';
import 'package:flutter_application_1/repositories/token_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._repository, {TokenStorage? tokenStorage})
    : _tokenStorage = tokenStorage ?? TokenStorage(),
      super(const AuthInitial()) {
    on<AuthLoginRequested>(_login);
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
      await _tokenStorage.saveAccessToken(response.accessToken);
      emit(AuthAuthenticated(response));
    } on Exception catch (error) {
      emit(AuthFailure(error.toString()));
    }
  }
}
