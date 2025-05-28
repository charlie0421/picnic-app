import 'dart:async';
import 'dart:convert';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/core/errors/auth_exception.dart';
import 'package:picnic_lib/core/services/auth/social_login/apple_login.dart';
import 'package:picnic_lib/core/services/auth/social_login/google_login.dart';
import 'package:picnic_lib/core/services/auth/social_login/kakao_login.dart';
import 'package:picnic_lib/core/services/auth/social_login/wechat_login.dart';
import 'package:picnic_lib/core/services/device_manager.dart';
import 'package:picnic_lib/core/services/network_connectivity_service.dart';
import 'package:picnic_lib/core/services/secure_storage_service.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/common/social_login_result.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class SocialLogin {
  Future<SocialLoginResult> login();

  Future<void> logout();
}

class AuthTimeouts {
  const AuthTimeouts({
    this.networkCheck = const Duration(seconds: 5),
    this.sessionRecovery = const Duration(seconds: 10),
    this.tokenRefresh = const Duration(seconds: 8),
    this.tokenExpiration = const Duration(hours: 1),
  });

  final Duration networkCheck;
  final Duration sessionRecovery;
  final Duration tokenRefresh;
  final Duration tokenExpiration;
}

class AuthService {
  final SecureStorageService _storageService;
  final NetworkConnectivityService _networkService;
  final Map<supa.OAuthProvider, SocialLogin> _loginProviders;

  static const _timeouts = AuthTimeouts();
  final _sessionController = StreamController<Session?>.broadcast();

  AuthService({
    SecureStorageService? storageService,
    NetworkConnectivityService? networkService,
    Map<supa.OAuthProvider, SocialLogin>? loginProviders,
  })  : _storageService = storageService ?? SecureStorageService(),
        _networkService = networkService ?? NetworkConnectivityService(),
        _loginProviders = loginProviders ?? _createDefaultLoginProviders();

  static Map<supa.OAuthProvider, SocialLogin> _createDefaultLoginProviders() =>
      {
        supa.OAuthProvider.google: GoogleLogin(GoogleSignIn(
          clientId: Environment.googleClientId,
          serverClientId: Environment.googleServerClientId,
        )),
        supa.OAuthProvider.apple: AppleLogin(),
        supa.OAuthProvider.kakao: KakaoLogin(),
        // Note: WeChat is not in the standard OAuthProvider enum
        // We'll need to handle it separately or extend the enum
        // For now, we'll add a custom method for WeChat login
      };

  // WeChat login instance (separate from standard providers)
  late final WeChatLogin _wechatLogin = WeChatLogin();

  Future<bool> recoverSession() async {
    try {
      if (!await _networkService.checkOnlineStatus()) {
        logger.w('Cannot recover session - offline');
        return false;
      }

      final session = await _storageService.getSession();
      if (session == null) {
        logger.w('No stored session found');
        return false;
      }

      if (session.isExpired) {
        logger.w('Stored session is expired');
        await _storageService.clearSession();
        return false;
      }

      _sessionController.add(session);
      logger.i('Session recovered successfully');
      return true;
    } catch (e, s) {
      logger.e('Error recovering session', error: e, stackTrace: s);
      await _handleAuthError(e);
      return false;
    }
  }

