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
    final deviceLocale = PlatformDispatcher.instance.locale;
    return _isSupported(deviceLocale) ? deviceLocale : const Locale('ko');
  }

  bool _isSupported(Locale locale) {
    return PicnicLibL10n.supportedLocales
        .any((l) => l.languageCode == locale.languageCode);
  }

  Future<void> setLocale(Locale locale) async {
    if (!_isSupported(locale)) return;

    try {
      await PicnicLibL10n.loadTranslations(locale);
      state = locale;
    } catch (e) {
      debugPrint('로케일 변경 실패: $e');
    }
  }

  /// 저장된 로케일 초기화
  Future<void> initialize() async {
    try {
      // 1. 로컬 스토리지에서 저장된 로케일 가져오기
      final languageCode = await globalStorage.loadData('locale', 'ko');

      if (languageCode != null && languageCode.isNotEmpty) {
        // 저장된 언어 코드가 지원되는 언어인지 확인
        final isSupported = PicnicLibL10n.supportedLocales
            .any((locale) => locale.languageCode == languageCode);

        if (isSupported) {
          // 지원되는 언어면 해당 언어의 기본 국가 코드와 함께 로케일 생성
          final countryCode = countryMap[languageCode] ?? '';
          final savedLocale = Locale(languageCode, countryCode);
          await _updateLocale(savedLocale);
          return;
        }
      }

      // 2. 저장된 로케일이 없거나 지원되지 않는 경우 디바이스 로케일 사용
      final deviceLocale = PlatformDispatcher.instance.locale;
      final isSupported = PicnicLibL10n.supportedLocales
          .any((locale) => locale.languageCode == deviceLocale.languageCode);

      if (isSupported) {
        // 디바이스 로케일이 지원되는 언어면 해당 언어의 기본 국가 코드와 함께 로케일 생성
        final countryCode = countryMap[deviceLocale.languageCode] ?? '';
        final locale = Locale(deviceLocale.languageCode, countryCode);
        await _updateLocale(locale);
      } else {
        // 3. 디바이스 로케일도 지원되지 않는 경우 기본값 사용
        await _updateLocale(const Locale('ko', 'KR'));
      }
    } catch (e, s) {
      logger.e('Error initializing locale', error: e, stackTrace: s);
      // 오류 발생 시 기본값 사용
      await _updateLocale(const Locale('ko', 'KR'));
    }
  }

  /// 로케일 업데이트 공통 메서드
  Future<void> _updateLocale(Locale locale) async {
    try {
      // Crowdin 번역 로드 (언어 코드만 사용)
      await Crowdin.loadTranslations(Locale(locale.languageCode));
      logger.i('Crowdin 번역 로드 성공: ${locale.languageCode}');

      // 상태 업데이트
      state = locale;
    } catch (e) {
      logger.e('Crowdin 번역 로드 실패', error: e);
      // Crowdin 로드 실패 시에도 상태는 업데이트
      state = locale;
    }
  }
}
