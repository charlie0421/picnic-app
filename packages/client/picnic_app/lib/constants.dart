import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:picnic_app/storage/local_storage.dart';
import 'package:picnic_app/ui/style.dart';

const voteMainColor = AppColors.Mint500;
const picMainColor = AppColors.Primary500;
const communityMainColor = AppColors.Sub500;
const novelMainColor = AppColors.Point500;

const kAccessTokenKey = 'ACCESS_TOKEN';

class Constants {
  static const double webMaxWidth = 600.0;
  static const int snackBarDuration = 3;
}

var logger = Logger();

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

int userId = 2;

enum PortalType { vote, pic, community, novel, mypage }
