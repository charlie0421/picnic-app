import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/supabase_options.dart';

class ReceiptVerificationService {
  static const String _sandboxEnvironment = 'sandbox';
  static const String _productionEnvironment = 'production';

  // 디버깅용 환경 정보 반환
  Future<Map<String, dynamic>> getEnvironmentInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();

    return {
      'environment': await getEnvironment(),
      'isDebugMode': kDebugMode,
      'platform': Platform.isIOS ? 'iOS' : 'Android',
      'installerStore': packageInfo.installerStore,
      'buildSignature': packageInfo.buildSignature,
      'appName': packageInfo.appName,
      'packageName': packageInfo.packageName,
      'version': packageInfo.version,
      'buildNumber': packageInfo.buildNumber,
    };
  }

  Future<void> verifyReceipt(String receipt, String productId, String userId,
      String environment) async {
    logger.i('Starting receipt verification...');
    logger.i('Environment: $environment');
    logger.i('Product ID: $productId');
    logger.i('User ID: $userId');
    logger.i('Platform: ${Platform.isIOS ? 'iOS' : 'Android'}');
    logger.i('Receipt length: ${receipt.length}');

    // 재시도 로직 (최대 3회)
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        // Supabase 연결 상태 확인
        if (supabase.auth.currentUser == null) {
          throw Exception('사용자 인증이 필요합니다');
        }

        logger.i('Receipt verification attempt ${retryCount + 1}/$maxRetries');

        final response = await supabase.functions.invoke(
          'verify_receipt',
          body: {
            'receipt': receipt,
            'platform': Platform.isIOS ? 'ios' : 'android',
            'productId': productId,
            'user_id': userId,
            'environment': environment,
          },
        ).timeout(
          const Duration(seconds: 30), // 30초 타임아웃
          onTimeout: () {
            throw Exception('영수증 검증 요청 시간 초과');
          },
        );

        logger.i('Receipt verification response status: ${response.status}');
        logger.i('Receipt verification response data: ${response.data}');

        if (response.status != 200) {
          logger
              .e('Receipt verification failed with status: ${response.status}');
          throw Exception('영수증 검증 실패 - 상태코드: ${response.status}');
        }

        if (response.data == null) {
          logger.e('Receipt verification response data is null');
          throw Exception('영수증 검증 실패 - 응답 데이터 없음');
        }

        if (response.data['success'] != true) {
          logger.e(
              'Receipt verification failed - Success: ${response.data['success']}');
          logger.e('Receipt verification error: ${response.data['error']}');
          final errorMsg = response.data['error'] ?? 'Unknown error';
          throw Exception('영수증 검증 실패: $errorMsg');
        }

        logger.i('Receipt verification successful!');
        return; // 성공 시 함수 종료
      } catch (e, s) {
        logger.e('Receipt verification attempt ${retryCount + 1} failed: $e',
            stackTrace: s);

        retryCount++;

        // 마지막 시도가 아니면 잠시 대기 후 재시도
        if (retryCount < maxRetries) {
          logger.i(
              'Retrying receipt verification in ${retryCount * 2} seconds...');
          await Future.delayed(Duration(seconds: retryCount * 2));
          continue;
        }

        // 모든 재시도 실패 시 구체적인 에러 메시지 제공
        if (e.toString().contains('SocketException') ||
            e.toString().contains('TimeoutException') ||
            e.toString().contains('시간 초과')) {
          throw Exception('네트워크 연결 오류 - 인터넷 연결을 확인해주세요');
        } else if (e.toString().contains('사용자 인증')) {
          rethrow;
        } else if (e.toString().contains('영수증 검증 실패')) {
          rethrow;
        } else {
          throw Exception('영수증 검증 중 예상치 못한 오류가 발생했습니다: ${e.toString()}');
        }
      }
    }
  }

  Future<String> getEnvironment() async {
    logger.i('Determining environment...');

    if (kDebugMode) {
      logger.i('Debug mode detected - using sandbox environment');
      return _sandboxEnvironment;
    }

    final packageInfo = await PackageInfo.fromPlatform();
    logger.i('Package info - installer store: ${packageInfo.installerStore}');
    logger.i('Package info - build signature: ${packageInfo.buildSignature}');
    logger.i('Package info - app name: ${packageInfo.appName}');
    logger.i('Package info - package name: ${packageInfo.packageName}');
    logger.i('Package info - version: ${packageInfo.version}');
    logger.i('Package info - build number: ${packageInfo.buildNumber}');

    if (Platform.isIOS) {
      // iOS에서 테스트플라이트 환경 감지 개선
      final installerStore = packageInfo.installerStore;

      // TestFlight 감지 방법들
      final isTestFlightStore = installerStore == 'com.apple.testflight';
      final isNullInstaller =
          installerStore == null; // TestFlight는 때때로 null을 반환
      final hasTestFlightSuffix =
          packageInfo.appName.toLowerCase().contains('testflight') ||
              packageInfo.appName.toLowerCase().contains('beta');

      // 추가적인 테스트/개발 환경 감지
      final isDebugBuild = packageInfo.buildSignature.isNotEmpty;
      final isAdHocBuild = installerStore?.isEmpty == true;

      logger.i('iOS environment detection:');
      logger.i('  - installerStore: $installerStore');
      logger.i('  - isTestFlightStore: $isTestFlightStore');
      logger.i('  - isNullInstaller: $isNullInstaller');
      logger.i('  - hasTestFlightSuffix: $hasTestFlightSuffix');
      logger.i('  - buildSignature: ${packageInfo.buildSignature}');
      logger.i('  - isDebugBuild: $isDebugBuild');
      logger.i('  - isAdHocBuild: $isAdHocBuild');

      // 테스트플라이트, 개발, 또는 Ad Hoc 빌드이면 샌드박스 사용
      final isSandboxEnvironment = isTestFlightStore ||
          isNullInstaller ||
          hasTestFlightSuffix ||
          isDebugBuild ||
          isAdHocBuild;

      if (isSandboxEnvironment) {
        logger.i('Using sandbox environment for iOS TestFlight/Debug/AdHoc');
        return _sandboxEnvironment;
      } else {
        logger.i('Using production environment for iOS App Store');
        return _productionEnvironment;
      }
    } else if (Platform.isAndroid) {
      final installer = packageInfo.installerStore;
      logger.i('Android installer: $installer');

      if (installer == null || installer == 'com.android.vending') {
        logger.i('Using production environment for Android Play Store');
        return _productionEnvironment;
      } else if (installer == 'com.google.android.apps.internal.testing') {
        logger.i('Using sandbox environment for Android Internal Testing');
        return _sandboxEnvironment;
      } else {
        logger.i('Using sandbox environment for Android unknown installer');
        return _sandboxEnvironment;
      }
    }

    logger.w('Unknown platform - using sandbox environment');
    return _sandboxEnvironment;
  }
}
