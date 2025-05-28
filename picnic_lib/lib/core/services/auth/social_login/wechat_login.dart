import 'dart:async';
import 'package:flutter/services.dart';
import 'package:fluwx/fluwx.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/core/errors/auth_exception.dart';
import 'package:picnic_lib/core/services/auth/auth_service.dart';
import 'package:picnic_lib/core/services/wechat_token_storage_service.dart';
import 'package:picnic_lib/core/utils/china_network_simulator.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/common/social_login_result.dart';
import 'package:picnic_lib/data/models/wechat_token_info.dart';

class WeChatLogin implements SocialLogin {
  final WeChatTokenStorageService _tokenStorage;

  WeChatLogin({WeChatTokenStorageService? tokenStorage})
      : _tokenStorage = tokenStorage ?? WeChatTokenStorageService();

  @override
  Future<SocialLoginResult> login() async {
    try {
      // Test WeChat connectivity in China network simulation
      if (ChinaNetworkSimulator.isEnabled) {
        final isConnected =
            await ChinaNetworkSimulator.testWeChatConnectivity();
        if (!isConnected) {
          throw PicnicAuthExceptions.network();
        }
      }

      // Initialize WeChat SDK with China network simulation
      await ChinaNetworkSimulator.simulateChinaMobileNetwork(() async {
        await registerWxApi(
          appId: Environment.wechatAppId,
          universalLink: Environment.wechatUniversalLink,
        );
      });

      // Check if WeChat is installed
      final isInstalled = await isWeChatInstalled;
      if (!isInstalled) {
        throw PicnicAuthExceptions.unsupportedProvider('WeChat not installed');
      }

      // Check if we have a valid existing token
      final existingToken = await _tokenStorage.getWeChatToken();
      if (existingToken != null && !existingToken.isExpired) {
        logger.i('Using existing valid WeChat token');
        return _createSocialLoginResult(existingToken);
      }

      // Perform WeChat login with China network simulation
      final authResult =
          await ChinaNetworkSimulator.simulateChinaMobileNetwork(() async {
        return await _performWeChatLogin();
      });

      if (authResult.errCode != 0 ||
          authResult.code == null ||
          authResult.code!.isEmpty) {
        throw PicnicAuthExceptions.unknown();
      }

      // Exchange auth code for access token (server-side implementation needed)
      final tokenResponse =
          await ChinaNetworkSimulator.simulateChinaMobileNetwork(() async {
        return await _exchangeCodeForToken(authResult.code!);
      });

      // Get user information (server-side implementation needed)
      final userInfo =
          await ChinaNetworkSimulator.simulateChinaMobileNetwork(() async {
        return await _getUserInfo(
          tokenResponse['access_token'] as String,
          tokenResponse['openid'] as String,
        );
      });

      // Create and save token info
      final wechatTokenInfo = WeChatTokenInfo.fromWeChatResponse(
        tokenResponse: tokenResponse,
        userInfo: userInfo,
      );

      await _tokenStorage.saveWeChatToken(wechatTokenInfo);
      logger.i('WeChat token saved successfully');

      return _createSocialLoginResult(wechatTokenInfo);
    } catch (e, s) {
      logger.e('WeChat login error', error: e, stackTrace: s);
      return Future.error(_handleWeChatLoginError(e));
    }
  }

  /// Create SocialLoginResult from WeChatTokenInfo
  SocialLoginResult _createSocialLoginResult(WeChatTokenInfo tokenInfo) {
    return SocialLoginResult(
      idToken: tokenInfo.accessToken, // Using access token as ID token for now
      accessToken: tokenInfo.accessToken,
      userData: {
        'email': '', // WeChat doesn't provide email directly
        'name': tokenInfo.nickname ?? 'WeChat User',
        'photoUrl': tokenInfo.headImgUrl ?? '',
        'openId': tokenInfo.openId,
        'unionId': tokenInfo.unionId,
        'country': tokenInfo.country ?? '',
        'province': tokenInfo.province ?? '',
        'city': tokenInfo.city ?? '',
        'language': tokenInfo.language ?? '',
        'sex': tokenInfo.sex ?? 0,
      },
    );
  }

