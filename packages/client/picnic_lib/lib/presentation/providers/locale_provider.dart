import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/constatns/constants.dart';
import 'package:crowdin_sdk/crowdin_sdk.dart';

part '../../generated/providers/locale_provider.g.dart';

/// 로케일 상태 제공자 (자동 생성됨)
@Riverpod(keepAlive: true)
class LocaleState extends _$LocaleState {
  @override
  Locale build() {
    // 기본값은 한국어
    return const Locale('ko', 'KR');
  }

  /// 로케일 변경 메서드
  Future<void> setLocale(Locale locale) async {
    try {
      logger.i('언어 변경 시작: ${locale.toString()}');

      // 1. 로컬 스토리지에 저장
      final localeString = '${locale.languageCode}_${locale.countryCode ?? ''}';
      await globalStorage.saveData('locale', localeString);
      logger.i('로컬 스토리지에 저장: $localeString');

      // 2. Crowdin 번역 로드
      try {
        await Crowdin.loadTranslations(locale);
        logger.i('Crowdin 번역 로드 성공: ${locale.toString()}');
      } catch (e) {
        logger.e('Crowdin 번역 로드 실패', error: e);
      }

      // 3. 상태 업데이트
      state = locale;

      logger.i('Locale changed to: ${locale.toString()}');
    } catch (e, s) {
      logger.e('Error changing locale', error: e, stackTrace: s);
    }
  }

  /// 저장된 로케일 초기화
  Future<void> initialize() async {
    try {
      final localeStr = await globalStorage.loadData('locale', 'ko_KR');
      if (localeStr != null && localeStr.isNotEmpty) {
        final parts = localeStr.split('_');
        String languageCode = parts[0];
        String? countryCode =
            parts.length > 1 && parts[1].isNotEmpty ? parts[1] : null;
        final locale = Locale(languageCode, countryCode);

        // Crowdin 번역 로드
        await Crowdin.loadTranslations(locale);

        // 상태 업데이트
        state = locale;

        logger.i('Locale initialized to: ${locale.toString()}');
      }
    } catch (e, s) {
      logger.e('Error initializing locale', error: e, stackTrace: s);
    }
  }
}
