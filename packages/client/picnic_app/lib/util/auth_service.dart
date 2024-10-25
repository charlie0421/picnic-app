import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:picnic_app/config/environment.dart';
import 'package:picnic_app/models/common/social_login_result.dart';
import 'package:picnic_app/storage/storage.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/util/logger.dart';
import 'package:picnic_app/util/network.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as Supabase;
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class SocialLogin {
  Future<SocialLoginResult> login();

  Future<void> logout();
}

class GoogleLogin implements SocialLogin {
  final GoogleSignIn _googleSignIn;

  GoogleLogin(this._googleSignIn);

  @override
  Future<SocialLoginResult> login() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      final googleAuth = await googleUser!.authentication;

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
      Sentry.captureException(
        e,
        stackTrace: s,
      );

      return const SocialLoginResult();
    }
  }

  @override
  Future<void> logout() => _googleSignIn.signOut();
}

class AppleLogin implements SocialLogin {
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  @override
  Future<SocialLoginResult> login() async {
    try {
      final rawNonce = _generateNonce();
      // final nonce = _sha256ofString(rawNonce);

      final credential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName
          ],
          webAuthenticationOptions: WebAuthenticationOptions(
            clientId: Environment.appleClientId,
            redirectUri: Uri.parse(
              Environment.appleRedirectUri,
            ),
          ),
          state: rawNonce);
      return SocialLoginResult(
        idToken: credential.identityToken,
        accessToken: credential.authorizationCode,
        userData: {
          'email': credential.email,
          'name': '${credential.givenName} ${credential.familyName}',
        },
      );
    } catch (e, s) {
      logger.e('Apple login error: $e', stackTrace: s);
      return const SocialLoginResult();
    }
  }

  @override
  Future<void> logout() async {
    // Apple doesn't provide a logout method
  }
}

class KakaoLogin implements SocialLogin {
  Future<OAuthToken?> _tryLogin(Function loginMethod) async {
    try {
      return await loginMethod();
    } catch (e, s) {
      logger.e('Login failed $e', stackTrace: s);
      Sentry.captureException(
        e,
        stackTrace: s,
      );
      if (e is PlatformException && e.code == 'CANCELED') {
        return null;
      }
    }
    return null;
  }

  @override
  Future<SocialLoginResult> login() async {
    try {
      KakaoSdk.init(
          nativeAppKey: Environment.kakaoNativeAppKey,
          javaScriptAppKey: Environment.kakaoJavascriptKey);
      OAuthToken? token;

      logger.i('kIsWeb: $kIsWeb');

      if (kIsWeb) {
        await supabase.auth.signInWithOAuth(OAuthProvider.kakao);
        return const SocialLoginResult();
      } else {
        if (await isKakaoTalkInstalled()) {
          token = await _tryLogin(UserApi.instance.loginWithKakaoTalk);
        }

        token ??= await _tryLogin(UserApi.instance.loginWithKakaoAccount);

        if (token == null) {
          return const SocialLoginResult();
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
      }
    } catch (e, s) {
      logger.e('login error: $e', stackTrace: s);
      Sentry.captureException(
        e,
        stackTrace: s,
      );
      return const SocialLoginResult();
    }
  }

  @override
  Future<void> logout() => UserApi.instance.logout();
}

class AuthService {
  final Storage _storage = kIsWeb ? WebStorage() : SecureStorage();

  final Map<Supabase.OAuthProvider, SocialLogin> _loginProviders = {
    Supabase.OAuthProvider.google: kIsWeb
        ? GoogleLogin(GoogleSignIn(
            clientId:
                '853406219989-jrfkss5a0lqe5sq43t4uhm7n6i0g6s1b.apps.googleusercontent.com',
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
        throw Exception('not support provider: $provider');
      }

      final result = await socialLogin.login();
      if (result.idToken == null) {
        throw Exception('Failed to get ID token');
      }

      logger.i('idToken ${result.idToken}');
      final response = await supabase.auth.signInWithIdToken(
        provider: provider,
        idToken: result.idToken!,
      );

      if (response.user != null) {
        await _storeSession(response.session!, provider, result.idToken!);

        return response.user;
      } else {
        logger.e('Supabase login failed');
      }
    } catch (e, s) {
      logger.e('Error during sign in: $e', stackTrace: s);
      rethrow;
    }
    return null;
  }

  Future<void> signOut() async {
    // for (var socialLogin in _loginProviders.values) {
    //   await socialLogin.logout();
    // }
    await supabase.auth.signOut();
    // await _clearStoredSession();
  }

  Future<void> _storeSession(
      Session session, Supabase.OAuthProvider provider, String idToken) async {
    await _storage.write(
        key: 'supabase_access_token', value: session.accessToken);
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

      return await _recoverOAuthSession(Supabase.OAuthProvider.values
          .firstWhere((e) => e.name == lastProvider));
    } catch (e, s) {
      logger.e('Error during session recovery: $e', stackTrace: s);
      Sentry.captureException(
        e,
        stackTrace: s,
      );
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
        } else {
          logger
              .w('Re-authentication failed for $provider: No session returned');
        }
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
    await _storage.readAll().then((value) => logger.i(value));
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
      rethrow;
    }

    await _storage.readAll().then((value) => logger.i(value));
    logger.i('Stored session cleared');
  }

  Future<void> refreshToken() async {
    if (await NetworkCheck.isOnline()) {
      try {
        final response = await supabase.auth.refreshSession();
        logger.i(
            'Token refreshed successfully: ${response.session?.accessToken}');
      } catch (e, s) {
        logger.e('Token refresh failed: $e', stackTrace: s);
        rethrow; // 에러 처리 (예: 사용자에게 재로그인 요청)
      }
    } else {
      logger.w('Skipping token refresh due to offline status');
    }
  }
}
