import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/presentation/providers/locale_state_provider.dart';

// 로케일 변경 헬퍼 클래스
class LocaleHelper {
  final Ref ref;

  LocaleHelper(this.ref);

  Future<void> changeLocale(Locale newLocale) async {
    try {
      // 로케일 변경 (모든 처리 위임)
      await ref.read(localeStateProvider.notifier).setLocale(newLocale);

      logger.i('Locale changed to: ${newLocale.toString()}');
    } catch (e, s) {
      logger.e('Error changing locale', error: e, stackTrace: s);
    }
  }

  // 앱 시작 시 저장된 로케일 복원
  Future<void> initializeLocale() async {
    try {
      // 초기화 메서드 호출
      await ref.read(localeStateProvider.notifier).initialize();
    } catch (e, s) {
      logger.e('Error initializing locale', error: e, stackTrace: s);
    }
  }
}

// 로케일 변경 함수를 제공하는 provider
final localeHelperProvider = Provider<LocaleHelper>((ref) {
  return LocaleHelper(ref);
});
