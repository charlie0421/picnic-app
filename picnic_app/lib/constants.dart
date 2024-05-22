import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:picnic_app/storage/local_storage.dart';

const fanMainColorLight = Color(0xFF07E88F);
const famMainColorDark = Color(0xFF08C97E);
const voteMainColorLight = Colors.pink;
const voteMainColorDark = Colors.pinkAccent;

const kAccessTokenKey = 'ACCESS_TOKEN';

class Constants {
  static const double webMaxWidth = 600.0;
  static const int snackBarDuration = 3;
  static const Color fanMainColor = Color(0xFF47E89B);
  static const Color voteMainColor = Color(0xFFE84747);
  static const Color developerMainColor = Colors.grey;
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
