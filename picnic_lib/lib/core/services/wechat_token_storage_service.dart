import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/wechat_token_info.dart';

class WeChatTokenStorageService {
  static const String _wechatTokenKey = 'wechat_token_info';
  static const String _wechatLastLoginKey = 'wechat_last_login';

  final FlutterSecureStorage _storage;

  WeChatTokenStorageService([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  /// Save WeChat token information securely
  Future<void> saveWeChatToken(WeChatTokenInfo tokenInfo) async {
    try {
      final tokenJson = tokenInfo.toJson();
      await _storage.write(
        key: _wechatTokenKey,
        value: jsonEncode(tokenJson),
      );

      // Also save the last login timestamp
      await _storage.write(
        key: _wechatLastLoginKey,
        value: DateTime.now().toIso8601String(),
      );

      logger.i('WeChat token saved successfully');
    } catch (e, s) {
      logger.e('Error saving WeChat token to storage', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Retrieve WeChat token information
  Future<WeChatTokenInfo?> getWeChatToken() async {
    try {
      final tokenStr = await _storage.read(key: _wechatTokenKey);
      if (tokenStr == null) {
        logger.i('No WeChat token found in storage');
        return null;
      }

      final tokenJson = jsonDecode(tokenStr) as Map<String, dynamic>;
      final tokenInfo = WeChatTokenInfo.fromJson(tokenJson);

      // Check if token is expired
      if (tokenInfo.isExpired) {
        logger.w('WeChat token is expired, removing from storage');
        await clearWeChatToken();
        return null;
      }

      return tokenInfo;
    } catch (e, s) {
      logger.e('Error reading WeChat token from storage',
          error: e, stackTrace: s);
      // If there's an error reading the token, clear it to prevent future issues
      await clearWeChatToken();
      return null;
    }
  }

  /// Update existing WeChat token with new access token and refresh token
  Future<void> updateWeChatToken({
    required String accessToken,
    required String refreshToken,
    required DateTime expiresAt,
  }) async {
    try {
      final existingToken = await getWeChatToken();
      if (existingToken == null) {
        logger.w('No existing WeChat token to update');
        return;
      }

      final updatedToken = existingToken.copyWithTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresAt: expiresAt,
      );

      await saveWeChatToken(updatedToken);
      logger.i('WeChat token updated successfully');
    } catch (e, s) {
      logger.e('Error updating WeChat token', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Check if WeChat token exists and is valid
  Future<bool> hasValidWeChatToken() async {
    try {
      final token = await getWeChatToken();
      return token != null && !token.isExpired;
    } catch (e, s) {
      logger.e('Error checking WeChat token validity', error: e, stackTrace: s);
      return false;
    }
  }

  /// Check if WeChat token will expire soon (within specified duration)
  Future<bool> willWeChatTokenExpireSoon([Duration? threshold]) async {
    try {
      final token = await getWeChatToken();
      if (token == null) return false;

      final checkThreshold = threshold ?? const Duration(minutes: 30);
      return token.willExpireWithin(checkThreshold);
    } catch (e, s) {
      logger.e('Error checking WeChat token expiration',
          error: e, stackTrace: s);
      return false;
    }
  }

  /// Get the last login timestamp
  Future<DateTime?> getLastLoginTime() async {
    try {
      final lastLoginStr = await _storage.read(key: _wechatLastLoginKey);
      if (lastLoginStr == null) return null;

      return DateTime.parse(lastLoginStr);
    } catch (e, s) {
      logger.e('Error reading last login time', error: e, stackTrace: s);
      return null;
    }
  }

  /// Clear WeChat token information
  Future<void> clearWeChatToken() async {
    try {
      await _storage.delete(key: _wechatTokenKey);
      await _storage.delete(key: _wechatLastLoginKey);
      logger.i('WeChat token cleared successfully');
    } catch (e, s) {
      logger.e('Error clearing WeChat token from storage',
          error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Get WeChat user information from stored token
  Future<Map<String, dynamic>?> getWeChatUserInfo() async {
    try {
      final token = await getWeChatToken();
      if (token == null) return null;

      return {
        'openId': token.openId,
        'unionId': token.unionId,
        'nickname': token.nickname,
        'headImgUrl': token.headImgUrl,
        'country': token.country,
        'province': token.province,
        'city': token.city,
        'language': token.language,
        'sex': token.sex,
      };
    } catch (e, s) {
      logger.e('Error getting WeChat user info', error: e, stackTrace: s);
      return null;
    }
  }

  /// Check if user has previously logged in with WeChat
  Future<bool> hasPreviousWeChatLogin() async {
    try {
      final lastLogin = await getLastLoginTime();
      return lastLogin != null;
    } catch (e, s) {
      logger.e('Error checking previous WeChat login', error: e, stackTrace: s);
      return false;
    }
  }

  /// Get storage statistics for debugging
  Future<Map<String, dynamic>> getStorageStats() async {
    try {
      final hasToken = await hasValidWeChatToken();
      final lastLogin = await getLastLoginTime();
      final token = await getWeChatToken();

      return {
        'hasValidToken': hasToken,
        'lastLoginTime': lastLogin?.toIso8601String(),
        'tokenExpiresAt': token?.expiresAt.toIso8601String(),
        'isExpired': token?.isExpired ?? false,
        'openId': token?.openId,
        'unionId': token?.unionId,
      };
    } catch (e, s) {
      logger.e('Error getting storage stats', error: e, stackTrace: s);
      return {'error': e.toString()};
    }
  }
}
