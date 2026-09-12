import 'dart:async';
import 'dart:convert';

import 'package:flutter_application_1/models/user_profile.dart';
import 'package:http/http.dart' as http;

abstract interface class ProfileRepository {
  Future<UserProfile> fetchProfile(String userId);
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
  Future<UserProfile> fetchProfile(String userId) async {
    final normalizedUserId = userId.trim();
    //
    if (normalizedUserId.isEmpty) {
      throw const ProfileRepositoryException(
        'PROFILE_USER_ID is missing. Start Flutter with '
        '--dart-define=PROFILE_USER_ID=<user-uuid>.'
        'dev only',
      );
    }
    //
    final uri = Uri.parse(
      '$_baseUrl/users/${Uri.encodeComponent(normalizedUserId)}/profile',
    );

    try {
      final response = await _client.get(uri).timeout(requestTimeout);

      if (response.statusCode == 404) {
        throw const ProfileRepositoryException('Profile not found.');
      }
      if (response.statusCode != 200) {
        throw ProfileRepositoryException(
          'Could not load profile (HTTP ${response.statusCode}).',
        );
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) {
        throw const ProfileRepositoryException(
          'Backend returned an invalid profile response.',
        );
      }

      try {
        // print('Decoded profile JSON: $decoded');
        return UserProfile.fromJson(decoded, apiBaseUrl: _baseUrl);
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
