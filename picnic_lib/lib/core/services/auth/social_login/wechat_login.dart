import 'dart:async';
import 'package:flutter/services.dart';
import 'package:fluwx/fluwx.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/core/errors/auth_exception.dart';
import 'package:picnic_lib/core/services/auth/auth_service.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/common/social_login_result.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WeChatLogin implements SocialLogin {
  final Fluwx _fluwx = Fluwx();

  @override
  Future<SocialLoginResult> login() async {
    try {
      await _fluwx.registerApi(
        appId: Environment.wechatAppId,
        universalLink: Environment.wechatUniversalLink,
      );

      final isInstalled = await _fluwx.isWeChatInstalled;
      if (!isInstalled) {
        throw PicnicAuthExceptions.unsupportedProvider('WeChat not installed');
      }

      final success = await _fluwx.authBy(
        which:
            NormalAuth(scope: 'snsapi_userinfo', state: 'picnic_wechat_login'),
      );

      logger.i('WeChat login request sent: $success');
      if (!success) {
        throw PicnicAuthExceptions.unknown();
      }

      final authResult = await _waitForWeChatResponse();
      if (authResult.errCode != 0 ||
          authResult.code == null ||
          authResult.code!.isEmpty) {
        throw PicnicAuthExceptions.unknown();
      }

      final uri = Uri.parse(
          '${Environment.supabaseUrl.replaceAll('/rest/v1', '')}/functions/v1/wechat-login');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'apikey': Environment.supabaseAnonKey,
          'Authorization': 'Bearer ${Environment.supabaseAnonKey}',
        },
        body: jsonEncode({
          'code': authResult.code,
          'app_id': Environment.wechatAppId,
          'app_secret': Environment.wechatAppSecret,
        }),
      );

      if (response.statusCode != 200) {
        logger.e('wechat-login error: ${response.statusCode} ${response.body}');
        throw PicnicAuthExceptions.unknown();
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final email = data['email'] as String?;
      final otp = data['otp'] as String?;
      if (email == null || otp == null) {
        throw PicnicAuthExceptions.invalidToken();
      }

      return SocialLoginResult(
        idToken: null,
        accessToken: null,
        userData: {
          'email': email,
          'otp': otp,
        },
      );
    } catch (e, s) {
      logger.e('WeChat login error', error: e, stackTrace: s);
      return Future.error(_handleWeChatLoginError(e));
    }
  }

  Future<WeChatAuthResponse> _waitForWeChatResponse() async {
    try {
      final completer = Completer<WeChatAuthResponse>();
      final subscription = _fluwx.addSubscriber((response) {
        if (response is WeChatAuthResponse) {
          completer.complete(response);
        }
      });
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
    if (e is WeChatAuthResponse) {
      switch (e.errCode) {
        case -4:
          throw PicnicAuthExceptions.canceled();
        case -2:
          throw PicnicAuthExceptions.canceled();
        case -1:
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
      logger.i('WeChat logout completed');
    } catch (e, s) {
      logger.e('WeChat logout error', error: e, stackTrace: s);
      throw PicnicAuthExceptions.unknown(originalError: e);
    }
  }
}
