import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/core/utils/supabase_health_check.dart';

import '../../helpers/mock_supabase.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testConfig = {
    'supabase': {
      'url': 'https://test.supabase.co',
      'anon_key': 'a' * 120,
      'storage': {
        'url': 'https://storage.test.co',
        'anon_key': 'storage_key',
      },
    },
    'auth': {
      'apple': {'client_id': 'a', 'redirect_uri': 'r'},
      'google': {'client_id': 'g', 'server_client_id': 'gs'},
      'kakao': {'native_app_key': 'kn', 'javascript_key': 'kj'},
    },
    'sentry': {
      'enable': false,
      'app_dsn': 'd',
      'web_dsn': 'w',
      'sample_rates': {
        'trace': 0.0,
        'profile': 0.0,
        'session': 0.0,
        'error': 0.0,
      },
    },
    'storage': {
      'cdn_url': 'c',
      'aws': {
        'access_key_id': 'a',
        'secret_access_key': 's',
        'region': 'r',
        's3_bucket': 'b',
        's3_bucket_url': 'u',
      },
    },
    'api_keys': {'youtube': 'y', 'deepl': 'd', 'branch': 'b'},
    'app': {
      'web_domain': 'w',
      'download_link': 'd',
      'app_link_prefix': 'a',
      'inapp_appname_prefix': 'i',
    },
    'theme': {
      'colors': {
        'primary': '0xFF000000',
        'secondary': '0xFF000000',
        'sub': '0xFF000000',
        'point': '0xFF000000',
        'point_900': '0xFF000000',
      },
    },
    'logging': {'level': 'debug'},
    'ads': {
      'tapjoy': {
        'android_sdk_key': 'tj_android',
        'ios_sdk_key': 'tj_ios',
      },
    },
  };

  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(
      'flutter/assets',
      (ByteData? message) async {
        final codec = const StringCodec();
        final requestedAsset = codec.decodeMessage(message!);
        if (requestedAsset == 'config/test.json') {
          return codec.encodeMessage(json.encode(testConfig));
        }
        return null;
      },
    );
    await Environment.initConfig('test');
  });

  tearDown(() {
    tearDownMockSupabase();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
  });

  group('SupabaseHealthCheck', () {
    group('checkSupabaseHealth', () {
      test('returns true when products table query succeeds', () async {
        setupMockSupabase({
          'products': [
            {'id': 1},
          ],
        });

        final result = await SupabaseHealthCheck.checkSupabaseHealth();
        expect(result, isTrue);
      });

      test('returns true when products table returns empty list', () async {
        setupMockSupabase({
          'products': <Map<String, dynamic>>[],
        });

        final result = await SupabaseHealthCheck.checkSupabaseHealth();
        expect(result, isTrue);
      });

      test('returns true with multiple products', () async {
        setupMockSupabase({
          'products': [
            {'id': 1},
            {'id': 2},
            {'id': 3},
          ],
        });

        final result = await SupabaseHealthCheck.checkSupabaseHealth();
        expect(result, isTrue);
      });
    });

    group('checkSupabaseHealth - URL validation', () {
      test('returns false when URL does not start with https', () async {
        // Create a config with http:// instead of https://
        final badUrlConfig = Map<String, dynamic>.from(testConfig);
        badUrlConfig['supabase'] = Map<String, dynamic>.from(testConfig['supabase'] as Map);
        (badUrlConfig['supabase'] as Map)['url'] = 'http://test.supabase.co';

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler(
          'flutter/assets',
          (ByteData? message) async {
            final codec = const StringCodec();
            final requestedAsset = codec.decodeMessage(message!);
            if (requestedAsset == 'config/badurl.json') {
              return codec.encodeMessage(json.encode(badUrlConfig));
            }
            return null;
          },
        );
        await Environment.initConfig('badurl');

        setupMockSupabase({});

        final result = await SupabaseHealthCheck.checkSupabaseHealth();
        expect(result, isFalse);
      });

      test('returns false when anon key is too short', () async {
        final shortKeyConfig = Map<String, dynamic>.from(testConfig);
        shortKeyConfig['supabase'] = {
          'url': 'https://test.supabase.co',
          'anon_key': 'short_key', // < 100 chars
          'storage': {
            'url': 'https://storage.test.co',
            'anon_key': 'storage_key',
          },
        };

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler(
          'flutter/assets',
          (ByteData? message) async {
            final codec = const StringCodec();
            final requestedAsset = codec.decodeMessage(message!);
            if (requestedAsset == 'config/shortkey.json') {
              return codec.encodeMessage(json.encode(shortKeyConfig));
            }
            return null;
          },
        );
        await Environment.initConfig('shortkey');

        setupMockSupabase({});

        final result = await SupabaseHealthCheck.checkSupabaseHealth();
        expect(result, isFalse);
      });
    });

    group('runHealthCheckOnAppStart', () {
      test('completes successfully when health check passes', () async {
        setupMockSupabase({
          'products': [
            {'id': 1},
          ],
        });

        await expectLater(
          SupabaseHealthCheck.runHealthCheckOnAppStart(),
          completes,
        );
      });

      test('completes without error when health check fails', () async {
        // Use a bad URL to make health check fail
        final badUrlConfig = Map<String, dynamic>.from(testConfig);
        badUrlConfig['supabase'] = {
          'url': 'http://bad-url.co',
          'anon_key': 'a' * 120,
          'storage': {
            'url': 'https://storage.test.co',
            'anon_key': 'storage_key',
          },
        };

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler(
          'flutter/assets',
          (ByteData? message) async {
            final codec = const StringCodec();
            final requestedAsset = codec.decodeMessage(message!);
            if (requestedAsset == 'config/badurl2.json') {
              return codec.encodeMessage(json.encode(badUrlConfig));
            }
            return null;
          },
        );
        await Environment.initConfig('badurl2');

        setupMockSupabase({});

        // Should not throw even if health check fails
        await expectLater(
          SupabaseHealthCheck.runHealthCheckOnAppStart(),
          completes,
        );
      });
    });
  });
}
