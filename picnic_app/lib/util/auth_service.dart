// auth_service.dart

import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:picnic_app/config/environment.dart';
import 'package:picnic_app/exceptions/auth_exception.dart';
import 'package:picnic_app/models/common/social_login_result.dart';
import 'package:picnic_app/storage/storage.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/util/logger.dart';
import 'package:picnic_app/util/network.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_extensions/supabase_extensions.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as Supabase;
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class SocialLogin {
  Future<SocialLoginResult> login();

  Future<void> logout();
}

class AppleLogin implements SocialLogin {
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  @override
  Future<SocialLoginResult> login() async {
    try {
      final rawNonce = _generateNonce();

      final credential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName
          ],
          webAuthenticationOptions: WebAuthenticationOptions(
            clientId: Environment.appleClientId,
            redirectUri: Uri.parse(Environment.appleRedirectUri),
          ),
          state: rawNonce);

      if (credential.identityToken == null) {
        throw PicnicAuthExceptions.invalidToken();
      }

      final String? fullName =
          credential.familyName != null || credential.givenName != null
              ? '${credential.givenName ?? ''} ${credential.familyName ?? ''}'
                  .trim()
              : null;

      return SocialLoginResult(
        idToken: credential.identityToken,
        accessToken: credential.authorizationCode,
        userData: {
          'email': credential.email,
          'name': fullName,
        },
      );
    } catch (e, s) {
      logger.e('Apple login error: $e', stackTrace: s);

      if (e is SignInWithAppleAuthorizationException) {
        // 취소 관련 메시지들 체크
        if (e.code == AuthorizationErrorCode.canceled) {
          throw PicnicAuthExceptions.canceled();
        }

        switch (e.code) {
          case AuthorizationErrorCode.failed:
            throw PicnicAuthExceptions.appleSignInFailed();
          case AuthorizationErrorCode.invalidResponse:
            throw PicnicAuthExceptions.appleInvalidResponse();
          case AuthorizationErrorCode.notHandled:
            throw PicnicAuthExceptions.unknown(originalError: e);
          default:
            // 알 수 없는 에러의 경우 로그를 남기고 unknown으로 처리
            logger.e(
                'Unknown Apple auth error code: ${e.code}, message: ${e.message}');
            throw PicnicAuthExceptions.unknown(originalError: e);
        }
      } else if (e is PlatformException) {
        if (e.code == 'ERROR_AUTHORIZATION_DENIED' ||
            (e.message?.toLowerCase().contains('canceled') ?? false) ||
            (e.message?.toLowerCase().contains('cancelled') ?? false) ||
            (e.message?.contains('취소') ?? false)) {
          throw PicnicAuthExceptions.canceled();
        }
        throw PicnicAuthExceptions.unknown(originalError: e);
      }

      throw PicnicAuthExceptions.unknown(originalError: e);
    }
  }

  @override
  Future<void> logout() async {
    // Apple doesn't provide a logout method
    return;
  }
}

class GoogleLogin implements SocialLogin {
  final GoogleSignIn _googleSignIn;

  GoogleLogin(this._googleSignIn);

  @override
  Future<SocialLoginResult> login() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw PicnicAuthExceptions.canceled();
      }

      final googleAuth = await googleUser.authentication;
      return SocialLoginResult(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
        userData: {
          'email': googleUser.email,
          'name': googleUser.displayName,
          'photoUrl': googleUser.photoUrl,
        },
      );
    } catch (e, s) {
      logger.e('Google login error: $e', stackTrace: s);

      if (e is PicnicAuthException) {
        rethrow;
      }

      if (e is PlatformException) {
        switch (e.code) {
          case 'sign_in_canceled':
          case 'CANCELED':
            throw PicnicAuthExceptions.canceled();
          case 'sign_in_failed':
            if (e.message?.contains('12500') ?? false) {
              throw PicnicAuthExceptions.googlePlayServices();
            } else if (e.message?.contains('network_error') ?? false) {
              throw PicnicAuthExceptions.network();
            }
            throw PicnicAuthExceptions.unknown(originalError: e);
          default:
            throw PicnicAuthExceptions.unknown(originalError: e);
        }
      }

      throw PicnicAuthExceptions.unknown(originalError: e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
    } catch (e, s) {
      logger.e('Google logout error: $e', stackTrace: s);
      throw PicnicAuthExceptions.unknown(originalError: e);
    }
  }
}

