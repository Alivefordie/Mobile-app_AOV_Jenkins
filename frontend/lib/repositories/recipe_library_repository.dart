import 'dart:async';
import 'dart:convert';

import 'package:flutter_application_1/models/recipe_collection_type.dart';
import 'package:flutter_application_1/models/recipe_summary.dart';
import 'package:http/http.dart' as http;

abstract interface class RecipeLibraryRepository {
  Future<List<RecipeSummary>> fetchCollection(
    RecipeCollectionType type,
    String userId,
  );
}

class HttpRecipeLibraryRepository implements RecipeLibraryRepository {
  HttpRecipeLibraryRepository({
    required String baseUrl,
    http.Client? client,
    this.requestTimeout = const Duration(seconds: 10),
  }) : _baseUrl = baseUrl.replaceAll(RegExp(r'/+$'), ''),
       _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;
  final Duration requestTimeout;

  @override
  Future<List<RecipeSummary>> fetchCollection(
    RecipeCollectionType type,
    String userId,
  ) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      throw const RecipeLibraryException(
        'PROFILE_USER_ID is missing. Restart the app with a user UUID.',
      );
    }

    final uri = _uriFor(type, normalizedUserId);

    try {
      final response = await _client.get(uri).timeout(requestTimeout);
      if (response.statusCode != 200) {
        throw RecipeLibraryException(
          'Could not load ${type.title.toLowerCase()} '
          '(HTTP ${response.statusCode}).',
        );
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! List) {
        throw const RecipeLibraryException(
          'Backend returned an invalid recipe list.',
        );
      }

      return decoded
          .map((item) {
            if (item is! Map<String, dynamic>) {
              throw const RecipeLibraryException(
                'Backend returned an invalid recipe item.',
              );
            }

            final recipeJson = switch (type) {
              RecipeCollectionType.favorites ||
              RecipeCollectionType.purchased => item['recipe'],
              _ => item,
            };
            if (recipeJson is! Map<String, dynamic>) {
              throw const RecipeLibraryException(
                'Backend response does not include recipe details.',
              );
            }

            return RecipeSummary.fromJson(recipeJson, apiBaseUrl: _baseUrl);
          })
          .toList(growable: false);
    } on TimeoutException {
      throw const RecipeLibraryException(
        'The request timed out. Check the backend connection.',
      );
    } on FormatException {
      throw const RecipeLibraryException('Backend returned malformed JSON.');
    } on http.ClientException catch (error) {
      throw RecipeLibraryException(
        'Could not connect to the backend: ${error.message}',
      );
    }
  }

  Uri _uriFor(RecipeCollectionType type, String userId) {
    return switch (type) {
      RecipeCollectionType.myRecipes => Uri.parse(
        '$_baseUrl/recipes',
      ).replace(queryParameters: {'creatorId': userId, 'status': 'published'}),
      RecipeCollectionType.drafts => Uri.parse(
        '$_baseUrl/recipes',
      ).replace(queryParameters: {'creatorId': userId, 'status': 'draft'}),
      RecipeCollectionType.favorites => Uri.parse(
        '$_baseUrl/favorites',
      ).replace(queryParameters: {'userId': userId}),
      RecipeCollectionType.purchased => Uri.parse(
        '$_baseUrl/recipe-access/user/${Uri.encodeComponent(userId)}',
      ),
    };
  }
}

class RecipeLibraryException implements Exception {
  const RecipeLibraryException(this.message);

  final String message;

  @override
  String toString() => message;
}
