import 'package:flutter/material.dart';
import 'package:picnic_lib/data/storage/local_storage.dart';
import 'package:picnic_lib/ui/style.dart';

const voteMainColor = AppColors.mint500;
const picMainColor = AppColors.primary500;
const communityMainColor = AppColors.sub500;
const novelMainColor = AppColors.point500;

class Constants {
  static const double webWidth = 600;
  static const double webHeight = 400;
  static const int snackBarDuration = 3;
}

LocalStorage globalStorage = LocalStorage();

Map<String, String> countryMap = {
  'en': 'US',
  'ko': 'KR',
  'ja': 'JP',
  'zh': 'CN',
};

Map<String, String> languageMap = {
  'ko': '한국어',
  'en': 'English',
  'ja': '日本語',
  'zh': '中文',
};

const Size webDesignSize = Size(600, 800);
