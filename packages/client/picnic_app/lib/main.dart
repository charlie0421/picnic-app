import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_branch_sdk/flutter_branch_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/app.dart';
import 'package:picnic_app/firebase_options.dart';
import 'package:picnic_app/main.reflectable.dart';
import 'package:picnic_lib/core/utils/app_initializer.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/logging_observer.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
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
        await AppInitializer.initializeUnityAds();
      }

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
