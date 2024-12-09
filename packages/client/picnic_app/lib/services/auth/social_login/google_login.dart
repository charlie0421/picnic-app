import 'package:google_sign_in/google_sign_in.dart';
import 'package:picnic_app/exceptions/auth_exception.dart';
import 'package:picnic_app/models/common/social_login_result.dart';
import 'package:picnic_app/services/auth/auth_service.dart';
import 'package:picnic_app/util/logger.dart';

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
      logger.e('Google login error', error: e, stackTrace: s);
      throw _handleGoogleLoginError(e);
    }
  }

  _handleGoogleLoginError(dynamic e) {
    // Never 반환 타입 명시
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
