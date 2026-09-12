import 'dart:async';
import 'dart:convert';

import 'package:flutter_application_1/models/auth_response.dart';
import 'package:flutter_application_1/models/user_profile.dart';
import 'package:http/http.dart' as http;

abstract interface class ProfileRepository {
  Future<UserProfile> fetchProfile(String accessToken);
}

class HttpProfileRepository implements ProfileRepository {
  HttpProfileRepository({
    required String baseUrl,
    http.Client? client,
    this.requestTimeout = const Duration(seconds: 10),
  }) : _baseUrl = baseUrl.replaceAll(RegExp(r'/+$'), ''),
       _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;
  final Duration requestTimeout;

  @override
  Future<UserProfile> fetchProfile(String accessToken) async {
    final normalizedAccessToken = accessToken.trim();
    if (normalizedAccessToken.isEmpty) {
      throw const ProfileRepositoryException('Access token is missing.');
    }
    final uri = Uri.parse('$_baseUrl/auth/me');

    try {
      final response = await _client
          .get(uri, headers: {'Authorization': 'Bearer $normalizedAccessToken'})
          .timeout(requestTimeout);

      if (response.statusCode != 200) {
        throw ProfileRepositoryException(
          response.statusCode == 401
              ? 'Your session has expired. Please sign in again.'
              : 'Could not load profile (HTTP ${response.statusCode}).',
        );
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) {
        throw const ProfileRepositoryException(
          'Backend returned an invalid profile response.',
        );
      }

      try {
        return UserProfile.fromAuthUser(
          AuthUser.fromJson(decoded),
          apiBaseUrl: _baseUrl,
        );
      } on FormatException catch (error) {
        throw ProfileRepositoryException(error.message);
      }
    } on TimeoutException {
      throw const ProfileRepositoryException(
        'Profile request timed out. Check the backend connection.',
      );
    } on FormatException {
      throw const ProfileRepositoryException(
        'Backend returned malformed JSON.',
      );
    } on http.ClientException catch (error) {
      throw ProfileRepositoryException(
        'Could not connect to the backend: ${error.message}',
      );
    }
  }
}

class ProfileRepositoryException implements Exception {
  const ProfileRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
