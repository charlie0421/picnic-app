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
  static String get cdnUrl => _config['CDN_URL'] as String;
}
