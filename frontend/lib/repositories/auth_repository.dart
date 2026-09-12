import 'dart:async';
import 'dart:convert';

import 'package:flutter_application_1/models/auth_response.dart';
import 'package:http/http.dart' as http;

abstract interface class AuthRepository {
  Future<AuthResponse> login({required String email, required String password});

  Future<AuthResponse> register({
    required String email,
    required String password,
    required String displayName,
  });
}

class HttpAuthRepository implements AuthRepository {
  HttpAuthRepository({
    required String baseUrl,
    http.Client? client,
    this.requestTimeout = const Duration(seconds: 10),
  }) : _baseUrl = baseUrl.replaceAll(RegExp(r'/+$'), ''),
       _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;
  final Duration requestTimeout;

  @override
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/auth/login'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email.trim(), 'password': password}),
          )
          .timeout(requestTimeout);

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AuthRepositoryException(_errorMessage(decoded));
      }
      if (decoded is! Map<String, dynamic>) {
        throw const AuthRepositoryException(
          'Backend returned an invalid login response.',
        );
      }

      return AuthResponse.fromJson(decoded);
    } on AuthRepositoryException {
      rethrow;
    } on TimeoutException {
      throw const AuthRepositoryException(
        'Login request timed out. Check the backend connection.',
      );
    } on FormatException {
      throw const AuthRepositoryException('Backend returned malformed JSON.');
    } on http.ClientException catch (error) {
      throw AuthRepositoryException(
        'Could not connect to the backend: ${error.message}',
      );
    }
  }

  @override
  Future<AuthResponse> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    return _sendAuthRequest(
      path: '/auth/register',
      body: {
        'email': email.trim(),
        'password': password,
        'displayName': displayName.trim(),
      },
    );
  }

  Future<AuthResponse> _sendAuthRequest({
    required String path,
    required Map<String, String> body,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl$path'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(requestTimeout);

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AuthRepositoryException(_errorMessage(decoded));
      }
      if (decoded is! Map<String, dynamic>) {
        throw const AuthRepositoryException(
          'Backend returned an invalid authentication response.',
        );
      }
      return AuthResponse.fromJson(decoded);
    } on AuthRepositoryException {
      rethrow;
    } on TimeoutException {
      throw const AuthRepositoryException(
        'Request timed out. Check the backend connection.',
      );
    } on FormatException {
      throw const AuthRepositoryException('Backend returned malformed JSON.');
    } on http.ClientException catch (error) {
      throw AuthRepositoryException(
        'Could not connect to the backend: ${error.message}',
      );
    }
  }

  String _errorMessage(Object decoded) {
    if (decoded is Map<String, dynamic>) {
      final message = decoded['message'];
      if (message is String) return message;
      if (message is List) return message.join('\n');
    }
    return 'Login failed. Please check your email and password.';
  }
}

class AuthRepositoryException implements Exception {
  const AuthRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
