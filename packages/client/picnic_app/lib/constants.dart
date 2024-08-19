import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:picnic_app/storage/local_storage.dart';
import 'package:picnic_app/ui/style.dart';

const voteMainColor = AppColors.mint500;
const picMainColor = AppColors.primary500;
const communityMainColor = AppColors.sub500;
const novelMainColor = AppColors.point500;

class Constants {
  static const double webWidth = 600;
  static const double webHeight = 400;
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

enum PortalType { vote, pic, community, novel, mypage }

extension PortalTypeExtension on PortalType {
  String get stringValue {
    switch (this) {
      case PortalType.vote:
        return 'vote';
      case PortalType.pic:
        return 'pic';
      case PortalType.community:
        return 'community';
      case PortalType.novel:
        return 'novel';
      case PortalType.mypage:
        return 'mypage';
      default:
        throw Exception('Unknown portal type');
    }
  }

  static PortalType fromString(String value) {
    switch (value) {
      case 'vote':
        return PortalType.vote;
      case 'pic':
        return PortalType.pic;
      case 'community':
        return PortalType.community;
      case 'novel':
        return PortalType.novel;
      case 'mypage':
        return PortalType.mypage;
      default:
        throw Exception('Unknown portal type string: $value');
    }
  }
}

const Size webDesignSize = Size(600, 800);
