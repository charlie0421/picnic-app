import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:universal_platform/universal_platform.dart';

class SystemUIInitializer {
  SystemUIInitializer._();

  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  static Future<void> initialize() async {
    if (kIsWeb) return;

    try {
      int? androidSdkVersion;
      if (UniversalPlatform.isAndroid) {
        try {
          final androidInfo = await _deviceInfo.androidInfo;
          androidSdkVersion = androidInfo.version.sdkInt;
          logger.i('Android SDK Version: $androidSdkVersion');
        } catch (e, s) {
          logger.e('안드로이드 SDK 버전 확인 실패:', error: e, stackTrace: s);
          androidSdkVersion = 29;
        }

        try {
          // 시스템 UI 스타일 설정
          SystemChrome.setSystemUIOverlayStyle(
            const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
              systemNavigationBarColor: Colors.transparent,
              systemNavigationBarDividerColor: Colors.transparent,
              systemNavigationBarIconBrightness: Brightness.dark,
            ),
          );

          // Android 버전별 SystemUiMode 설정
          if (androidSdkVersion >= 35) {
            // Android 15+ (갤럭시 S25 등 최신 기기)
            await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

            SystemChrome.setSystemUIOverlayStyle(
              const SystemUiOverlayStyle(
                systemNavigationBarContrastEnforced: false,
                // 최신 기기에서 gesture navigation 지원
                systemNavigationBarIconBrightness: Brightness.dark,
              ),
            );
          } else if (androidSdkVersion >= 30) {
            await SystemChrome.setEnabledSystemUIMode(
              SystemUiMode.manual,
              overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
            );

            SystemChrome.setSystemUIOverlayStyle(
              const SystemUiOverlayStyle(
                systemNavigationBarContrastEnforced: false,
              ),
            );
          } else {
            await SystemChrome.setEnabledSystemUIMode(
              SystemUiMode.manual,
              overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
            );
          }
        } catch (e, s) {
          logger.e('시스템 UI 설정 실패:', error: e, stackTrace: s);
          // 기본 설정으로 폴백
          await SystemChrome.setEnabledSystemUIMode(
            SystemUiMode.manual,
            overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
          );
        }
      }

      try {
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
      } catch (e, s) {
        logger.e('화면 방향 설정 실패:', error: e, stackTrace: s);
      }
    } catch (e, s) {
      logger.e('시스템 UI 초기화 중 오류 발생:', error: e, stackTrace: s);
    }
  }
}
