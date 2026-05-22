// secure_storage_service.dart

import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SecureStorageService {
  static const _sessionKey = 'session';
  final FlutterSecureStorage _storage;

  SecureStorageService([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveSession(Session session) async {
    try {
      final sessionJson = session.toJson();
      await _storage.write(
        key: _sessionKey,
        value: jsonEncode(sessionJson),
      );
    } catch (e, s) {
      // Android Keystore 가 일부 단말 (HUAWEI 등) 에서 NPE/PlatformException 을 throw
      // (PICNIC-APP-58P). SecureStorage 는 SDK 의 SharedPreferences-기반
      // currentSession 의 backup 일 뿐이라, write 실패로 로그인 흐름을 깰 이유가 없다.
      // 다음 cold start 시 recoverSession() 이 SDK session 으로 복구한다.
      logger.w('Failed to persist session to secure storage; SDK session is primary',
          error: e, stackTrace: s);
    }
  }

  Future<Session?> getSession() async {
    try {
      final sessionStr = await _storage.read(key: _sessionKey);
      if (sessionStr == null) return null;

      final sessionJson = jsonDecode(sessionStr);
      return Session.fromJson(sessionJson);
    } catch (e, s) {
      logger.e('Error reading session from storage', error: e, stackTrace: s);
      return null;
    }
  }

  Future<void> clearSession() async {
    try {
      await _storage.delete(key: _sessionKey);
    } catch (e, s) {
      logger.e('Error clearing session from storage', error: e, stackTrace: s);
      rethrow;
    }
  }
}
