import 'package:flutter/material.dart';
import 'package:picnic_lib/data/storage/local_storage.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:picnic_lib/core/utils/logger.dart';

final voteMainColor = AppColors.secondary500;
final picMainColor = AppColors.primary500;
final communityMainColor = AppColors.sub500;
final novelMainColor = AppColors.point500;

class Constants {
  Constants._();

  static double webWidth = 375;
  static double webHeight = 812;
  static Duration snackBarDuration = const Duration(seconds: 5);
}

LocalStorage globalStorage = LocalStorage();

// LocalStorage 언어 설정 관련 확장 메서드
extension LocalStorageLanguageExtension on LocalStorage {
  Future<void> debugSaveLanguage(String language) async {
    logger.i('언어 설정 저장: $language');
    await saveData('language', language);
    final savedValue = await loadData('language', null);
    logger.i('저장된 언어 확인: $savedValue');
  }
}

Map<String, String> countryMap = {
  'en': 'US',
  'ko': 'KR',
  'ja': 'JP',
  'zh': 'CN',
  'id': 'ID',
};

Map<String, String> languageMap = {
  // TODO: i18n - 국제화 적용 필요
  'ko': 'Korean',
  'en': 'English',
  'ja': 'Japanese',
  'zh': 'Chinese',
  'id': 'Indonesian',
};

const Size webDesignSize = Size(600, 800);
