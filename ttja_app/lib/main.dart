import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/main_initializer.dart';
import 'package:picnic_lib/core/utils/privacy_consent_manager.dart';

import 'package:ttja_app/app.dart';
import 'package:ttja_app/firebase_options.dart';
import 'package:ttja_app/generated/l10n.dart';
import 'package:ttja_app/main.reflectable.dart';

// 전역 언어 상태를 저장하는 변수
bool isLanguageInitialized = false;
String currentLanguage = 'ko'; // 기본값은 한국어

void main() async {
  // MainInitializer를 사용하여 앱 초기화
  await MainInitializer.initializeApp(
    environment: 'prod',
    firebaseOptions: DefaultFirebaseOptions.currentPlatform,
    appBuilder: () => Phoenix(
      child: const App(),
    ),
    loadGeneratedTranslations: S.load,
    reflectableInitializer: initializeReflectable,
  );
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
      localizationsDelegates: [],
      supportedLocales: const [Locale('ko'), Locale('en')],
      home: const Placeholder(), // 실제 홈 위젯으로 교체
    );
  }
}
