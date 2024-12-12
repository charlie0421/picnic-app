// auth_service.dart

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:picnic_app/config/environment.dart';
import 'package:picnic_app/exceptions/auth_exception.dart';
import 'package:picnic_app/models/auth_token_info.dart';
import 'package:picnic_app/models/common/social_login_result.dart';
import 'package:picnic_app/services/auth/social_login/apple_login.dart';
import 'package:picnic_app/services/auth/social_login/google_login.dart';
import 'package:picnic_app/services/auth/social_login/kakao_login.dart';
import 'package:picnic_app/services/secure_storage_service.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/util/logger.dart';
import 'package:supabase_extensions/supabase_extensions.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as Supabase;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:universal_io/io.dart';

abstract class SocialLogin {
  Future<SocialLoginResult> login();

  Future<void> logout();
}

class AuthService {
  final SecureStorageService _storageService;
  final Map<Supabase.OAuthProvider, SocialLogin> _loginProviders;
  static const tokenExpirationDuration = Duration(hours: 1);
  static const networkCheckTimeout = Duration(seconds: 5);
  static const sessionRecoveryTimeout = Duration(seconds: 10);
  static const tokenRefreshTimeout = Duration(seconds: 8);

  AuthService({
    SecureStorageService? storageService,
    Map<Supabase.OAuthProvider, SocialLogin>? loginProviders,
  })  : _storageService = storageService ?? SecureStorageService(),
        _loginProviders = loginProviders ??
            {
              Supabase.OAuthProvider.google: kIsWeb
                  ? GoogleLogin(GoogleSignIn(
                      clientId: Environment.googleServerClientId,
                    ))
                  : GoogleLogin(GoogleSignIn(
                      clientId: Environment.googleClientId,
                      serverClientId: Environment.googleServerClientId,
                    )),
              Supabase.OAuthProvider.apple: AppleLogin(),
              Supabase.OAuthProvider.kakao: KakaoLogin(),
            };

  Future<Supabase.User?> signInWithProvider(
      Supabase.OAuthProvider provider) async {
    try {
      final socialLogin = _loginProviders[provider];
      if (socialLogin == null) {
        logger.w('Unsupported provider: $provider');
        throw PicnicAuthExceptions.unsupportedProvider(provider.name);
      }

      final result = await socialLogin.login();
      if (result.idToken == null) {
        throw PicnicAuthExceptions.invalidToken();
      }

      final response = await supabase.auth.signInWithIdToken(
        provider: provider,
        idToken: result.idToken!,
      );

      if (response.user != null && response.session != null) {
        final tokenInfo = AuthTokenInfo(
          accessToken: response.session!.accessToken,
          refreshToken: response.session!.refreshToken,
          idToken: result.idToken!,
          expiresAt: DateTime.now().add(tokenExpirationDuration),
          provider: provider,
        );

        await _storageService.saveTokenInfo(tokenInfo);
        return response.user;
      }
    } catch (e, s) {
      logger.e('Error during sign in:', error: e, stackTrace: s);
      if (e is PicnicAuthException) rethrow;
      throw PicnicAuthExceptions.unknown(originalError: e);
    }
  }

  Future<bool> recoverSession() async {
    try {
      // 네트워크 체크에 타임아웃 추가
      final isOnline = await NetworkCheck.isOnline()
          .timeout(networkCheckTimeout, onTimeout: () {
        logger.e('Network check timed out');
        return false;
      });

      if (!isOnline) {
        logger.w('Cannot recover session - offline');
        return false;
      }

      final tokenInfo = await _storageService.getTokenInfo();
      if (tokenInfo == null) {
        logger.w('No stored token info found');
        return false;
      }

      if (tokenInfo.isExpired) {
        logger.i('Token expired, attempting refresh');
        return await _refreshSession(tokenInfo);
      }

      try {
        // signInWithIdToken에 타임아웃 추가
        final response = await supabase.auth
            .signInWithIdToken(
          provider: tokenInfo.provider,
          idToken: tokenInfo.idToken,
        )
            .timeout(sessionRecoveryTimeout, onTimeout: () {
          throw TimeoutException('Session recovery timed out');
        });

        if (response.session != null) {
          await _updateSessionTokens(response.session!, tokenInfo);
          return true;
        }
      } catch (e, s) {
        logger.e('Error during session recovery', error: e, stackTrace: s);
        return await _refreshSession(tokenInfo);
      }

      return false;
    } catch (e, s) {
      logger.e('Session recovery failed', error: e, stackTrace: s);
      await _handleAuthError(e);
      return false;
    }
  }

