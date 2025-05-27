import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

class Environment {
  static late Map<String, dynamic> _config;
  static late String _currentEnvironment;

  static Future<void> initConfig(String env) async {
    _currentEnvironment = env;
    final configString = await rootBundle.loadString('config/$env.json');
    _config = json.decode(configString) as Map<String, dynamic>;
  }

  static String get currentEnvironment => _currentEnvironment;

  // 중첩된 설정값을 가져오는 헬퍼 메서드
  static dynamic _getValue(List<String> path) {
    dynamic current = _config;
    for (final key in path) {
      if (current is! Map<String, dynamic> || !current.containsKey(key)) {
        throw Exception('설정 경로를 찾을 수 없습니다: ${path.join(".")}');
      }
      current = current[key];
    }
    return current;
  }

  // 설정값을 가져오되, 없으면 기본값 사용
  static dynamic _getValueOrDefault(List<String> path, dynamic defaultValue) {
    try {
      return _getValue(path);
    } catch (e) {
      return defaultValue;
    }
  }

  // 로그 관련 설정
  static Level get logLevel {
    final levelName = _getValueOrDefault(['logging', 'level'], 'info')
        .toString()
        .toLowerCase();
    switch (levelName) {
      case 'off':
        return Level.off;
      case 'verbose':
        return Level.verbose;
      case 'debug':
        return Level.debug;
      case 'info':
        return Level.info;
      case 'warning':
        return Level.warning;
      case 'error':
        return Level.error;
      case 'all':
        return Level.all;
      default:
        return Level.info;
    }
  }

  static int get imageLoadWarningThreshold => _getValueOrDefault(
      ['logging', 'image_load_warning_threshold_seconds'], 10) as int;

  static int get imageLoadErrorThreshold =>
      _getValueOrDefault(['logging', 'image_load_error_threshold_seconds'], 20)
          as int;

  // Supabase 관련 설정
  static String get supabaseUrl => _getValue(['supabase', 'url']) as String;
  static String get supabaseAnonKey =>
      _getValue(['supabase', 'anon_key']) as String;
  static String get supabaseStorageUrl =>
      _getValue(['supabase', 'storage', 'url']) as String;
  static String get supabaseStorageAnonKey =>
      _getValue(['supabase', 'storage', 'anon_key']) as String;

  // Auth 관련 설정
  static String get appleClientId =>
      _getValue(['auth', 'apple', 'client_id']) as String;
  static String get appleRedirectUri =>
      _getValue(['auth', 'apple', 'redirect_uri']) as String;
  static String get googleClientId =>
      _getValue(['auth', 'google', 'client_id']) as String;
  static String get googleServerClientId =>
      _getValue(['auth', 'google', 'server_client_id']) as String;
  static String get kakaoNativeAppKey =>
      _getValue(['auth', 'kakao', 'native_app_key']) as String;
  static String get kakaoJavascriptKey =>
      _getValue(['auth', 'kakao', 'javascript_key']) as String;
  static String get wechatAppId =>
      _getValue(['auth', 'wechat', 'app_id']) as String;
  static String get wechatAppSecret =>
      _getValue(['auth', 'wechat', 'app_secret']) as String;
  static String get wechatUniversalLink =>
      _getValue(['auth', 'wechat', 'universal_link']) as String;

  // Sentry 관련 설정
  static bool get enableSentry => _getValue(['sentry', 'enable']) as bool;
  static String get sentryAppDsn => _getValue(['sentry', 'app_dsn']) as String;
  static String get sentryWebDsn => _getValue(['sentry', 'web_dsn']) as String;
  static double get sentryTraceSampleRate =>
      _getValue(['sentry', 'sample_rates', 'trace']) as double;
  static double get sentryProfileSampleRate =>
      _getValue(['sentry', 'sample_rates', 'profile']) as double;
  static double get sentrySessionSampleRate =>
      _getValue(['sentry', 'sample_rates', 'session']) as double;
  static double get sentryErrorSampleRate =>
      _getValue(['sentry', 'sample_rates', 'error']) as double;

  // Storage 관련 설정
  static String get cdnUrl => _getValue(['storage', 'cdn_url']) as String;
  static String get awsAccessKey =>
      _getValue(['storage', 'aws', 'access_key_id']) as String;
  static String get awsSecretKey =>
      _getValue(['storage', 'aws', 'secret_access_key']) as String;
  static String get awsRegion =>
      _getValue(['storage', 'aws', 'region']) as String;
  static String get awsBucket =>
      _getValue(['storage', 'aws', 's3_bucket']) as String;
  static String get awsS3Url =>
      _getValue(['storage', 'aws', 's3_bucket_url']) as String;

