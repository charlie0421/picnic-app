import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as Supabase;
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class SocialLogin {
  Future<SocialLoginResult> login();
  Future<void> logout();
}

class SocialLoginResult {
  final String? idToken;
  final String? accessToken;
  final Map<String, dynamic>? userData;

  SocialLoginResult({this.idToken, this.accessToken, this.userData});
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
    } catch (e) {
      logger.e('Google login error: $e');
      return SocialLoginResult();
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
      final nonce = _sha256ofString(rawNonce);

      final credential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName
          ],
          webAuthenticationOptions: WebAuthenticationOptions(
            clientId: const String.fromEnvironment('APPLE_CLIENT_ID',
                defaultValue: 'io.iconcasting.picnic.app.apple'),
            redirectUri: Uri.parse(const String.fromEnvironment(
                'APPLE_REDIRECT_URI',
                defaultValue: 'https://api.picnic.fan/auth/v1/callback')),
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
    } catch (e) {
      print('Apple login error: $e');
      return SocialLoginResult();
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
    } catch (error) {
      print('Login failed $error');
      if (error is PlatformException && error.code == 'CANCELED') {
        return null;
      }
    }
    return null;
  }

  @override
  Future<SocialLoginResult> login() async {
    try {
      KakaoSdk.init(
          nativeAppKey: const String.fromEnvironment('KAKAO_NATIVE_APP_KEY',
              defaultValue: '75e247f5d29512f84749e64aac77ebfa'),
          javaScriptAppKey: const String.fromEnvironment('KAKAO_JS_APP_KEY',
              defaultValue: 'fe170eb02c6ff6a488a5848f9db41335'));
      OAuthToken? token;

      if (await isKakaoTalkInstalled()) {
        token = await _tryLogin(UserApi.instance.loginWithKakaoTalk);
      }

      token ??= await _tryLogin(UserApi.instance.loginWithKakaoAccount);

      if (token == null) {
        return SocialLoginResult();
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
    } catch (e) {
      print('login error: $e');
      return SocialLoginResult();
    }
  }

  @override
  Future<void> logout() => UserApi.instance.logout();
}

class AuthService {
  final Map<Supabase.OAuthProvider, SocialLogin> _loginProviders = {
    Supabase.OAuthProvider.google: GoogleLogin(GoogleSignIn(
        clientId: const String.fromEnvironment('GOOGLE_CLIENT_ID',
            defaultValue:
                '853406219989-ntnler0e2qe0gfheh3qdjt3k2h4kpvj4.apps.googleusercontent.com'),
        serverClientId: const String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID',
            defaultValue:
                '853406219989-jrfkss5a0lqe5sq43t4uhm7n6i0g6s1b.apps.googleusercontent.com'))),
    Supabase.OAuthProvider.apple: AppleLogin(),
    Supabase.OAuthProvider.kakao: KakaoLogin(),
  };

  Future<Supabase.User?> signInWithProvider(
      Supabase.OAuthProvider provider) async {
    try {
      final socialLogin = _loginProviders[provider];
      if (socialLogin == null) {
        throw Exception('Unsupported provider');
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
    } catch (e) {
      logger.e('Error during sign in: $e');
    }
    return null;
  }

  Future<void> signOut() async {
    // for (var socialLogin in _loginProviders.values) {
    //   await socialLogin.logout();
    // }
    await supabase.auth.signOut();
    await _clearStoredSession();
  }

  Future<void> _storeSession(
      Session session, Supabase.OAuthProvider provider, String idToken) async {
    const storage = FlutterSecureStorage();
    await storage.write(
        key: 'supabase_access_token', value: session.accessToken);
    await storage.write(key: 'last_provider', value: provider.name);
    await storage.write(
        key: '${provider.name.toLowerCase()}_id_token', value: idToken);
  }

  Future<bool> recoverSession() async {
    try {
      const storage = FlutterSecureStorage();
      final lastProvider = await storage.read(key: 'last_provider');

      if (lastProvider == null) {
        logger.w('No last provider found in storage');
        return false;
      }

      return await _recoverOAuthSession(Supabase.OAuthProvider.values
          .firstWhere((e) => e.name == lastProvider));
    } catch (e, s) {
      logger.e('Error during session recovery: $e', stackTrace: s);
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
      } catch (e) {
        logger.e('Error during OAuth re-authentication for $provider: $e');
      }
    } else {
      logger.w('No ID token found in storage for $provider');
    }

    return false;
  }

  Future<void> _clearStoredSession() async {
    const storage = FlutterSecureStorage();
    await storage.readAll().then((value) => logger.i(value));
    try {
      final allValues = await storage.readAll();
      logger.i('Before clearing: $allValues');

      for (var entry in allValues.entries) {
        if (entry.key != 'last_provider') {
          await storage.delete(key: entry.key);
        }
      }

      final remainingValues = await storage.readAll();
      logger.i('After clearing: $remainingValues');
      logger.i('Stored session cleared except last_provider');
    } catch (e) {
      logger.e('Error while clearing storage: $e');
    }

    await storage.readAll().then((value) => logger.i(value));
    logger.i('Stored session cleared');
  }
}
