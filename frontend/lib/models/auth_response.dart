class AuthResponse {
  const AuthResponse({
    required this.accessToken,
    required this.expiresIn,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final accessToken = json['accessToken'];
    final expiresIn = json['expiresIn'];
    final user = json['user'];

    if (accessToken is! String ||
        expiresIn is! String ||
        user is! Map<String, dynamic>) {
      throw const FormatException(
        'Backend returned an invalid login response.',
      );
    }

    return AuthResponse(
      accessToken: accessToken,
      expiresIn: expiresIn,
      user: AuthUser.fromJson(user),
    );
  }

  final String accessToken;
  final String expiresIn;
  final AuthUser user;
}

class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.avatarUrl,
    required this.role,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final email = json['email'];
    final displayName = json['displayName'];
    final role = json['role'];

    if (id is! String ||
        email is! String ||
        displayName is! String ||
        role is! String) {
      throw const FormatException('Backend returned an invalid user response.');
    }

    return AuthUser(
      id: id,
      email: email,
      displayName: displayName,
      avatarUrl: json['avatarUrl'] as String?,
      role: role,
    );
  }

  final String id;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final String role;
}
