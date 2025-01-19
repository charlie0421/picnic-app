import 'dart:convert';

import 'package:flutter/services.dart';

class Environment {
  static late Map<String, dynamic> _config;
  static late String _currentEnvironment;

  static Future<void> initConfig(String env) async {
    _currentEnvironment = env;
    final configString = await rootBundle.loadString('config/$env.json');
    _config = json.decode(configString) as Map<String, dynamic>;
  }

  static String get currentEnvironment => _currentEnvironment;

  static String get supabaseUrl => _config['SUPABASE_URL'] as String;

  static String get supabaseAnonKey => _config['SUPABASE_ANON_KEY'] as String;

  static String get supabaseStorageUrl =>
      _config['SUPABASE_STORAGE_URL'] as String;

  static String get supabaseStorageAnonKey =>
      _config['SUPABASE_STORAGE_ANON_KEY'] as String;

  static String get appleClientId => _config['APPLE_CLIENT_ID'] as String;

  static String get appleRedirectUri => _config['APPLE_REDIRECT_URI'] as String;

  static String get googleClientId => _config['GOOGLE_CLIENT_ID'] as String;

  static String get googleServerClientId =>
      _config['GOOGLE_SERVER_CLIENT_ID'] as String;

  static String get kakaoNativeAppKey =>
      _config['KAKAO_NATIVE_APP_KEY'] as String;

  static String get kakaoJavascriptKey =>
      _config['KAKAO_JAVASCRIPT_KEY'] as String;

  static bool get enableSentry => _config['ENABLE_SENTRY'] as bool;

  static String get sentryAppDsn => _config['SENTRY_APP_DSN'] as String;

  static String get sentryWebDsn => _config['SENTRY_WEB_DSN'] as String;

  static String get cdnUrl => _config['CDN_URL'] as String;

  static String get youtubeApiKey => _config['YOUTUBE_API_KEY'] as String;

  static String get awsAccessKey => _config['AWS_ACCESS_KEY_ID'] as String;

  static String get awsSecretKey => _config['AWS_SECRET_ACCESS_KEY'] as String;

  static String get awsRegion => _config['AWS_REGION'] as String;

  static String get awsBucket => _config['AWS_S3_BUCKET'] as String;

  static String get awsS3Url => _config['AWS_S3_BUCKET_URL'] as String;

  static String get unityAppleGameId =>
      _config['UNITY_APPLE_GAME_ID'] as String;

  static String get unityAndroidGameId =>
      _config['UNITY_GOOGLE_GAME_ID'] as String;

  static String get webDomain => _config['WEB_DOMAIN'] as String;

  static String get deepLApiKey => _config['DEEPL_API_KEY'] as String;

  static double get sentryTraceSampleRate =>
      _config['SENTRY_TRACE_SAMPLE_RATE'] as double;

  static double get sentryProfileSampleRate =>
      _config['SENTRY_PROFILE_SAMPLE_RATE'] as double;

  static double get sentrySessionSampleRate =>
      _config['SENTRY_SESSION_SAMPLE_RATE'] as double;

  static double get sentryErrorSampleRate =>
      _config['SENTRY_ERROR_SAMPLE_RATE'] as double;

  static Color get primaryColor =>
      Color(int.parse(_config['PRIMARY_COLOR'] as String));

  static Color get secondaryColor =>
      Color(int.parse(_config['SECONDARY_COLOR'] as String));

  static Color get subColor => Color(int.parse(_config['SUB_COLOR'] as String));

  static Color get pointColor =>
      Color(int.parse(_config['POINT_COLOR'] as String));

  static Color get point900Color =>
      Color(int.parse(_config['POINT_900_COLOR'] as String));

  static String get tapjoyAndroidSdkKey =>
      _config['TAPJOY_ANDROID_SDK_KEY'] as String;

  static String get tapjoyIosSdkKey => _config['TAPJOY_IOS_SDK_KEY'] as String;

  static String get inappAppNamePrefix =>
      _config['INAPP_APPNAME_PREFIX'] as String;

  static String get downloadLink => _config['DOWNLOAD_LINK'] as String;
}
