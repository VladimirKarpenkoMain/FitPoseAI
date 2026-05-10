class User {
  final int id;
  final String email;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class AuthToken {
  final String accessToken;
  final String refreshToken;
  final String tokenType;

  AuthToken({
    required this.accessToken,
    required this.refreshToken,
    this.tokenType = 'bearer',
  });

  factory AuthToken.fromJson(Map<String, dynamic> json) {
    return AuthToken(
      accessToken: json['access_token'],
      refreshToken: json['refresh_token'],
      tokenType: json['token_type'] ?? 'bearer',
    );
  }
}
