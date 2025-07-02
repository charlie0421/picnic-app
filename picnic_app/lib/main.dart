// ignore_for_file: unused_import

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_branch_sdk/flutter_branch_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:picnic_app/app.dart';
import 'package:picnic_app/firebase_options.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/main.reflectable.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/core/utils/app_initializer.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/logging_observer.dart';

import 'package:picnic_lib/supabase_options.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:crowdin_sdk/crowdin_sdk.dart';
import 'package:intl/intl.dart';
import 'package:picnic_lib/core/constatns/constants.dart';
import 'package:picnic_lib/services/localization_service.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/core/utils/shorebird_utils.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'package:picnic_lib/core/utils/main_initializer.dart';

// 전역 언어 상태 변수
bool isLanguageInitialized = false;
String currentLanguage = 'ko'; // 기본값은 한국어

void main() async {
  // ENVIRONMENT dart-define 값을 동적으로 읽기 (기본값: dev)
  const environment =
      String.fromEnvironment('ENVIRONMENT', defaultValue: 'dev');

  // MainInitializer를 사용하여 앱 초기화
  await MainInitializer.initializeApp(
    environment: environment, // 동적 환경값 사용
    firebaseOptions: DefaultFirebaseOptions.currentPlatform,
    appBuilder: () => Phoenix(
      child: const App(),
    ),
    loadGeneratedTranslations: S.load,
    reflectableInitializer: initializeReflectable,
  );
}