  // API 키 관련 설정
  static String get youtubeApiKey =>
      _getValue(['api_keys', 'youtube']) as String;
  static String get deepLApiKey => _getValue(['api_keys', 'deepl']) as String;
  static String get branchKey => _getValue(['api_keys', 'branch']) as String;

  // 앱 관련 설정
  static String get webDomain => _getValue(['app', 'web_domain']) as String;
  static String get downloadLink =>
      _getValue(['app', 'download_link']) as String;
  static String get appLinkPrefix =>
      _getValue(['app', 'app_link_prefix']) as String;
  static String get inappAppNamePrefix =>
      _getValue(['app', 'inapp_appname_prefix']) as String;

  // 테마 관련 설정
  static Color get primaryColor =>
      Color(int.parse(_getValue(['theme', 'colors', 'primary']) as String));
  static Color get secondaryColor =>
      Color(int.parse(_getValue(['theme', 'colors', 'secondary']) as String));
  static Color get subColor =>
      Color(int.parse(_getValue(['theme', 'colors', 'sub']) as String));
  static Color get pointColor =>
      Color(int.parse(_getValue(['theme', 'colors', 'point']) as String));
  static Color get point900Color =>
      Color(int.parse(_getValue(['theme', 'colors', 'point_900']) as String));

  // 광고 관련 설정
  static String? get tapjoyAndroidSdkKey =>
      _getValue(['ads', 'tapjoy', 'android_sdk_key']) as String;
  static String? get tapjoyIosSdkKey =>
      _getValue(['ads', 'tapjoy', 'ios_sdk_key']) as String;

  static String? get unityAppleGameId =>
      _getValue(['ads', 'unity', 'apple_game_id']) as String;
  static String? get unityAndroidGameId =>
      _getValue(['ads', 'unity', 'google_game_id']) as String;

  // Pincrux 관련 설정
  static String? get pincruxAndroidAppKey {
    try {
      return _getValue(['ads', 'pincrux', 'android_app_key']) as String;
    } catch (e) {
      return null;
    }
  }

  static String? get pincruxIosAppKey {
    try {
      return _getValue(['ads', 'pincrux', 'ios_app_key']) as String;
    } catch (e) {
      return null;
    }
  }

  // 다음 값들은 prod 환경에만 있고 나머지 환경에는 없을 수 있으므로 예외 처리 추가
  static String? get unityIosPlacementId {
    try {
      return _getValue(['ads', 'unity', 'ios_placement_id']) as String;
    } catch (e) {
      return null;
    }
  }

  static String? get unityAndroidPlacementId {
    try {
      return _getValue(['ads', 'unity', 'android_placement_id']) as String;
    } catch (e) {
      return null;
    }
  }

  // Pangle 관련 설정
  static String? get pangleIosAppId {
    try {
      return _getValue(['ads', 'pangle', 'ios_app_id']) as String;
    } catch (e) {
      try {
        return _getValue(['ads', 'pangle', 'app_id']) as String;
      } catch (e) {
        return null;
      }
    }
  }

  static String? get pangleAndroidAppId {
    try {
      return _getValue(['ads', 'pangle', 'android_app_id']) as String;
    } catch (e) {
      try {
        return _getValue(['ads', 'pangle', 'app_id']) as String;
      } catch (e) {
        return null;
      }
    }
  }

  static String? get pangleIosRewardedVideoId {
    try {
      return _getValue(['ads', 'pangle', 'ios_rewarded_video_id']) as String;
    } catch (e) {
      try {
        return _getValue(['ads', 'pangle', 'rewarded_video_id']) as String;
      } catch (e) {
        return null;
      }
    }
  }

  static String? get pangleAndroidRewardedVideoId {
    try {
      return _getValue(['ads', 'pangle', 'android_rewarded_video_id'])
          as String;
    } catch (e) {
      try {
        return _getValue(['ads', 'pangle', 'rewarded_video_id']) as String;
      } catch (e) {
        return null;
      }
    }
  }

  static String? get admobIosRewardedVideoId {
    try {
      return _getValue(['ads', 'admob', 'ios_rewarded_video_id']) as String;
    } catch (e) {
      return null;
    }
  }

  static String? get admobAndroidRewardedVideoId {
    try {
      return _getValue(['ads', 'admob', 'android_rewarded_video_id']) as String;
    } catch (e) {
      return null;
    }
  }

  static String? get crowdinDistributionHash {
    try {
      return _getValue(['crowdin', 'distribution_hash']) as String;
    } catch (e) {
      return null;
    }
  }
}
