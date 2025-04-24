// ignore_for_file: unused_import

import 'dart:async';

import 'package:crowdin_sdk/crowdin_sdk.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_branch_sdk/flutter_branch_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/app.dart';
import 'package:picnic_app/firebase_options.dart';
import 'package:picnic_app/main.reflectable.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/core/utils/app_initializer.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/logging_observer.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/presentation/providers/app_setting_provider.dart';
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

      // Branch SDK는 모바일에서만 초기화
      if (!kIsWeb && UniversalPlatform.isMobile) {
        await FlutterBranchSdk.init(
          enableLogging: true,
          branchAttributionLevel: BranchAttributionLevel.NONE,
        );
      }

      // ProviderContainer 생성
      final container = ProviderContainer(
        observers: [LoggingObserver()],
      );

      // Crowdin OTA 초기화
      await PicnicLibL10n.initialize(
          container.read(appSettingProvider.notifier), container);

      // 기본 언어(한국어) 번역 로드
      for (final locale in PicnicLibL10n.supportedLocales) {
        await Crowdin.loadTranslations(locale);
      }

      logger.i('Starting app...');

      runApp(
        UncontrolledProviderScope(
          container: container,
          child: Consumer(builder: (context, ref, _) {
            final locale = PicnicLibL10n.getCurrentLocale();
            logger.i('MaterialApp locale: $locale');

            return MaterialApp(
              localizationsDelegates: PicnicLibL10n.localizationsDelegates,
              supportedLocales: PicnicLibL10n.supportedLocales,
              locale: locale,
              home: const App(),
            );
          }),
        ),
      );
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

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = PicnicLibL10n.getCurrentLocale();
    logger.i('currentLocale: $locale');

    return MaterialApp(
      title: 'Picnic App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      locale: locale,
      localizationsDelegates: PicnicLibL10n.localizationsDelegates,
      supportedLocales: PicnicLibL10n.supportedLocales,
      home: const Placeholder(), // 실제 홈 위젯으로 교체
    );
  }
}

// 언어 변경 사용 예시:
// ref.read(appSettingProvider.notifier).setLanguage('en');
// await PicnicLibL10n.loadTranslations(Locale('en'));
