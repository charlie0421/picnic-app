import 'package:flutter/material.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/data/storage/local_storage.dart';
import 'package:picnic_lib/ui/style.dart';

final voteMainColor = AppColors.secondary500;
final picMainColor = AppColors.primary500;
final communityMainColor = AppColors.sub500;
final novelMainColor = AppColors.point500;

class Constants {
  Constants._();

  static double webWidth = 375;
  static double webHeight = 812;
  static Duration snackBarDuration = const Duration(seconds: 5);
  static String get crowdinDistributionHash =>
      Environment.crowdinDistributionHash ?? 'e266f21c6074a395eb846fa5954';
}

LocalStorage globalStorage = LocalStorage();

Map<String, String> countryMap = {
  'en': 'US',
  'ko': 'KR',
  'ja': 'JP',
  'zh': 'CN',
  'id': 'ID',
};

Map<String, String> languageMap = {
  'ko': '한국어',
  'en': 'English',
  'ja': '日本語',
  'zh': '中文',
  'id': 'Indonesia',
};

const Size webDesignSize = Size(600, 800);
