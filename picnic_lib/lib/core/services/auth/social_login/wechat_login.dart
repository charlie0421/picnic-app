// TODO: 위챗 로그인 임시 비활성화 - CI 에러 해결을 위해 전체 주석 처리
// 긴급 배포 완료 후 주석을 제거하고 fluwx 패키지 에러를 해결해야 함

/*
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:fluwx/fluwx.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/core/errors/auth_exception.dart';
import 'package:picnic_lib/core/services/auth/auth_service.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/common/social_login_result.dart';

class WeChatLogin implements SocialLogin {
  final Fluwx _fluwx = Fluwx();

  @override
  Future<SocialLoginResult> login() async {
    try {
      // Initialize WeChat SDK (API 문서: Fluwx().registerApi)
      await _fluwx.registerApi(
        appId: Environment.wechatAppId,
        universalLink: Environment.wechatUniversalLink,
      );

      // Check if WeChat is installed (API 문서: isWeChatInstalled)
      final isInstalled = await _fluwx.isWeChatInstalled;
      if (!isInstalled) {
        throw PicnicAuthExceptions.unsupportedProvider('WeChat not installed');
      }

      // Send auth request (API 문서: sendWeChatAuth)
      final success = await _fluwx.authBy(
        which: NormalAuth(scope: 'snsapi_userinfo', state: 'wechat_sdk_demo_test'),
      );

      logger.i('WeChat login success: $success');

      if (!success) {
        throw PicnicAuthExceptions.unknown();
      }

      // Listen for response
      final authResult = await _waitForWeChatResponse();

      if (authResult.errCode != 0 ||
          authResult.code == null ||
          authResult.code!.isEmpty) {
        throw PicnicAuthExceptions.unknown();
      }

      // In a real implementation, this should be done on the server side
      // For now, we'll create a basic result with the auth code
      return SocialLoginResult(
        idToken: authResult.code, // Using auth code as ID token temporarily
        accessToken:
            authResult.code, // Using auth code as access token temporarily
        userData: {
          'email': '', // WeChat doesn't provide email directly
          'name': 'WeChat User', // This should be fetched from server
          'photoUrl': '', // This should be fetched from server
          'code': authResult.code,
          'state': authResult.state ?? '',
        },
      );
    } catch (e, s) {
      logger.e('WeChat login error', error: e, stackTrace: s);
      return Future.error(_handleWeChatLoginError(e));
    }
  }

  Future<WeChatAuthResponse> _waitForWeChatResponse() async {
    try {
      // Set up response listener
      final completer = Completer<WeChatAuthResponse>();

      final subscription = _fluwx.addSubscriber(
        (response) {
          if (response is WeChatAuthResponse) {
            completer.complete(response);
          }
        },
      );

      // Wait for response (with timeout)
      return await completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          subscription.cancel();
          throw PicnicAuthExceptions.unknown();
        },
      );
    } catch (e, s) {
      logger.e('_waitForWeChatResponse', error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _exchangeCodeForToken(String code) async {
    // Note: In a real implementation, this should be done on the server side
    // for security reasons. The app secret should never be exposed in the client.
    // This is a simplified example for demonstration purposes.
    try {
      // This should be implemented as a server endpoint
      // For now, returning a mock response
      await Future.delayed(const Duration(milliseconds: 500));

      return {
        'access_token': 'mock_access_token_$code',
        'expires_in': 7200,
        'refresh_token': 'mock_refresh_token',
        'openid': 'mock_openid',
        'scope': 'snsapi_userinfo',
        'unionid': 'mock_unionid',
      };
    } catch (e, s) {
      logger.e('_exchangeCodeForToken', error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _getUserInfo(
      String accessToken, String openId) async {
    // Note: In a real implementation, this should be done on the server side
    // This is a simplified example for demonstration purposes.
    try {
      // This should be implemented as a server endpoint
      // For now, returning a mock response
      await Future.delayed(const Duration(milliseconds: 500));

      return {
        'openid': openId,
        'nickname': 'WeChat User',
        'sex': 1,
        'language': 'zh_CN',
        'city': 'Beijing',
        'province': 'Beijing',
        'country': 'CN',
        'headimgurl': 'https://thirdwx.qlogo.cn/mmopen/mock_avatar.jpg',
        'privilege': [],
        'unionid': 'mock_unionid',
      };
    } catch (e, s) {
      logger.e('_getUserInfo', error: e, stackTrace: s);
      rethrow;
    }
  }

  Never _handleWeChatLoginError(dynamic e) {
    if (e is PlatformException) {
      switch (e.code) {
        case 'CANCELLED':
        case 'USER_CANCELLED':
          throw PicnicAuthExceptions.canceled();
        case 'NOT_INSTALLED':
          throw PicnicAuthExceptions.unsupportedProvider(
              'WeChat not installed');
        default:
          if (e.message?.contains('network') ?? false) {
            throw PicnicAuthExceptions.network();
          }
          throw PicnicAuthExceptions.unknown(originalError: e);
      }
    }

    // Handle WeChatAuthResponse error codes
    if (e is WeChatAuthResponse) {
      switch (e.errCode) {
        case -4: // User cancelled
          throw PicnicAuthExceptions.canceled();
        case -2: // User denied
          throw PicnicAuthExceptions.canceled();
        case -1: // Common error
          throw PicnicAuthExceptions.unknown(originalError: e);
        default:
          throw PicnicAuthExceptions.unknown(originalError: e);
      }
    }

    throw PicnicAuthExceptions.unknown(originalError: e);
  }

  @override
  Future<void> logout() async {
    try {
      // WeChat doesn't have a specific logout method
      // Clear any stored WeChat tokens if needed
      logger.i('WeChat logout completed');
    } catch (e, s) {
      logger.e('WeChat logout error', error: e, stackTrace: s);
      throw PicnicAuthExceptions.unknown(originalError: e);
    }
  }
}
*/

// 임시 더미 클래스 - 컴파일 에러 방지용
import 'package:picnic_lib/core/services/auth/auth_service.dart';
import 'package:picnic_lib/core/errors/auth_exception.dart';
import 'package:picnic_lib/data/models/common/social_login_result.dart';

class WeChatLogin implements SocialLogin {
  @override
  Future<SocialLoginResult> login() async {
    throw PicnicAuthExceptions.unsupportedProvider(
        'WeChat login temporarily disabled');
  }

  @override
  Future<void> logout() async {
    // 위챗 로그인이 비활성화되어 있으므로 아무것도 하지 않음
  }
}
