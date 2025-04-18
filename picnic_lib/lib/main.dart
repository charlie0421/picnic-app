import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:crowdin_sdk/crowdin_sdk.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Crowdin SDK 초기화
  await Crowdin.init(
    distributionHash: 'YOUR_DISTRIBUTION_HASH', // 실제 distributionHash로 변경 필요
    sourceLanguage: 'ko', // 소스 언어 (한국어)
    updateInterval: 900, // 업데이트 간격 (15분)
    intervalUpdating: true, // 주기적 업데이트 활성화
  );

  // 앱 시작 시 번역 로드
  await Crowdin.loadTranslations(WidgetsBinding.instance.window.locale);

  runApp(MyApp());
}
