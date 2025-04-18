// picnic_lib/lib/l10n_setup.dart 파일 내용 수정
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/generated/app_localizations.dart';
import 'package:picnic_lib/generated/crowdin_localizations.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/presentation/providers/locale_provider.dart';

/// Picnic 라이브러리의 다국어 설정을 위한 delegate
class PicnicLibL10n {
  static LocalizationsDelegate<AppLocalizations> get delegate =>
      CrowdinLocalization.delegate;

  static List<LocalizationsDelegate> get localizationsDelegates =>
      CrowdinLocalization.localizationsDelegates;

  static List<Locale> get supportedLocales =>
      CrowdinLocalization.supportedLocales;

  /// 앱 시작 시 모든 지원 언어에 대한 번역을 미리 로드 (WidgetRef 또는 ProviderContainer 사용)
  static Future<void> preloadTranslations(dynamic refOrContainer) async {
    if (refOrContainer is WidgetRef) {
      await _preloadTranslationsWithRef(refOrContainer);
    } else if (refOrContainer is ProviderContainer) {
      await _preloadTranslationsWithContainer(refOrContainer);
    } else {
      throw ArgumentError(
          'refOrContainer must be either WidgetRef or ProviderContainer');
    }
  }

  /// 앱 시작 시 모든 지원 언어에 대한 번역을 미리 로드 (WidgetRef 사용)
  static Future<void> _preloadTranslationsWithRef(WidgetRef ref) async {
    try {
      logger.i('모든 언어 번역 미리 로드 시작 (WidgetRef)');

      for (final locale in supportedLocales) {
        logger.i('${locale.toString()} 번역 로드 중...');
        await CrowdinLocalization.delegate.load(locale);
      }

      // 저장된 로케일 초기화
      await ref.read(localeStateProvider.notifier).initialize();

      logger.i('모든 언어 번역 로드 완료');
    } catch (e) {
      logger.e('번역 미리 로드 중 오류 발생', error: e);
    }
  }

  /// 앱 시작 시 모든 지원 언어에 대한 번역을 미리 로드 (ProviderContainer 사용)
  static Future<void> _preloadTranslationsWithContainer(
      ProviderContainer container) async {
    try {
      logger.i('모든 언어 번역 미리 로드 시작 (ProviderContainer)');

      for (final locale in supportedLocales) {
        logger.i('${locale.toString()} 번역 로드 중...');
        await CrowdinLocalization.delegate.load(locale);
      }

      // 저장된 로케일 초기화
      await container.read(localeStateProvider.notifier).initialize();

      logger.i('모든 언어 번역 로드 완료');
    } catch (e) {
      logger.e('번역 미리 로드 중 오류 발생', error: e);
    }
  }
}