class KakaoLogin implements SocialLogin {
  Future<OAuthToken?> _tryLogin(Function loginMethod) async {
    try {
      return await loginMethod();
    } catch (e, s) {
      logger.e('Kakao login failed: $e', stackTrace: s);

      if (e is PlatformException) {
        switch (e.code) {
          case 'CANCELED':
          case 'CANCELLED':
          case 'USER_CANCELLED':
            throw PicnicAuthExceptions.canceled();
          case 'NotSupportError':
            throw PicnicAuthExceptions.kakaoNotSupported();
          default:
            if (e.message != null &&
                (e.message?.contains('canceled') ??
                    false || e.message!.contains('cancelled'))) {
              throw PicnicAuthExceptions.canceled();
            }
            if (e.message?.contains('network') ?? false) {
              throw PicnicAuthExceptions.network();
            }
            throw PicnicAuthExceptions.unknown(originalError: e);
        }
      }
      throw PicnicAuthExceptions.unknown(originalError: e);
    }
  }

  @override
  Future<SocialLoginResult> login() async {
    try {
      KakaoSdk.init(
          nativeAppKey: Environment.kakaoNativeAppKey,
          javaScriptAppKey: Environment.kakaoJavascriptKey);

      OAuthToken? token;

      if (kIsWeb) {
        await supabase.auth.signInWithOAuth(OAuthProvider.kakao);
        return const SocialLoginResult();
      }

      if (await isKakaoTalkInstalled()) {
        try {
          token = await _tryLogin(UserApi.instance.loginWithKakaoTalk);
        } catch (e) {
          if (e is PicnicAuthException) {
            if (e.code == 'kakao_not_supported') {
              token = await _tryLogin(UserApi.instance.loginWithKakaoAccount);
            } else {
              rethrow;
            }
          } else {
            rethrow;
          }
        }
      } else {
        token = await _tryLogin(UserApi.instance.loginWithKakaoAccount);
      }

      if (token == null) {
        throw PicnicAuthExceptions.unknown();
      }

      final user = await UserApi.instance.me();
      return SocialLoginResult(
        idToken: token.idToken,
        accessToken: token.accessToken,
        userData: {
          'email': user.kakaoAccount?.email,
          'name': user.kakaoAccount?.profile?.nickname,
          'photoUrl': user.kakaoAccount?.profile?.profileImageUrl,
        },
      );
    } catch (e, s) {
      logger.e('Kakao login error: $e', stackTrace: s);
      if (e is PicnicAuthException) {
        rethrow;
      }
      throw PicnicAuthExceptions.unknown(originalError: e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await UserApi.instance.logout();
    } catch (e, s) {
      logger.e('Kakao logout error: $e', stackTrace: s);
      throw PicnicAuthExceptions.unknown(originalError: e);
    }
  }
}

class AuthService {
  final Storage _storage = kIsWeb ? WebStorage() : SecureStorage();

  final Map<Supabase.OAuthProvider, SocialLogin> _loginProviders = {
    Supabase.OAuthProvider.google: kIsWeb
        ? GoogleLogin(GoogleSignIn(
            clientId: Environment.googleServerClientId,
          ))
        : GoogleLogin(GoogleSignIn(
            clientId: Environment.googleClientId,
            serverClientId: Environment.googleServerClientId)),
    Supabase.OAuthProvider.apple: AppleLogin(),
    Supabase.OAuthProvider.kakao: KakaoLogin(),
  };

  Future<Supabase.User?> signInWithProvider(
      Supabase.OAuthProvider provider) async {
    try {
      final socialLogin = _loginProviders[provider];
      if (socialLogin == null) {
        logger.w('not support provider: $provider');
        throw PicnicAuthExceptions.unsupportedProvider(provider.name);
      }

      final result = await socialLogin.login();
      if (result.idToken == null) {
        throw PicnicAuthExceptions.invalidToken();
      }

      logger.i('idToken ${result.idToken}');
      final response = await supabase.auth.signInWithIdToken(
        provider: provider,
        idToken: result.idToken!,
      );

      if (response.user != null) {
        await _storeSession(response.session!, provider, result.idToken!);
        return response.user;
      }

      throw PicnicAuthExceptions.unknown();
    } catch (e, s) {
      logger.e('Error during sign in: $e', stackTrace: s);
      if (e is PicnicAuthException) {
        rethrow;
      }
      throw PicnicAuthExceptions.unknown(originalError: e);
    }
  }

