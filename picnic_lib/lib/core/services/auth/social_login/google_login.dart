import 'package:google_sign_in/google_sign_in.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:picnic_lib/core/errors/auth_exception.dart';
import 'package:picnic_lib/core/services/auth/auth_service.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/common/social_login_result.dart';
import 'package:picnic_lib/core/config/environment.dart';

class GoogleLogin implements SocialLogin {
  GoogleLogin();

  @override
  Future<SocialLoginResult> login() async {
    try {
      // google_sign_in 7.x API: singleton + initialize + authenticate
      // iOS는 Info.plist 설정을 사용하므로 clientId를 명시하지 않음
      await GoogleSignIn.instance.initialize(
        clientId: UniversalPlatform.isIOS ? null : Environment.googleClientId,
        serverClientId: Environment.googleServerClientId,
      );

      final account = await GoogleSignIn.instance.authenticate(
        scopeHint: const <String>['email', 'profile'],
      );
      logger.d('Google Sign In attempt result: $account');

      final googleAuth = account.authentication;
      logger.d('Google authentication tokens extracted');

      return SocialLoginResult(
        idToken: googleAuth.idToken,
        // google_sign_in 7.x는 accessToken 제공 방식이 변경됨 (clientAuthorization 등 사용)
        // Supabase는 idToken 기반 로그인만 필요하므로 accessToken은 생략 가능
        accessToken: null,
        userData: {
          'email': account.email,
          'name': account.displayName,
          'photoUrl': account.photoUrl,
        },
      );
    } catch (e, s) {
      // 수정된 에러 로깅
      logger.e('Google login error: ${e.toString()}', error: e, stackTrace: s);
      return Future.error(_handleGoogleLoginError(e));
    }
  }

  PicnicAuthException _handleGoogleLoginError(Object e) {
    if (e is PicnicAuthException) {
      switch (e.code) {
        case 'sign_in_canceled':
        case 'canceled':
          return PicnicAuthExceptions.canceled();
        case 'network_error':
          return PicnicAuthExceptions.network();
        default:
          return PicnicAuthExceptions.unknown(originalError: e);
      }
    }
    return PicnicAuthExceptions.unknown(originalError: e);
  }

  @override
  Future<void> logout() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (e, s) {
      logger.e('Google logout error', error: e, stackTrace: s);
      throw PicnicAuthExceptions.unknown(originalError: e);
    }
  }
}
