import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/core/errors/auth_exception.dart';
import 'package:picnic_lib/data/models/common/social_login_result.dart';
import 'package:picnic_lib/core/services/auth/social_login/apple_login.dart';
import 'package:picnic_lib/core/services/auth/social_login/google_login.dart';
import 'package:picnic_lib/core/services/auth/social_login/kakao_login.dart';
import 'package:picnic_lib/core/services/device_manager.dart';
import 'package:picnic_lib/core/services/network_connectivity_service.dart';
import 'package:picnic_lib/core/services/secure_storage_service.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class SocialLogin {
  Future<SocialLoginResult> login();

  Future<void> logout();
}

class AuthTimeouts {
  const AuthTimeouts({
    this.networkCheck = const Duration(seconds: 5),
    this.sessionRecovery = const Duration(seconds: 10),
    this.tokenRefresh = const Duration(seconds: 8),
    this.tokenExpiration = const Duration(hours: 1),
  });

  final Duration networkCheck;
  final Duration sessionRecovery;
  final Duration tokenRefresh;
  final Duration tokenExpiration;
}

class AuthService {
  final SecureStorageService _storageService;
  final NetworkConnectivityService _networkService;
  final Map<supa.OAuthProvider, SocialLogin> _loginProviders;

  static const _timeouts = AuthTimeouts();
  final _sessionController = StreamController<Session?>.broadcast();

  AuthService({
    SecureStorageService? storageService,
    NetworkConnectivityService? networkService,
    Map<supa.OAuthProvider, SocialLogin>? loginProviders,
  })  : _storageService = storageService ?? SecureStorageService(),
        _networkService = networkService ?? NetworkConnectivityService(),
        _loginProviders = loginProviders ?? _createDefaultLoginProviders();

  static Map<supa.OAuthProvider, SocialLogin> _createDefaultLoginProviders() =>
      {
        supa.OAuthProvider.google: kIsWeb
            ? GoogleLogin(GoogleSignIn(
                clientId: Environment.googleServerClientId,
              ))
            : GoogleLogin(GoogleSignIn(
                clientId: Environment.googleClientId,
                serverClientId: Environment.googleServerClientId,
              )),
        supa.OAuthProvider.apple: AppleLogin(),
        supa.OAuthProvider.kakao: KakaoLogin(),
      };

  Future<supa.User?> signInWithProvider(supa.OAuthProvider provider) async {
    try {
      if (await DeviceManager.isDeviceBanned()) {
        throw PicnicAuthExceptions.deviceBanned();
      }

      final socialLogin = _loginProviders[provider];
      if (socialLogin == null) {
        throw PicnicAuthExceptions.unsupportedProvider(provider.name);
      }

      if (!await _networkService.checkOnlineStatus()) {
        throw PicnicAuthExceptions.network();
      }

      final result = await socialLogin.login();
      if (result.idToken == null) {
        throw PicnicAuthExceptions.invalidToken();
      }

      final response = await supabase.auth.signInWithIdToken(
        provider: provider,
        idToken: result.idToken!,
      );

      if (response.session == null || response.user == null) {
        throw PicnicAuthExceptions.invalidToken();
      }

      await DeviceManager.registerDevice(response.user!.id);

      await _saveAndNotifySession(response.session!);
      return response.user;
    } catch (e, s) {
      logger.e('Error during sign in:', error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<bool> recoverSession() async {
    try {
      if (!await _networkService.checkOnlineStatus()) {
        logger.w('Cannot recover session - offline');
        return false;
      }

      final session = await _storageService.getSession();
      if (session == null) {
        logger.w('No stored session found');
        return false;
      }

      if (_isSessionExpired(session)) {
        logger.i('Session expired, attempting refresh');
        return await _refreshSession();
      }

      // Session 복구 시도
      try {
        final response = await supabase.auth
            .recoverSession(jsonEncode(session))
            .timeout(_timeouts.sessionRecovery);

        if (response.session != null) {
          await DeviceManager.updateLastSeen();
          await _saveAndNotifySession(response.session!);
          return true;
        }
      } catch (e, s) {
        logger.e('Session recovery failed, trying refresh',
            error: e, stackTrace: s);
      }

      // 복구 실패시 refresh 시도
      return await _refreshSession();
    } catch (e, s) {
      logger.e('Session recovery failed', error: e, stackTrace: s);
      await _handleAuthError(e);
      return false;
    }
  }

  bool _isSessionExpired(Session session) {
    final expiresAt =
        DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000);
    return DateTime.now().isAfter(expiresAt);
  }

  Future<bool> refreshSession() async {
    try {
      if (!await _networkService.checkOnlineStatus()) {
        logger.w('Cannot refresh session - offline');
        return false;
      }

      final session = await _storageService.getSession();
      if (session == null) {
        logger.w('No stored session found');
        return false;
      }

      final response =
          await supabase.auth.refreshSession().timeout(_timeouts.tokenRefresh);

      if (response.session != null) {
        await _saveAndNotifySession(response.session!);
        return true;
      }

      return false;
    } catch (e, s) {
      logger.e('Error refreshing session', error: e, stackTrace: s);
      await _handleAuthError(e);
      return false;
    }
  }

  // Private refresh method for internal use
  Future<bool> _refreshSession() => refreshSession();

  Future<void> signOut() async {
    try {
      final session = await _storageService.getSession();
      if (session != null) {
        final provider = _getProviderFromSession(session);
        await _logoutFromProvider(provider);
        await DeviceManager.updateLastSeen();
      }
      await _clearAuthState();
    } catch (e, s) {
      logger.e('Error during sign out', error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<void> _logoutFromProvider(supa.OAuthProvider provider) async {
    final socialLogin = _loginProviders[provider];
    if (socialLogin != null) {
      await socialLogin.logout();
      logger.i('Social provider logout successful: ${provider.name}');
    }
  }

  supa.OAuthProvider _getProviderFromSession(Session session) {
    try {
      final jwt = session.accessToken;
      final parts = jwt.split('.');
      if (parts.length != 3) throw const FormatException('Invalid JWT format');

      final payload =
          String.fromCharCodes(base64Url.decode(base64Url.normalize(parts[1])));
      final data = jsonDecode(payload);

      final provider = data['provider'] as String?;
      return _parseProvider(provider);
    } catch (e, s) {
      logger.e('Error extracting provider from session',
          error: e, stackTrace: s);
      return supa.OAuthProvider.google; // 기본값 반환
    }
  }

  supa.OAuthProvider _parseProvider(String? provider) {
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

  Future<void> _handleAuthError(dynamic error) async {
    logger.e('Handling auth error: $error');
    if (_shouldClearSession(error)) {
      await _clearAuthState();
    }
  }

  bool _shouldClearSession(dynamic error) {
    return error is TimeoutException ||
        (error is AuthException &&
            (error.message.contains('Token expired') ||
                error.statusCode == "401"));
  }

  Future<void> _saveAndNotifySession(Session session) async {
    await _storageService.saveSession(session);
    _sessionController.add(session);
  }

  Future<void> _clearAuthState() async {
    await supabase.auth.signOut();
    await _storageService.clearSession();
    _sessionController.add(null);
    logger.i('Auth state cleared');
  }

  Stream<Session?> get sessionStream => _sessionController.stream;

  Future<void> dispose() async {
    await _sessionController.close();
  }
}
