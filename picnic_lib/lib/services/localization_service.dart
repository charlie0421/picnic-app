import 'package:flutter/material.dart';
import 'package:crowdin_sdk/crowdin_sdk.dart';
import 'package:picnic_lib/core/constatns/constants.dart';
import 'package:picnic_lib/l10n.dart';

/// Crowdin 로컬라이제이션 관리를 위한 서비스 클래스
class LocalizationService {
  /// Crowdin SDK를 초기화합니다.
  static Future<void> initialize({
    String? distributionHash,
    Duration updatesInterval = const Duration(minutes: 15),
    InternetConnectionType connectionType = InternetConnectionType.any,
  }) async {
    await Crowdin.init(
      distributionHash: distributionHash ?? Constants.crowdinDistributionHash,
      connectionType: connectionType,
      updatesInterval: updatesInterval,
    );
  }

  /// 지정된 로케일에 대한 번역을 로드합니다.
  static Future<void> loadTranslations(Locale locale) async {
    await Crowdin.loadTranslations(locale);
  }

  /// 앱에서 사용할 로컬라이제이션 델리게이트 목록을 반환합니다.
  static List<LocalizationsDelegate<dynamic>> get localizationDelegates {
    return PicnicLibL10n.localizationsDelegates;
  }

  /// 지원되는 로케일 목록을 반환합니다.
  static List<Locale> get supportedLocales {
    return PicnicLibL10n.supportedLocales;
  }
}
