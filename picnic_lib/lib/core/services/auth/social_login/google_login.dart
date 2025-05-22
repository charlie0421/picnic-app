import 'package:google_sign_in/google_sign_in.dart';
import 'package:picnic_lib/core/errors/auth_exception.dart';
import 'package:picnic_lib/core/services/auth/auth_service.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/common/social_login_result.dart';

class GoogleLogin implements SocialLogin {
  final GoogleSignIn _googleSignIn;

  GoogleLogin(this._googleSignIn);

  @override
  Future<SocialLoginResult> login() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      logger.d('Google Sign In attempt result: $googleUser'); // 수정된 로그

      if (googleUser == null) {
        logger.w('Google Sign In was canceled by user');
        throw PicnicAuthExceptions.canceled();
      }

      final googleAuth = await googleUser.authentication;
      logger.d('Google Auth completed successfully');

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
      await _googleSignIn.signOut();
    } catch (e, s) {
      logger.e('Google logout error', error: e, stackTrace: s);
      throw PicnicAuthExceptions.unknown(originalError: e);
    }
  }
}
