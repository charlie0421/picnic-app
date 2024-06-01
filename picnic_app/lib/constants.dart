import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:picnic_app/storage/local_storage.dart';
import 'package:picnic_app/ui/style.dart';

const voteMainColor = AppColors.Mint500;
const picMainColor = AppColors.Primary500;
const communityMainColor = AppColors.Sub500;
const novelMainColor = AppColors.Point500;

const Gradient commonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.Mint500, AppColors.Primary500]);

const Gradient voteGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFE3B847), AppColors.Gray00]);

const kAccessTokenKey = 'ACCESS_TOKEN';

class Constants {
  static const double webMaxWidth = 600.0;
  static const int snackBarDuration = 3;
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
