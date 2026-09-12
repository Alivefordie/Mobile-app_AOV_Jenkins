import 'package:flutter_application_1/models/auth_response.dart';

sealed class AuthState {
  const AuthState();
}

final class AuthInitial extends AuthState {
  const AuthInitial();
}

final class AuthLoading extends AuthState {
  const AuthLoading();
}

final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.response);

  final AuthResponse response;
}

final class AuthFailure extends AuthState {
  const AuthFailure(this.message);

  final String message;
}
