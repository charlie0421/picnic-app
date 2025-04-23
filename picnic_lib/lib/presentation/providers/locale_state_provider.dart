import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/constatns/constants.dart';
import 'package:crowdin_sdk/crowdin_sdk.dart';
import 'package:picnic_lib/l10n.dart';
import 'dart:ui';

part '../../generated/providers/locale_state_provider.g.dart';

/// 로케일 상태 제공자
@riverpod
class LocaleState extends _$LocaleState {
  @override
  Locale build() {
    // 초기값은 한국어로 설정
    return const Locale('ko');
  }

  bool _isSupported(Locale locale) {
    return PicnicLibL10n.supportedLocales
        .any((l) => l.languageCode == locale.languageCode);
  }

  Future<void> setLocale(Locale locale) async {
    if (!_isSupported(locale)) return;

    try {
      logger.i('로케일 변경 시도: ${locale.languageCode}');

      // 1. Crowdin 번역 로드
      logger.i('Crowdin 번역 로드 시작');
      await Crowdin.loadTranslations(locale);
      logger.i('Crowdin 번역 로드 완료');

      // 2. 번역이 실제로 로드되었는지 확인
      final testKeys = ['nav_vote'];
      bool allTranslationsLoaded = true;

      for (final key in testKeys) {
        final translation = Crowdin.getText(locale.languageCode, key);
        logger.i('번역 키 "$key" 검사: ${translation ?? "null"}');

        if (translation == null || translation.isEmpty) {
          logger.w('번역 키 "$key" 로드 실패');
          allTranslationsLoaded = false;
          break;
        }
      }

      if (!allTranslationsLoaded) {
        // 실패 시 기본 번역 사용 시도
        logger.i('기본 번역 사용 시도');
        final defaultTranslation = Crowdin.getText('ko', 'nav_vote');
        if (defaultTranslation != null && defaultTranslation.isNotEmpty) {
          logger.i('기본 번역 사용 성공');
          allTranslationsLoaded = true;
        } else {
          throw Exception('번역 로드 실패: nav_vote 키를 찾을 수 없음');
        }
      }

      // 3. 로컬 스토리지에 언어 설정 저장
      await globalStorage.saveData('locale', locale.languageCode);

      // 4. 상태 업데이트
      state = locale;

      logger.i('로케일 변경 성공: ${locale.languageCode}');
    } catch (e, s) {
      logger.e('로케일 변경 실패', error: e, stackTrace: s);
      debugPrint('로케일 변경 실패: $e');

      // 실패 시 기본값으로 설정
      state = const Locale('ko');
      await globalStorage.saveData('locale', 'ko');
    }
  }

  /// 저장된 로케일 초기화
  Future<void> initialize() async {
    try {
      // 1. 로컬 스토리지에서 저장된 로케일 가져오기
      final languageCode = await globalStorage.loadData('locale', 'ko');
      logger.i('저장된 로케일: $languageCode');

      if (languageCode != null && languageCode.isNotEmpty) {
        final isSupported = PicnicLibL10n.supportedLocales
            .any((locale) => locale.languageCode == languageCode);

        if (isSupported) {
          final countryCode = countryMap[languageCode] ?? '';
          final savedLocale = Locale(languageCode, countryCode);
          await setLocale(savedLocale);
          return;
        }
      }

      // 2. 디바이스 로케일 확인
      final deviceLocale = PlatformDispatcher.instance.locale;
      logger.i('디바이스 로케일: ${deviceLocale.languageCode}');

      final isDeviceLocaleSupported = PicnicLibL10n.supportedLocales
          .any((locale) => locale.languageCode == deviceLocale.languageCode);

      if (isDeviceLocaleSupported) {
        final countryCode = countryMap[deviceLocale.languageCode] ?? '';
        final locale = Locale(deviceLocale.languageCode, countryCode);
        await setLocale(locale);
        return;
      }

      // 3. 기본값 사용
      logger.i('기본 로케일(한국어) 사용');
      await setLocale(const Locale('ko', 'KR'));
    } catch (e, s) {
      logger.e('로케일 초기화 실패', error: e, stackTrace: s);
      await setLocale(const Locale('ko', 'KR'));
    }
  }
}
