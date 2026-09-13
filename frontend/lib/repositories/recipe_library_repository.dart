import 'dart:async';
import 'dart:convert';

import 'package:flutter_application_1/models/recipe_collection_type.dart';
import 'package:flutter_application_1/models/recipe_summary.dart';
import 'package:http/http.dart' as http;

abstract interface class RecipeLibraryRepository {
  /// favorites ถูก guard ด้วย JWT จึงต้องแนบ accessToken
  /// ส่วน myRecipes/drafts/purchased ยังอ้างอิง userId ทาง query
  Future<List<RecipeSummary>> fetchCollection(
    RecipeCollectionType type, {
    required String userId,
    required String accessToken,
  });
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
    RecipeCollectionType type, {
    required String userId,
    required String accessToken,
  }) async {
    final normalizedUserId = userId.trim();
    final normalizedToken = accessToken.trim();
    if (normalizedUserId.isEmpty || normalizedToken.isEmpty) {
      throw const RecipeLibraryException(
        'Please sign in to see your recipes.',
      );
    }

    final uri = _uriFor(type, normalizedUserId);

    try {
      final response = await _client
          .get(uri, headers: {'Authorization': 'Bearer $normalizedToken'})
          .timeout(requestTimeout);

      if (response.statusCode == 401) {
        throw const RecipeLibraryException(
          'Your session has expired. Please sign in again.',
        );
      }
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
      // /favorites รู้ว่าเป็นของใครจาก token แล้ว ไม่ต้องส่ง userId
      RecipeCollectionType.favorites => Uri.parse('$_baseUrl/favorites'),
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
