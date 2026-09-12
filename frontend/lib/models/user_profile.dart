import 'package:flutter_application_1/models/auth_response.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.displayName,
    required this.email,
    required this.avatarUrl,
    required this.role,
    required this.status,
    required this.recipeCount,
    required this.purchasedCount,
    required this.savedCount,
    required this.draftCount,
    required this.rating,
  });

  static const fallbackAvatarAsset = 'assets/images/Profile1.jpg';

  final String id;
  final String displayName;
  final String email;
  final String? avatarUrl;
  final String role;
  final String status;
  final int recipeCount;
  final int purchasedCount;
  final int savedCount;
  final int draftCount;
  final double rating;

  factory UserProfile.guest() {
    return const UserProfile(
      id: '',
      displayName: 'Guest',
      email: '-',
      avatarUrl: null,
      role: 'guest',
      status: 'guest',
      recipeCount: 0,
      purchasedCount: 0,
      savedCount: 0,
      draftCount: 0,
      rating: 0,
    );
  }

  String get roleLabel => switch (role) {
    'creator' => 'Recipe creator',
    'admin' => 'Administrator',
    _ => 'Food lover',
  };

  factory UserProfile.fromAuthUser(
    AuthUser user, {
    required String apiBaseUrl,
  }) {
    return UserProfile(
      id: user.id,
      displayName: user.displayName,
      email: user.email,
      avatarUrl: _resolveAvatarUrl(user.avatarUrl, apiBaseUrl),
      role: user.role,
      status: 'active',
      recipeCount: 0,
      purchasedCount: 0,
      savedCount: 0,
      draftCount: 0,
      rating: 0,
    );
  }

  factory UserProfile.fromJson(
    Map<String, dynamic> json, {
    required String apiBaseUrl,
  }) {
    final rawAvatarUrl = json['avatarUrl'];

    return UserProfile(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      email: json['email'] as String,
      // avatarUrl: json['avatarUrl'] as String  ,
      role: json['role'] as String,
      status: json['status'] as String,
      recipeCount: json['recipeCount'] as int,
      purchasedCount: json['purchasedCount'] as int,
      savedCount: json['savedCount'] as int,
      draftCount: json['draftCount'] as int,
      rating: (json['rating'] as num).toDouble(),
      // id: _requiredString(json, 'id'),
      // displayName: _requiredString(json, 'displayName'),
      // email: _requiredString(json, 'email'),
      avatarUrl: _resolveAvatarUrl(rawAvatarUrl, apiBaseUrl),
      // role: _requiredString(json, 'role'),
      // status: _requiredString(json, 'status'),
      // recipeCount: _requiredInt(json, 'recipeCount'),
      // purchasedCount: _requiredInt(json, 'purchasedCount'),
      // savedCount: _requiredInt(json, 'savedCount'),
      // draftCount: _requiredInt(json, 'draftCount'),
      // rating: _requiredNumber(json, 'rating').toDouble(),
    );
  }

  // static String _requiredString(Map<String, dynamic> json, String key) {
  //   final value = json[key];
  //   if (value is! String || value.isEmpty) {
  //     throw FormatException('Profile field "$key" must be a non-empty string');
  //   }
  //   return value;
  // }

  // static int _requiredInt(Map<String, dynamic> json, String key) {
  //   final value = json[key];
  //   if (value is! num) {
  //     throw FormatException('Profile field "$key" must be a number');
  //   }
  //   return value.toInt();
  // }

  // static num _requiredNumber(Map<String, dynamic> json, String key) {
  //   final value = json[key];
  //   if (value is! num) {
  //     throw FormatException('Profile field "$key" must be a number');
  //   }
  //   return value;
  // }

  static String? _resolveAvatarUrl(Object? value, String apiBaseUrl) {
    if (value == null) return null;
    if (value is! String) {
      throw const FormatException('Profile field "avatarUrl" is invalid');
    }
    if (value.trim().isEmpty) return null;

    final uri = Uri.parse(value);
    if (uri.hasScheme) return uri.toString();

    final normalizedBaseUrl = apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
    final normalizedPath = value.startsWith('/') ? value : '/$value';
    return '$normalizedBaseUrl$normalizedPath';
  }
}