  Future<void> signOut() async {
    try {
      final lastProvider = await _storage.read(key: 'last_provider');
      if (lastProvider != null) {
        final provider = Supabase.OAuthProvider.values
            .firstWhere((e) => e.name == lastProvider);
        final socialLogin = _loginProviders[provider];
        if (socialLogin != null) {
          await socialLogin.logout();
        }
      }

      await supabase.auth.signOut();
      await _clearStoredSession();
    } catch (e, s) {
      logger.e('Error during sign out: $e', stackTrace: s);
      throw PicnicAuthExceptions.unknown(originalError: e);
    }
  }

  Future<void> _storeSession(
      Session session, Supabase.OAuthProvider provider, String idToken) async {
    await _storage.write(
        key: 'supabase_access_token', value: session.accessToken);
    await _storage.write(
        key: 'supabase_refresh_token', value: session.refreshToken);
    await _storage.write(key: 'last_provider', value: provider.name);
    await _storage.write(
        key: '${provider.name.toLowerCase()}_id_token', value: idToken);
  }

  Future<bool> recoverSession() async {
    try {
      final lastProvider = await _storage.read(key: 'last_provider');

      if (lastProvider == null) {
        logger.w('No last provider found in storage');
        return false;
      }

      if (await NetworkCheck.isOnline()) {
        return await _recoverOAuthSession(Supabase.OAuthProvider.values
            .firstWhere((e) => e.name == lastProvider));
      } else {
        logger.w('Cannot recover session due to offline status');
        return false;
      }
    } catch (e, s) {
      logger.e('Error during session recovery: $e', stackTrace: s);
      Sentry.captureException(e, stackTrace: s);
      return false;
    }
  }

  Future<bool> _recoverOAuthSession(Supabase.OAuthProvider provider) async {
    const storage = FlutterSecureStorage();
    final idToken =
        await storage.read(key: '${provider.name.toLowerCase()}_id_token');
    logger.i('idToken:$idToken');
    if (idToken != null) {
      logger.i('Attempting to re-authenticate with ID token for $provider');

      try {
        final response = await supabase.auth.signInWithIdToken(
          provider: provider,
          idToken: idToken,
        );

        if (response.session != null) {
          await _storeSession(response.session!, provider, idToken);
          logger.i('Re-authentication successful for $provider');
          return true;
        }

        logger.w('Re-authentication failed for $provider: No session returned');
      } catch (e, s) {
        logger.e('Error during OAuth re-authentication for $provider: $e',
            stackTrace: s);
        rethrow;
      }
    } else {
      logger.w('No ID token found in storage for $provider');
    }

    return false;
  }

  Future<void> _clearStoredSession() async {
    try {
      final allValues = await _storage.readAll();
      logger.i('Before clearing: $allValues');

      for (var entry in allValues.entries) {
        if (entry.key != 'last_provider') {
          await _storage.delete(key: entry.key);
        }
      }

      final remainingValues = await _storage.readAll();
      logger.i('After clearing: $remainingValues');
      logger.i('Stored session cleared except last_provider');
    } catch (e, s) {
      logger.e('Error while clearing storage: $e', stackTrace: s);
      throw PicnicAuthExceptions.unknown(originalError: e);
    }
  }

  Future<void> refreshToken() async {
    if (supabase.isLogged) {
      if (await NetworkCheck.isOnline()) {
        try {
          final response = await supabase.auth.refreshSession();
          if (response.session != null) {
            await _storeSession(response.session!,
                Supabase.OAuthProvider.google, response.session!.accessToken);
            logger.i(
                'Token refreshed successfully: ${response.session?.accessToken}');
          } else {
            logger.e('Token refresh failed: No session returned');
            throw PicnicAuthExceptions.invalidToken();
          }
        } catch (e, s) {
          logger.e('Token refresh failed: $e', stackTrace: s);
          throw PicnicAuthExceptions.unknown(originalError: e);
        }
      } else {
        logger.w('Skipping token refresh due to offline status');
        throw PicnicAuthExceptions.network();
      }
    }
  }
}
