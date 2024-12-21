import 'dart:math';

import 'package:picnic_app/config/environment.dart';
import 'package:picnic_app/exceptions/auth_exception.dart';
import 'package:picnic_app/models/common/social_login_result.dart';
import 'package:picnic_app/services/auth/auth_service.dart';
import 'package:picnic_app/util/logger.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

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
        state: rawNonce,
      );

      if (credential.identityToken == null) {
        throw PicnicAuthExceptions.invalidToken();
      }

      // 이름 처리 로직 개선
      final fullName = [
        credential.givenName,
        credential.familyName,
      ].where((name) => name != null && name.isNotEmpty).join(' ');

      return SocialLoginResult(
        idToken: credential.identityToken,
        accessToken: credential.authorizationCode,
        userData: {
          'email': credential.email,
          'name': fullName.isEmpty ? null : fullName,
        },
      );
    } catch (e, s) {
      logger.e('Apple login error', error: e, stackTrace: s);
      throw _handleAppleLoginError(e); // throw로 수정
    }
  }

  Never _handleAppleLoginError(dynamic e) {
    if (e is SignInWithAppleAuthorizationException) {
      switch (e.code) {
        case AuthorizationErrorCode.canceled:
          throw PicnicAuthExceptions.canceled();
        case AuthorizationErrorCode.failed:
          throw PicnicAuthExceptions.invalidToken();
        case AuthorizationErrorCode.invalidResponse:
          throw PicnicAuthExceptions.invalidToken();
        default:
          throw PicnicAuthExceptions.unknown(originalError: e);
      }
    }
    throw PicnicAuthExceptions.unknown(originalError: e);
  }

  @override
  Future<void> logout() async {
    // Apple doesn't provide a logout method
  }
}
