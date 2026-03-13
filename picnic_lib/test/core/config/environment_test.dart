import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:picnic_lib/core/config/environment.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testConfig = {
    'supabase': {
      'url': 'https://test.supabase.co',
      'anon_key': 'a' * 120, // > 100 chars
      'storage': {
        'url': 'https://storage.test.co',
        'anon_key': 'storage_key',
      },
    },
    'auth': {
      'apple': {
        'client_id': 'io.test.apple',
        'redirect_uri': 'https://test.co/callback',
      },
      'google': {
        'client_id': 'google_client_id',
        'server_client_id': 'google_server_id',
      },
      'kakao': {
        'native_app_key': 'kakao_native',
        'javascript_key': 'kakao_js',
      },
    },
    'sentry': {
      'enable': true,
      'app_dsn': 'https://sentry.test/app',
      'web_dsn': 'https://sentry.test/web',
      'sample_rates': {
        'trace': 0.5,
        'profile': 0.3,
        'session': 0.8,
        'error': 1.0,
      },
    },
    'storage': {
      'cdn_url': 'https://cdn.test.co',
      'aws': {
        'access_key_id': 'aws_key',
        'secret_access_key': 'aws_secret',
        'region': 'ap-northeast-2',
        's3_bucket': 'test-bucket',
        's3_bucket_url': 'https://s3.test.co',
      },
    },
    'api_keys': {
      'youtube': 'yt_key',
      'deepl': 'deepl_key',
      'branch': 'branch_key',
    },
    'app': {
      'web_domain': 'test.co',
      'download_link': 'https://dl.test.co',
      'app_link_prefix': 'https://link.test.co',
      'inapp_appname_prefix': 'io.test',
    },
    'theme': {
      'colors': {
        'primary': '0xFF6200EE',
        'secondary': '0xFF03DAC5',
        'sub': '0xFF018786',
        'point': '0xFFBB86FC',
        'point_900': '0xFF3700B3',
      },
    },
    'logging': {
      'level': 'debug',
      'image_load_warning_threshold_seconds': 15,
      'image_load_error_threshold_seconds': 25,
    },
    'ads': {
      'tapjoy': {
        'android_sdk_key': 'tapjoy_android',
        'ios_sdk_key': 'tapjoy_ios',
      },
      'pangle': {
        'ios_app_id': 'pangle_ios',
        'android_app_id': 'pangle_android',
        'ios_rewarded_video_id': 'pangle_ios_video',
        'android_rewarded_video_id': 'pangle_android_video',
      },
      'admob': {
        'ios_rewarded_video_id': 'admob_ios_video',
        'android_rewarded_video_id': 'admob_android_video',
      },
      'pincrux': {
        'android_app_key': 'pincrux_android',
        'ios_app_key': 'pincrux_ios',
      },
    },
  };

  setUp(() {
    // Mock rootBundle to return test config
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(
      'flutter/assets',
      (ByteData? message) async {
        // Decode the requested asset path
        final codec = const StringCodec();
        final requestedAsset = codec.decodeMessage(message!);

        if (requestedAsset == 'config/test.json') {
          return codec.encodeMessage(json.encode(testConfig));
        }
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
  });

  group('Environment initConfig and getters', () {
    setUp(() async {
      await Environment.initConfig('test');
    });

    test('currentEnvironment returns the set environment', () {
      expect(Environment.currentEnvironment, equals('test'));
    });

    test('supabaseUrl returns correct value', () {
      expect(Environment.supabaseUrl, equals('https://test.supabase.co'));
    });

    test('supabaseAnonKey returns correct value', () {
      expect(Environment.supabaseAnonKey.length, greaterThan(100));
    });

    test('supabaseStorageUrl returns correct value', () {
      expect(Environment.supabaseStorageUrl, equals('https://storage.test.co'));
    });

    test('auth getters return correct values', () {
      expect(Environment.appleClientId, equals('io.test.apple'));
      expect(
          Environment.appleRedirectUri, equals('https://test.co/callback'));
      expect(Environment.googleClientId, equals('google_client_id'));
      expect(Environment.googleServerClientId, equals('google_server_id'));
      expect(Environment.kakaoNativeAppKey, equals('kakao_native'));
      expect(Environment.kakaoJavascriptKey, equals('kakao_js'));
    });

    test('sentry getters return correct values', () {
      expect(Environment.enableSentry, isTrue);
      expect(Environment.sentryAppDsn, equals('https://sentry.test/app'));
      expect(Environment.sentryWebDsn, equals('https://sentry.test/web'));
      expect(Environment.sentryTraceSampleRate, equals(0.5));
      expect(Environment.sentryProfileSampleRate, equals(0.3));
      expect(Environment.sentrySessionSampleRate, equals(0.8));
      expect(Environment.sentryErrorSampleRate, equals(1.0));
    });

    test('storage getters return correct values', () {
      expect(Environment.cdnUrl, equals('https://cdn.test.co'));
      expect(Environment.awsAccessKey, equals('aws_key'));
      expect(Environment.awsSecretKey, equals('aws_secret'));
      expect(Environment.awsRegion, equals('ap-northeast-2'));
      expect(Environment.awsBucket, equals('test-bucket'));
      expect(Environment.awsS3Url, equals('https://s3.test.co'));
    });

    test('api key getters return correct values', () {
      expect(Environment.youtubeApiKey, equals('yt_key'));
      expect(Environment.deepLApiKey, equals('deepl_key'));
      expect(Environment.branchKey, equals('branch_key'));
    });

    test('app getters return correct values', () {
      expect(Environment.webDomain, equals('test.co'));
      expect(Environment.downloadLink, equals('https://dl.test.co'));
      expect(Environment.appLinkPrefix, equals('https://link.test.co'));
      expect(Environment.inappAppNamePrefix, equals('io.test'));
    });

    test('theme color getters return Color values', () {
      expect(Environment.primaryColor, isNotNull);
      expect(Environment.secondaryColor, isNotNull);
      expect(Environment.subColor, isNotNull);
      expect(Environment.pointColor, isNotNull);
      expect(Environment.point900Color, isNotNull);
    });

    test('logging getters return correct values', () {
      expect(Environment.imageLoadWarningThreshold, equals(15));
      expect(Environment.imageLoadErrorThreshold, equals(25));
    });

    test('logLevel returns correct level for debug', () {
      expect(Environment.logLevel, equals(Level.debug));
    });

    test('tapjoy getters return correct values', () {
      expect(Environment.tapjoyAndroidSdkKey, equals('tapjoy_android'));
      expect(Environment.tapjoyIosSdkKey, equals('tapjoy_ios'));
    });

    test('pangle getters return correct values', () {
      expect(Environment.pangleIosAppId, equals('pangle_ios'));
      expect(Environment.pangleAndroidAppId, equals('pangle_android'));
      expect(
          Environment.pangleIosRewardedVideoId, equals('pangle_ios_video'));
      expect(Environment.pangleAndroidRewardedVideoId,
          equals('pangle_android_video'));
    });

    test('admob getters return correct values', () {
      expect(Environment.admobIosRewardedVideoId, equals('admob_ios_video'));
      expect(Environment.admobAndroidRewardedVideoId,
          equals('admob_android_video'));
    });

    test('pincrux getters return correct values', () {
      expect(Environment.pincruxAndroidAppKey, equals('pincrux_android'));
      expect(Environment.pincruxIosAppKey, equals('pincrux_ios'));
    });
  });

  group('Environment logLevel parsing', () {
    Future<void> initWithLogLevel(String level, String envName) async {
      final config = Map<String, dynamic>.from(testConfig);
      config['logging'] = {'level': level};

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler(
        'flutter/assets',
        (ByteData? message) async {
          final codec = const StringCodec();
          final requestedAsset = codec.decodeMessage(message!);
          if (requestedAsset == 'config/$envName.json') {
            return codec.encodeMessage(json.encode(config));
          }
          return null;
        },
      );
      await Environment.initConfig(envName);
    }

    test('off level', () async {
      await initWithLogLevel('off', 'loglevel_off');
      expect(Environment.logLevel, equals(Level.off));
    });

    test('verbose level', () async {
      await initWithLogLevel('verbose', 'loglevel_verbose');
      expect(Environment.logLevel, equals(Level.trace));
    });

    test('info level', () async {
      await initWithLogLevel('info', 'loglevel_info');
      expect(Environment.logLevel, equals(Level.info));
    });

    test('warning level', () async {
      await initWithLogLevel('warning', 'loglevel_warning');
      expect(Environment.logLevel, equals(Level.warning));
    });

    test('error level', () async {
      await initWithLogLevel('error', 'loglevel_error');
      expect(Environment.logLevel, equals(Level.error));
    });

    test('all level', () async {
      await initWithLogLevel('all', 'loglevel_all');
      expect(Environment.logLevel, equals(Level.all));
    });

    test('unknown level defaults to info', () async {
      await initWithLogLevel('xyz', 'loglevel_unknown');
      expect(Environment.logLevel, equals(Level.info));
    });
  });

  group('Environment missing config fallbacks', () {
    final minConfig = {
      'supabase': {
        'url': 'https://min.supabase.co',
        'anon_key': 'b' * 120,
        'storage': {'url': 'https://s.co', 'anon_key': 'sk'},
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
      // no ads, no logging
    };

    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler(
        'flutter/assets',
        (ByteData? message) async {
          final codec = const StringCodec();
          final requestedAsset = codec.decodeMessage(message!);
          if (requestedAsset == 'config/minimal.json') {
            return codec.encodeMessage(json.encode(minConfig));
          }
          return null;
        },
      );
    });

    test('logLevel defaults to info when logging section missing', () async {
      await Environment.initConfig('minimal');
      expect(Environment.logLevel, equals(Level.info));
    });

    test('imageLoadWarningThreshold defaults to 10', () async {
      await Environment.initConfig('minimal');
      expect(Environment.imageLoadWarningThreshold, equals(10));
    });

    test('imageLoadErrorThreshold defaults to 20', () async {
      await Environment.initConfig('minimal');
      expect(Environment.imageLoadErrorThreshold, equals(20));
    });

    test('pangle returns null when config missing', () async {
      await Environment.initConfig('minimal');
      expect(Environment.pangleIosAppId, isNull);
      expect(Environment.pangleAndroidAppId, isNull);
      expect(Environment.pangleIosRewardedVideoId, isNull);
      expect(Environment.pangleAndroidRewardedVideoId, isNull);
    });

    test('admob returns null when config missing', () async {
      await Environment.initConfig('minimal');
      expect(Environment.admobIosRewardedVideoId, isNull);
      expect(Environment.admobAndroidRewardedVideoId, isNull);
    });

    test('pincrux returns null when config missing', () async {
      await Environment.initConfig('minimal');
      expect(Environment.pincruxAndroidAppKey, isNull);
      expect(Environment.pincruxIosAppKey, isNull);
    });

    test('tapjoy throws when config missing', () async {
      await Environment.initConfig('minimal');
      expect(() => Environment.tapjoyAndroidSdkKey, throwsException);
      expect(() => Environment.tapjoyIosSdkKey, throwsException);
    });
  });
}
