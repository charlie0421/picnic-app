import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:prame_app/storage/local_storage.dart';

const mainColorLightMode = Color(0xFF07E88F);
const mainColorDarkMode = Color(0xFF08C97E);
const kAccessTokenKey = 'ACCESS_TOKEN';

class Constants {
  static const String userApiUrl = String.fromEnvironment('API_USER_ROOT',
      defaultValue: 'https://api-dev.1stype.io/prame');
  static const String authApiUrl = String.fromEnvironment(
    'API_AUTH_ROOT',
    defaultValue: 'https://api-dev.1stype.io/prame/auth',
  );
  static double webMaxWidth = 600.0;
  static int snackBarDuration = 3;
  static Color mainColor = const Color(0xFF0A481E);
}

var logger = Logger();

LocalStorage globalStorage = LocalStorage();

Map<String, String> countryMap = {
  'KR': 'South Korea',
  'US': 'United States',
  'JP': 'Japan',
  'DE': 'Germany',
  'FR': 'France',
  'ES': 'Spain',
  'IT': 'Italy',
  'RU': 'Russia',
  'CN': 'China',
  'BR': 'Brazil',
};

Map<String, String> languageMap = {
  'ko': '한국어',
  'en': 'English',
  'ja': '日本語',
  'de': 'Deutsch',
  'fr': 'Français',
  'es': 'Español',
  'it': 'Italiano',
  'ru': 'Русский',
  'zh': '中文',
  'pt': 'Português',
};
