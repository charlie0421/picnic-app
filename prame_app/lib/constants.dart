import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:prame_app/storage/local_storage.dart';

const mainColorLightMode = Color(0xFF07E88F);
const mainColorDarkMode = Color(0xFF08C97E);
const kAccessTokenKey = 'ACCESS_TOKEN';

class Constants {
  static const String userApiUrl = String.fromEnvironment('API_USER_ROOT',
      defaultValue: 'https://api-dev.iconcasting.io/user');
  static const String authApiUrl = String.fromEnvironment(
    'API_AUTH_ROOT',
    defaultValue: 'https://api-dev.iconcasting.io/auth',
  );
  static const double webMaxWidth = 600.0;
  static const int snackBarDuration = 3;
  static const Color mainColor = Color(0xFF47E89B);
}

var logger = Logger();

LocalStorage globalStorage = LocalStorage();

Map<String, String> countryMap = {
  'KR': 'South Korea',
  'US': 'United States',
  'JP': 'Japan',
  'CN': 'China',
};

Map<String, String> languageMap = {
  'ko': '한국어',
  'en': 'English',
  'ja': '日本語',
  'zh': '中文',
};

int userId = 2;