  Future<bool> _refreshSession(AuthTokenInfo tokenInfo) async {
    try {
      // refreshSession에 타임아웃 추가
      final response = await supabase.auth
          .refreshSession()
          .timeout(tokenRefreshTimeout, onTimeout: () {
        throw TimeoutException('Token refresh timed out');
      });

      if (response.session != null) {
        await _updateSessionTokens(response.session!, tokenInfo);
        return true;
      }

      logger.w('Session refresh failed - no session returned');
      return false;
    } catch (e, s) {
      logger.e('Error refreshing session', error: e, stackTrace: s);
      await _handleAuthError(e);
      return false;
    }
  }

  Future<void> _handleAuthError(dynamic error) async {
    logger.e('Handling auth error: $error'); // 추가된 로그
    if (error is TimeoutException) {
      await _storageService.clearTokenInfo();
      logger.i('Cleared stored tokens due to timeout');
      return;
    }

    if (error is AuthException) {
      if (error.message.contains('Token expired') || error.statusCode == 401) {
        await _storageService.clearTokenInfo();
        logger.i('Cleared stored tokens due to expiration/unauthorized');
      }
    } else if (error is String && error.contains('Token expired')) {
      await _storageService.clearTokenInfo();
      logger.i('Cleared stored tokens due to expiration message');
    }
  }

  Future<void> _updateSessionTokens(
      Session session, AuthTokenInfo oldTokenInfo) async {
    final newTokenInfo = AuthTokenInfo(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      idToken: oldTokenInfo.idToken,
      expiresAt: DateTime.now().add(tokenExpirationDuration),
      provider: oldTokenInfo.provider,
    );

    await _storageService.saveTokenInfo(newTokenInfo);
    logger.i('Session tokens updated successfully');
  }

  Future<void> signOut() async {
    try {
      final tokenInfo = await _storageService.getTokenInfo();
      if (tokenInfo != null) {
        final socialLogin = _loginProviders[tokenInfo.provider];
        if (socialLogin != null) {
          await socialLogin.logout();
          logger.i(
              'Social provider logout successful: ${tokenInfo.provider.name}');
        }
      }

      await supabase.auth.signOut();
      await _storageService.clearTokenInfo();
      logger.i('Sign out completed successfully');
    } catch (e, s) {
      logger.e('Error during sign out', error: e, stackTrace: s);
      throw PicnicAuthExceptions.unknown(originalError: e);
    }
  }

  Future<void> refreshToken() async {
    if (!supabase.isLogged) {
      logger.w('Cannot refresh token - not logged in');
      return;
    }

    if (!await NetworkCheck.isOnline()) {
      logger.e('Cannot refresh token - offline');
      throw PicnicAuthExceptions.network();
    }

    try {
      final tokenInfo = await _storageService.getTokenInfo();
      if (tokenInfo == null) {
        logger.e('No token info found for refresh');
        throw PicnicAuthExceptions.invalidToken();
      }

      final response = await supabase.auth.refreshSession();
      if (response.session != null) {
        await _updateSessionTokens(response.session!, tokenInfo);
        logger.i('Token refreshed successfully');
      } else {
        logger.e('Token refresh failed - no session returned');
        throw PicnicAuthExceptions.invalidToken();
      }
    } catch (e, s) {
      logger.e('Token refresh failed', error: e, stackTrace: s);
      await _handleAuthError(e);
      throw PicnicAuthExceptions.unknown(originalError: e);
    }
  }

  // 토큰 상태 모니터링을 위한 Stream
  Stream<AuthTokenInfo?> get tokenStream async* {
    while (true) {
      yield await _storageService.getTokenInfo();
      await Future.delayed(const Duration(minutes: 1));
    }
  }
}

class NetworkCheck {
  static Future<bool> isOnline() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }
}
