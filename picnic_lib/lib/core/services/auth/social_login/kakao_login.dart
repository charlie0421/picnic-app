import 'package:flutter/services.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/core/errors/auth_exception.dart';
import 'package:picnic_lib/core/services/auth/auth_service.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/common/social_login_result.dart';

class KakaoLogin implements SocialLogin {
  @override
  Future<SocialLoginResult> login() async {
    try {
      KakaoSdk.init(
        nativeAppKey: Environment.kakaoNativeAppKey,
        javaScriptAppKey: Environment.kakaoJavascriptKey,
      );

      final token = await _performKakaoLogin();
      if (token == null) {
        throw PicnicAuthExceptions.unknown();
      }

      final user = await UserApi.instance.me();
      return SocialLoginResult(
        idToken: token.idToken,
        accessToken: token.accessToken,
        userData: {
          'email': user.kakaoAccount?.email ?? '',
          'name': user.kakaoAccount?.profile?.nickname ?? '',
          'photoUrl': user.kakaoAccount?.profile?.profileImageUrl ?? '',
        },
      );
    } catch (e, s) {
      logger.e('Kakao login error', error: e, stackTrace: s);
      return Future.error(_handleKakaoLoginError(e));
    }
  }

  Future<OAuthToken?> _performKakaoLogin() async {
    try {
      if (await isKakaoTalkInstalled()) {
        return await UserApi.instance.loginWithKakaoTalk();
      } else {
        return await UserApi.instance.loginWithKakaoAccount();
      }
    } catch (e, s) {
      logger.e('_performKakaoLogin', error: e, stackTrace: s);
      if (e is PlatformException && e.code == 'NotSupportError') {
        return await UserApi.instance.loginWithKakaoAccount();
      }
      rethrow;
    }
  }

  Never _handleKakaoLoginError(dynamic e) {
    if (e is PlatformException) {
      switch (e.code) {
        case 'CANCELED':
        case 'USER_CANCELLED':
          throw PicnicAuthExceptions.canceled();
        case 'NotSupportError':
          throw PicnicAuthExceptions.unsupportedProvider('KakaoTalk');
        default:
          if (e.message?.contains('network') ?? false) {
            throw PicnicAuthExceptions.network();
          }
          throw PicnicAuthExceptions.unknown(originalError: e);
      }
    }
    throw PicnicAuthExceptions.unknown(originalError: e);
  }

  @override
  Future<void> logout() async {
    try {
      await UserApi.instance.logout();
    } catch (e, s) {
      logger.e('Kakao logout error', error: e, stackTrace: s);
      throw PicnicAuthExceptions.unknown(originalError: e);
    }
  }
}