  Future<WeChatAuthResponse> _performWeChatLogin() async {
    try {
      // Set up response listener
      final completer = Completer<WeChatAuthResponse>();
      StreamSubscription? subscription;

      subscription = weChatResponseEventHandler.listen((response) {
        if (response is WeChatAuthResponse) {
          subscription?.cancel();
          completer.complete(response);
        }
      });

      // Send auth request
      final success = await sendWeChatAuth(
        scope: "snsapi_userinfo",
        state: "wechat_sdk_demo_test",
      );

      if (!success) {
        subscription.cancel();
        throw PicnicAuthExceptions.unknown();
      }

      // Wait for response (with timeout)
      return await completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          subscription?.cancel();
          throw PicnicAuthExceptions.unknown();
        },
      );
    } catch (e, s) {
      logger.e('_performWeChatLogin', error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _exchangeCodeForToken(String code) async {
    // TODO: Implement server-side token exchange
    // This should call your backend API endpoint that securely exchanges
    // the auth code for access token using WeChat's API
    //
    // Example endpoint: POST /api/auth/wechat/exchange
    // Body: { "code": "auth_code_from_wechat" }
    // Response: { "access_token": "...", "refresh_token": "...", "openid": "...", ... }

    try {
      logger.w('Using mock token exchange - implement server endpoint!');

      // Mock response for development - REMOVE IN PRODUCTION
      await Future.delayed(const Duration(milliseconds: 500));

      return {
        'access_token': 'mock_access_token_$code',
        'expires_in': 7200, // 2 hours
        'refresh_token': 'mock_refresh_token_$code',
        'openid': 'mock_openid_${DateTime.now().millisecondsSinceEpoch}',
        'scope': 'snsapi_userinfo',
        'unionid': 'mock_unionid_${DateTime.now().millisecondsSinceEpoch}',
      };
    } catch (e, s) {
      logger.e('_exchangeCodeForToken', error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _getUserInfo(
      String accessToken, String openId) async {
    // TODO: Implement server-side user info retrieval
    // This should call your backend API endpoint that securely fetches
    // user information from WeChat's API using the access token
    //
    // Example endpoint: GET /api/auth/wechat/userinfo?access_token=...&openid=...
    // Response: { "nickname": "...", "headimgurl": "...", "country": "...", ... }

    try {
      logger.w('Using mock user info - implement server endpoint!');

      // Mock response for development - REMOVE IN PRODUCTION
      await Future.delayed(const Duration(milliseconds: 500));

      return {
        'openid': openId,
        'nickname': 'WeChat User ${DateTime.now().millisecondsSinceEpoch}',
        'sex': 1,
        'language': 'zh_CN',
        'city': 'Beijing',
        'province': 'Beijing',
        'country': 'CN',
        'headimgurl':
            'https://thirdwx.qlogo.cn/mmopen/mock_avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
        'privilege': [],
        'unionid': 'mock_unionid_${DateTime.now().millisecondsSinceEpoch}',
      };
    } catch (e, s) {
      logger.e('_getUserInfo', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Refresh WeChat access token if needed
  Future<bool> refreshTokenIfNeeded() async {
    try {
      final tokenInfo = await _tokenStorage.getWeChatToken();
      if (tokenInfo == null) {
        logger.i('No WeChat token to refresh');
        return false;
      }

      // Check if token will expire soon (within 30 minutes)
      if (!tokenInfo.willExpireWithin(const Duration(minutes: 30))) {
        logger.i('WeChat token is still valid, no refresh needed');
        return true;
      }

      logger.i('WeChat token will expire soon, attempting refresh...');

      // TODO: Implement server-side token refresh
      // This should call your backend API endpoint that uses the refresh token
      // to get a new access token from WeChat's API
      //
      // Example endpoint: POST /api/auth/wechat/refresh
      // Body: { "refresh_token": "..." }
      // Response: { "access_token": "...", "expires_in": 7200 }

      // Mock refresh for development - REMOVE IN PRODUCTION
      await ChinaNetworkSimulator.simulateChinaMobileNetwork(() async {
        await Future.delayed(const Duration(milliseconds: 300));
      });

      final newExpiresAt = DateTime.now().add(const Duration(hours: 2));
      await _tokenStorage.updateWeChatToken(
        accessToken: 'refreshed_${tokenInfo.accessToken}',
        refreshToken: tokenInfo.refreshToken,
        expiresAt: newExpiresAt,
      );

      logger.i('WeChat token refreshed successfully');
      return true;
    } catch (e, s) {
      logger.e('Error refreshing WeChat token', error: e, stackTrace: s);
      return false;
    }
  }

  /// Get current WeChat user info from storage
  Future<Map<String, dynamic>?> getCurrentUserInfo() async {
    return await _tokenStorage.getWeChatUserInfo();
  }

  /// Check if user has valid WeChat login
  Future<bool> isLoggedIn() async {
    return await _tokenStorage.hasValidWeChatToken();
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
      // Clear stored WeChat tokens
      await _tokenStorage.clearWeChatToken();

      // WeChat doesn't have a specific logout method in the SDK
      // The logout is handled by clearing the stored tokens
      logger.i('WeChat logout completed - tokens cleared');
    } catch (e, s) {
      logger.e('WeChat logout error', error: e, stackTrace: s);
      throw PicnicAuthExceptions.unknown(originalError: e);
    }
  }
}
