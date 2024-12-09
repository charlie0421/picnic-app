import 'package:supabase_flutter/supabase_flutter.dart';

class AuthTokenInfo {
  final String accessToken;
  final String? refreshToken;
  final String idToken;
  final DateTime expiresAt;
  final OAuthProvider provider;

  AuthTokenInfo({
    required this.accessToken,
    required this.refreshToken,
    required this.idToken,
    required this.expiresAt,
    required this.provider,
  });

  Map<String, dynamic> toJson() => {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'idToken': idToken,
        'expiresAt': expiresAt.toIso8601String(),
        'provider': provider.name,
      };

  factory AuthTokenInfo.fromJson(Map<String, dynamic> json) {
    return AuthTokenInfo(
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
      idToken: json['idToken'],
      expiresAt: DateTime.parse(json['expiresAt']),
      provider: OAuthProvider.values.firstWhere(
        (e) => e.name == json['provider'],
      ),
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
