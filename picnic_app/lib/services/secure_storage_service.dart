import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:picnic_app/exceptions/auth_exception.dart';
import 'package:picnic_app/models/auth_token_info.dart';
import 'package:picnic_app/util/logger.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveTokenInfo(AuthTokenInfo tokenInfo) async {
    try {
      final jsonData = tokenInfo.toJson();
      await _storage.write(
        key: 'auth_token_info',
        value: jsonEncode(jsonData),
      );
      await _storage.write(
        key: 'last_provider',
        value: tokenInfo.provider.name,
      );
    } catch (e, s) {
      logger.e('Error saving token info', error: e, stackTrace: s);
      throw PicnicAuthExceptions.storageError();
    }
  }

  Future<AuthTokenInfo?> getTokenInfo() async {
    try {
      final jsonStr = await _storage.read(key: 'auth_token_info');
      if (jsonStr == null) return null;

      final jsonData = jsonDecode(jsonStr);
      return AuthTokenInfo.fromJson(jsonData);
    } catch (e, s) {
      logger.e('Error reading token info', error: e, stackTrace: s);
      return null;
    }
  }

  Future<void> clearTokenInfo() async {
    try {
      await _storage.delete(key: 'auth_token_info');
    } catch (e, s) {
      logger.e('Error clearing token info', error: e, stackTrace: s);
      throw PicnicAuthExceptions.storageError();
    }
  }
}
