import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/repositories/repository_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

part '../../generated/providers/config_service.g.dart';

class ConfigService {
  final ConfigRepository _configRepository;

  ConfigService(this._configRepository);

  Future<String?> getConfig(String key) async {
    try {
      final response = await _configRepository.getConfig(key);
      logger.i('Config fetched for key $key: $response');
      return response;
    } catch (e, s) {
      logger.e('Error fetching config: $e, $s');
      Sentry.captureException(
        e,
        stackTrace: s,
      );
      return null;
    }
  }

  Future<bool?> getBoolConfig(String key) async {
    try {
      return await _configRepository.getBoolConfig(key);
    } catch (e, s) {
      logger.e('Error fetching bool config: $e, $s');
      Sentry.captureException(e, stackTrace: s);
      return null;
    }
  }

  Future<int?> getIntConfig(String key) async {
    try {
      return await _configRepository.getIntConfig(key);
    } catch (e, s) {
      logger.e('Error fetching int config: $e, $s');
      Sentry.captureException(e, stackTrace: s);
      return null;
    }
  }

  Future<double?> getDoubleConfig(String key) async {
    try {
      return await _configRepository.getDoubleConfig(key);
    } catch (e, s) {
      logger.e('Error fetching double config: $e, $s');
      Sentry.captureException(e, stackTrace: s);
      return null;
    }
  }

  Future<Map<String, dynamic>?> getJsonConfig(String key) async {
    try {
      return await _configRepository.getJsonConfig(key);
    } catch (e, s) {
      logger.e('Error fetching JSON config: $e, $s');
      Sentry.captureException(e, stackTrace: s);
      return null;
    }
  }

  Future<Map<String, String>> getConfigsByPrefix(String prefix) async {
    try {
      return await _configRepository.getConfigsByPrefix(prefix);
    } catch (e, s) {
      logger.e('Error fetching configs by prefix: $e, $s');
      Sentry.captureException(e, stackTrace: s);
      return {};
    }
  }

  Future<void> setConfig(String key, String value) async {
    try {
      await _configRepository.setConfig(key, value);
      logger.i('Config set for key $key');
    } catch (e, s) {
      logger.e('Error setting config: $e, $s');
      Sentry.captureException(e, stackTrace: s);
      rethrow;
    }
  }

  Stream<String?> streamConfig(String key) {
    try {
      return _configRepository.streamConfig(key);
    } catch (e, s) {
      logger.e('Error streaming config: $e, $s');
      Sentry.captureException(e, stackTrace: s);
      return Stream.value(null);
    }
  }
}

@Riverpod(keepAlive: true)
ConfigService configService(Ref ref) {
  final configRepository = ref.watch(configRepositoryProvider);
  return ConfigService(configRepository);
}
