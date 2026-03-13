import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

/// Helper class containing extracted pure logic from AuthService.
/// These methods were private in AuthService but are now testable.
class AuthServiceHelper {
  /// Checks if a session is expired based on its expiresAt timestamp.
  @visibleForTesting
  static bool isSessionExpired(int expiresAtSeconds) {
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(
      expiresAtSeconds * 1000,
    );
    return DateTime.now().isAfter(expiresAt);
  }

  /// Determines whether the auth state should be cleared for a given error.
  /// Only clears for explicit auth failures (401, Token expired),
  /// not for transient errors like TimeoutException.
  @visibleForTesting
  static bool shouldClearSession(dynamic error) {
    return error is supa.AuthException &&
        (error.message.contains('Token expired') ||
            error.statusCode == "401");
  }

  /// Parses an OAuth provider string into the corresponding OAuthProvider enum.
  /// Defaults to google if the provider string is unknown or null.
  @visibleForTesting
  static supa.OAuthProvider parseProvider(String? provider) {
    switch (provider?.toLowerCase()) {
      case 'google':
        return supa.OAuthProvider.google;
      case 'apple':
        return supa.OAuthProvider.apple;
      case 'kakao':
        return supa.OAuthProvider.kakao;
      default:
        return supa.OAuthProvider.google;
    }
  }

  /// Extracts the provider name from a JWT access token.
  /// Returns the provider string or null if extraction fails.
  @visibleForTesting
  static String? extractProviderFromJwt(String jwt) {
    final parts = jwt.split('.');
    if (parts.length != 3) return null;

    try {
      final payload = String.fromCharCodes(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final data = jsonDecode(payload);
      return data['provider'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Resolves an OAuthProvider from a JWT access token.
  /// Combines extractProviderFromJwt and parseProvider.
  /// Defaults to google on any error.
  @visibleForTesting
  static supa.OAuthProvider getProviderFromJwt(String jwt) {
    final providerStr = extractProviderFromJwt(jwt);
    return parseProvider(providerStr);
  }

  /// Checks if a refresh token is valid (non-null, non-empty).
  @visibleForTesting
  static bool isRefreshTokenValid(String? refreshToken) {
    return refreshToken != null && refreshToken.isNotEmpty;
  }

  /// Checks if a specific AuthException status code indicates
  /// a missing session (400) which can be safely skipped.
  @visibleForTesting
  static bool isMissingSessionError(dynamic error) {
    return error is supa.AuthException && error.statusCode == "400";
  }
}
