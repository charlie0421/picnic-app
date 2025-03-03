import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_branch_sdk/flutter_branch_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ttja_app/app.dart';
import 'package:ttja_app/firebase_options.dart';
import 'package:ttja_app/main.reflectable.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/logging_observer.dart';
import 'package:picnic_lib/core/utils/privacy_consent_manager.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:url_strategy/url_strategy.dart';
import 'package:picnic_lib/core/utils/app_initializer.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_platform/universal_platform.dart';

void main() async {
  await runZonedGuarded(() async {
    try {
      logger.i('Starting app initialization...');

      await AppInitializer.initializeBasics();
      await AppInitializer.initializeEnvironment('prod');
      await AppInitializer.initializeSentry();

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

      // URL 전략 설정 (웹에만 적용)
      // 웹에서 URL 전략 설정 부분 제거 - 에러가 나고 있어서 주석 처리
      // if (kIsWeb) {
      //   setPathUrlStrategy();
      // }

      // Branch SDK는 모바일에서만 초기화
      if (!kIsWeb && UniversalPlatform.isMobile) {
        await FlutterBranchSdk.init(
          enableLogging: true,
          branchAttributionLevel: BranchAttributionLevel.NONE,
        );
      }

      logger.i('Starting app...');
      runApp(ProviderScope(observers: [LoggingObserver()], child: const App()));
      logger.i('App started successfully');
    } catch (e, s) {
      logger.e('Error during initialization', error: e, stackTrace: s);
      rethrow;
    }
  }, (Object error, StackTrace s) async {
    logger.e('Main Uncaught error', error: error, stackTrace: s);
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
