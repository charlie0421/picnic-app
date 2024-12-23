// auth_token_info.dart

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class AuthTokenInfo {
  final String accessToken;
  final String? refreshToken;
  final DateTime expiresAt;
  final supabase.OAuthProvider provider;

  AuthTokenInfo({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.provider,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toJson() => {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'expiresAt': expiresAt.toIso8601String(),
        'provider': provider.name,
      };

  factory AuthTokenInfo.fromJson(Map<String, dynamic> json) => AuthTokenInfo(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        expiresAt: DateTime.parse(json['expiresAt'] as String),
        provider: supabase.OAuthProvider.values
            .firstWhere((e) => e.name == json['provider']),
      );
}
