// secure_storage_service.dart

import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:picnic_app/util/logger.dart';
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
      logger.e('Error saving session to storage', error: e, stackTrace: s);
      rethrow;
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
