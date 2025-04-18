import 'package:crowdin_sdk/crowdin_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/presentation/providers/app_setting_provider.dart';

// 로케일 변경 헬퍼 클래스
class LocaleHelper {
  final Ref ref;

  LocaleHelper(this.ref);

  Future<void> changeLocale(Locale newLocale) async {
    try {
      // 번역 로드
      await Crowdin.loadTranslations(newLocale);
      // 상태 업데이트
      ref.read(appSettingProvider.notifier).setLocale(newLocale);

      logger.i('Locale changed to: ${newLocale.toString()}');
    } catch (e, s) {
      logger.e('Error changing locale', error: e, stackTrace: s);
    }
  }
}

// 로케일 변경 함수를 제공하는 provider
final localeHelperProvider = Provider<LocaleHelper>((ref) {
  return LocaleHelper(ref);
});
