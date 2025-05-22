import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_branch_sdk/flutter_branch_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ttja_app/app.dart';
import 'package:ttja_app/firebase_options.dart';
import 'package:ttja_app/generated/l10n.dart';
import 'package:ttja_app/main.reflectable.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/logging_observer.dart';
import 'package:picnic_lib/core/utils/privacy_consent_manager.dart';
import 'package:picnic_lib/services/localization_service.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:picnic_lib/core/utils/app_initializer.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:picnic_lib/core/constatns/constants.dart';
import 'package:crowdin_sdk/crowdin_sdk.dart';
import 'package:intl/intl.dart';

// 전역 언어 상태를 저장하는 변수
bool isLanguageInitialized = false;
String currentLanguage = 'ko'; // 기본값은 한국어

void main() async {
  // 에러 로깅 향상을 위한 Zone 설정
  await runZonedGuarded(() async {
    try {
      // 기본 Flutter 초기화
      WidgetsFlutterBinding.ensureInitialized();
      logger.i('앱 초기화 시작...');

      // 가장 먼저 필요한 기본 서비스들 초기화
      await AppInitializer.initializeBasics();
      await AppInitializer.initializeEnvironment('prod');
      await AppInitializer.initializeSentry();

      // ==================== 언어 초기화 시작 ====================
      logger.i('언어 초기화 시작');

      // 1. LocalizationService 초기화 (Crowdin SDK 포함)
      await LocalizationService.initialize(
        distributionHash: Constants.crowdinDistributionHash,
      );
      logger.i(
          'LocalizationService 초기화 완료: ${Constants.crowdinDistributionHash}');

      // 2. 저장된 언어 설정 확인 (한국어 우선)
      final languagePref = await globalStorage.loadData('language', 'ko');
      currentLanguage =
          languagePref == null || languagePref.isEmpty || languagePref == 'en'
              ? 'ko' // 비어있거나 영어인 경우 한국어로 설정
              : languagePref;
      logger.i('선택된 언어: $currentLanguage (원본값: $languagePref)');

      // 언어 설정이 영어인 경우 한국어로 강제 변경
      if (currentLanguage != languagePref) {
        await globalStorage.saveData('language', currentLanguage);
        logger.i('언어 설정 저장 완료: $languagePref → $currentLanguage');
      }

      // 3. Intl 기본 로케일 설정 (필수)
      Intl.defaultLocale = currentLanguage;
      logger.i('Intl.defaultLocale 설정: $currentLanguage');

      // 4. 번역 데이터 로드 (동기적으로 처리)
      try {
        // Crowdin SDK 번역 로드
        await Crowdin.loadTranslations(Locale(currentLanguage));
        logger.i('Crowdin 번역 로드 완료');

        // 앱 내부 생성 번역 로드
        await S.load(Locale(currentLanguage));
        logger.i('앱 내부 번역(S.load) 완료');

        // 테스트를 위한 번역 샘플 확인
        final testValue = Crowdin.getText(currentLanguage, 'app_name');
        logger.i('번역 테스트 결과: app_name -> $testValue');

        // 언어 초기화 완료 플래그 설정
        isLanguageInitialized = true;
        logger.i('언어 초기화 완료');
      } catch (e) {
        logger.e('번역 로드 중 오류 발생', error: e);
        // 오류 발생 시 기본값으로 다시 시도
        try {
          currentLanguage = 'ko';
          Intl.defaultLocale = currentLanguage;
          await Crowdin.loadTranslations(const Locale('ko'));
          await S.load(const Locale('ko'));
          await globalStorage.saveData('language', currentLanguage);

          isLanguageInitialized = true;
          logger.i('언어 복구 성공: ko');
        } catch (recoveryError) {
          logger.e('언어 복구 시도 중 추가 오류', error: recoveryError);
          // 최소한의 기능이라도 동작하도록 플래그 설정
          isLanguageInitialized = true;
        }
      }
      // ==================== 언어 초기화 종료 ====================

      // 기타 서비스 초기화
      await initializeSupabase();

      // 웹에서 불필요한 기능들은 조건부로 초기화
      if (!kIsWeb) {
        await AppInitializer.initializeWebP();
        await AppInitializer.initializeTapjoy();
      }

      // Firebase는 웹과 모바일 모두 필요할 수 있지만, 웹 환경에서 다른 설정이 필요한 경우 처리
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      await AppInitializer.initializeAuth();

      // 타임존 초기화는 모바일에서만 필요할 수 있음
      if (!kIsWeb) {
        await AppInitializer.initializeTimezone();
      }

      initializeReflectable();

      // 프라이버시 동의 관련 기능은 모바일에서만 필요할 수 있음
      if (!kIsWeb) {
        await AppInitializer.initializePrivacyConsent();
      }

      // Branch SDK는 모바일에서만 초기화
      if (!kIsWeb && UniversalPlatform.isMobile) {
        await FlutterBranchSdk.init(
          enableLogging: true,
          branchAttributionLevel: BranchAttributionLevel.NONE,
        );
      }

      // 모든 초기화가 완료되면 앱 실행
      logger.i('앱 시작 중...');
      runApp(ProviderScope(observers: [LoggingObserver()], child: const App()));
      logger.i('앱 시작 완료');
    } catch (e, s) {
      logger.e('초기화 중 오류 발생', error: e, stackTrace: s);
      rethrow;
    }
  }, (Object error, StackTrace s) async {
    logger.e('치명적 오류 발생', error: error, stackTrace: s);
    await Sentry.captureException(error, stackTrace: s);
  });
}

void logStorageData() async {
  // 웹에서는 FlutterSecureStorage를 사용할 수 없으므로 조건부 실행
  if (!kIsWeb) {
    const storage = FlutterSecureStorage();
    final storageData = await storage.readAll();

    final storageDataString =
        storageData.entries.map((e) => '${e.key}: ${e.value}').join('\n');
    logger.i(storageDataString);
  }
}

Future<void> requestAppTrackingTransparency() async {
  // 앱 추적 투명성은 iOS에서만 필요하므로 웹에서는 실행하지 않음
  if (!kIsWeb) {
    await PrivacyConsentManager.initialize();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TTJA App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      localizationsDelegates: LocalizationService.localizationDelegates,
      supportedLocales: LocalizationService.supportedLocales,
      home: const Placeholder(), // 실제 홈 위젯으로 교체
    );
  }
}
