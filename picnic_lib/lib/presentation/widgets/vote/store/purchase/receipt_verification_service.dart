import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:picnic_lib/supabase_options.dart';

class ReceiptVerificationService {
  static const String _sandboxEnvironment = 'sandbox';
  static const String _productionEnvironment = 'production';

  // 중복 검증 방지를 위한 플래그
  bool _isVerifying = false;

  Future<void> verifyReceipt(String receipt, String productId, String userId,
      String environment) async {
    // 이미 검증 중이면 중복 실행 방지
    if (_isVerifying) {
      print('🚨 Receipt verification already in progress, skipping');
      return;
    }

    _isVerifying = true;
    try {
      await _verifyReceiptWithRetry(receipt, productId, userId, environment);
    } finally {
      _isVerifying = false;
    }
  }

  Future<void> _verifyReceiptWithRetry(
      String receipt, String productId, String userId, String environment,
      {bool isRetry = false}) async {
    // 디버그 정보 로깅
    print('🔍 Receipt verification details ${isRetry ? '(RETRY)' : ''}:');
    print('   Platform: ${Platform.isIOS ? 'iOS' : 'Android'}');
    print('   Environment: $environment');
    print('   ProductId: $productId');
    print('   Receipt length: ${receipt.length}');
    print(
        '   Receipt preview: ${receipt.length > 50 ? receipt.substring(0, 50) + '...' : receipt}');

    try {
      final response = await supabase.functions.invoke('verify_receipt', body: {
        'receipt': receipt,
        'platform': Platform.isIOS ? 'ios' : 'android',
        'productId': productId,
        'user_id': userId,
        'environment': environment,
      });

      print('🔍 Verification response: ${response.status}, ${response.data}');

      if (response.status != 200 || response.data['success'] != true) {
        // 21002 오류 상세 분석 - 단 한 번만 재시도
        final errorData = response.data;
        if (errorData != null && errorData['error'] != null) {
          final errorMessage = errorData['error'].toString();
          print('🚨 Verification error details: $errorMessage');

          // 21002 에러이고 첫 번째 시도인 경우에만 재시도
          if (errorMessage.contains('21002') && !isRetry) {
            print('🚨 21002 Error - Environment mismatch detected');
            print('   Current environment: $environment');

            final alternativeEnvironment =
                getAlternativeEnvironment(environment);
            print(
                '🔄 Retrying with alternative environment: $alternativeEnvironment');

            try {
              await _verifyReceiptWithRetry(
                  receipt, productId, userId, alternativeEnvironment,
                  isRetry: true);
              return; // 성공하면 리턴
            } catch (retryError) {
              print(
                  '🚨 Retry with alternative environment failed: $retryError');
              // 재시도 실패 시 명확한 에러 메시지로 원래 오류 던지기
              throw Exception(
                  '구매 검증 실패: 환경 설정 오류 (21002). TestFlight와 App Store 환경이 일치하지 않습니다.');
            }
          }
        }

        throw Exception('Receipt verification failed: ${response.data}');
      }

      if (isRetry) {
        print(
            '✅ Receipt verification succeeded with alternative environment: $environment');
      } else {
        print('✅ Receipt verification succeeded');
      }
    } catch (e) {
      print('🚨 Receipt verification exception: $e');
      rethrow;
    }
  }

  Future<String> getEnvironment() async {
    final packageInfo = await PackageInfo.fromPlatform();

    print('🔍 Environment detection:');
    print('   Debug mode: $kDebugMode');
    print('   Installer store: ${packageInfo.installerStore}');
    print('   Package name: ${packageInfo.packageName}');

    if (Platform.isIOS) {
      String environment;

      // 디버그 모드에서는 무조건 샌드박스
      if (kDebugMode) {
        environment = _sandboxEnvironment;
        print('   ✅ Debug mode - using sandbox');
      } else {
        final installer = packageInfo.installerStore;

        // TestFlight 감지 로직 단순화
        bool isTestFlight = false;

        // 1. 가장 확실한 방법: installer store 체크
        if (installer == 'com.apple.testflight') {
          isTestFlight = true;
          print('   ✅ TestFlight installer detected');
        }
        // 2. App Store가 아닌 경우 TestFlight로 간주 (안전한 기본값)
        else if (installer != 'com.apple.AppStore') {
          isTestFlight = true;
          print(
              '   ⚠️ Non-AppStore installer: $installer - treating as TestFlight');
        }

        environment =
            isTestFlight ? _sandboxEnvironment : _productionEnvironment;

        print(
            '   🎯 Final environment: $environment (${isTestFlight ? 'TestFlight' : 'App Store'})');
      }

      return environment;
    } else if (Platform.isAndroid) {
      final installer = packageInfo.installerStore;
      String environment;

      if (kDebugMode) {
        environment = _sandboxEnvironment;
      } else if (installer == 'com.google.android.apps.internal.testing') {
        environment = _sandboxEnvironment; // Internal testing
      } else {
        environment = _productionEnvironment; // Google Play Store
      }

      print('   🎯 Final Android environment: $environment');
      return environment;
    }

    print('   🎯 Unknown platform, defaulting to sandbox');
    return _sandboxEnvironment;
  }

  /// 대체 환경 반환 (21002 오류 시 사용)
  String getAlternativeEnvironment(String currentEnvironment) {
    final alternative = currentEnvironment == _sandboxEnvironment
        ? _productionEnvironment
        : _sandboxEnvironment;
    print('🔄 Switching from $currentEnvironment to $alternative environment');
    return alternative;
  }
}