  Future<User> signInWithProvider(supa.OAuthProvider provider) async {
    try {
      if (await DeviceManager.isDeviceBanned()) {
        throw PicnicAuthExceptions.deviceBanned();
      }

      final socialLogin = _loginProviders[provider];
      if (socialLogin == null) {
        throw PicnicAuthExceptions.unsupportedProvider(provider.name);
      }

      if (!await _networkService.checkOnlineStatus()) {
        throw PicnicAuthExceptions.network();
      }

      final result = await socialLogin.login();
      if (result.idToken == null) {
        throw PicnicAuthExceptions.invalidToken();
      }

      final response = await supabase.auth.signInWithIdToken(
        provider: provider,
        idToken: result.idToken!,
      );

      if (response.session == null || response.user == null) {
        throw PicnicAuthExceptions.invalidToken();
      }

      await DeviceManager.registerDevice(response.user!.id);

      await _saveAndNotifySession(response.session!);
      return response.user!;
    } catch (e, s) {
      logger.e('Error during sign in:', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// WeChat-specific login method
  /// Since WeChat is not a standard Supabase OAuth provider,
  /// we handle it separately with custom authentication flow
  Future<User> signInWithWeChat() async {
    try {
      if (await DeviceManager.isDeviceBanned()) {
        throw PicnicAuthExceptions.deviceBanned();
      }

      if (!await _networkService.checkOnlineStatus()) {
        throw PicnicAuthExceptions.network();
      }

      // Perform WeChat login
      final result = await _wechatLogin.login();
      if (result.idToken == null) {
        throw PicnicAuthExceptions.invalidToken();
      }

      // For WeChat, we need to create a custom authentication flow
      // This could involve:
      // 1. Creating a custom JWT token on your server
      // 2. Using Supabase's signInWithPassword with WeChat user data
      // 3. Or implementing a custom auth provider in Supabase

      // For now, we'll use a placeholder approach
      // TODO: Implement proper WeChat authentication with Supabase
      logger.w('WeChat authentication needs custom Supabase integration');

      // Temporary approach - you'll need to implement proper server-side integration
      // This is just a placeholder to demonstrate the flow
      throw PicnicAuthExceptions.unsupportedProvider(
          'WeChat authentication requires custom server integration');

      // Example of what the final implementation might look like:
      /*
      final response = await supabase.auth.signInWithPassword(
        email: 'wechat_${result.userData['openId']}@your-domain.com',
        password: 'secure_generated_password',
      );

      if (response.session == null || response.user == null) {
        throw PicnicAuthExceptions.invalidToken();
      }

      await DeviceManager.registerDevice(response.user!.id);
      await _saveAndNotifySession(response.session!);
      return response.user;
      */
    } catch (e, s) {
      logger.e('Error during WeChat sign in:', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Check if user has valid WeChat login
  Future<bool> hasValidWeChatLogin() async {
    try {
      return await _wechatLogin.isLoggedIn();
    } catch (e, s) {
      logger.e('Error checking WeChat login status', error: e, stackTrace: s);
      return false;
    }
  }

  /// Get WeChat user information
  Future<Map<String, dynamic>?> getWeChatUserInfo() async {
    try {
      return await _wechatLogin.getCurrentUserInfo();
    } catch (e, s) {
      logger.e('Error getting WeChat user info', error: e, stackTrace: s);
      return null;
    }
  }

  /// Refresh WeChat token if needed
  Future<bool> refreshWeChatToken() async {
    try {
      return await _wechatLogin.refreshTokenIfNeeded();
    } catch (e, s) {
      logger.e('Error refreshing WeChat token', error: e, stackTrace: s);
      return false;
    }
  }

  Future<bool> refreshSession() async {
    try {
      if (!await _networkService.checkOnlineStatus()) {
        logger.w('Cannot refresh session - offline');
        return false;
      }

      final session = await _storageService.getSession();
      if (session == null) {
        logger.w('No stored session found');
        return false;
      }

      final response =
          await supabase.auth.refreshSession().timeout(_timeouts.tokenRefresh);

      if (response.session != null) {
        await _saveAndNotifySession(response.session!);
        return true;
      }

      return false;
    } catch (e, s) {
      logger.e('Error refreshing session', error: e, stackTrace: s);
      await _handleAuthError(e);
      return false;
    }
  }

  // Private refresh method for internal use
  Future<bool> _refreshSession() => refreshSession();

  Future<void> signOut() async {
    try {
      final session = await _storageService.getSession();
      if (session != null) {
        final provider = _getProviderFromSession(session);
        await _logoutFromProvider(provider);
        await DeviceManager.updateLastSeen();
      }
      await _clearAuthState();
    } catch (e, s) {
      logger.e('Error during sign out', error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<void> _logoutFromProvider(supa.OAuthProvider provider) async {
    final socialLogin = _loginProviders[provider];
    if (socialLogin != null) {
      await socialLogin.logout();
      logger.i('Social provider logout successful: ${provider.name}');
    }
  }

  supa.OAuthProvider _getProviderFromSession(Session session) {
    try {
      final jwt = session.accessToken;
      final parts = jwt.split('.');
      if (parts.length != 3) throw const FormatException('Invalid JWT format');

      final payload =
          String.fromCharCodes(base64Url.decode(base64Url.normalize(parts[1])));
      final data = jsonDecode(payload);

      final provider = data['provider'] as String?;
      return _parseProvider(provider);
    } catch (e, s) {
      logger.e('Error extracting provider from session',
          error: e, stackTrace: s);
      return supa.OAuthProvider.google; // 기본값 반환
    }
  }

  supa.OAuthProvider _parseProvider(String? provider) {
    switch (provider?.toLowerCase()) {
      case 'google':
        return supa.OAuthProvider.google;
      case 'apple':
        return supa.OAuthProvider.apple;
      case 'kakao':
        return supa.OAuthProvider.kakao;
      default:
        return supa.OAuthProvider.google;
    }
  }

  Future<void> _handleAuthError(dynamic error) async {
    logger.e('Handling auth error: $error');
    if (_shouldClearSession(error)) {
      await _clearAuthState();
    }
  }

  bool _shouldClearSession(dynamic error) {
    return error is TimeoutException ||
        (error is AuthException &&
            (error.message.contains('Token expired') ||
                error.statusCode == "401"));
  }

  Future<void> _saveAndNotifySession(Session session) async {
    await _storageService.saveSession(session);
    _sessionController.add(session);
  }

  Future<void> _clearAuthState() async {
    await supabase.auth.signOut();
    await _storageService.clearSession();
    _sessionController.add(null);
    logger.i('Auth state cleared');
  }

  Stream<Session?> get sessionStream => _sessionController.stream;

  Future<void> dispose() async {
    await _sessionController.close();
  }
}
