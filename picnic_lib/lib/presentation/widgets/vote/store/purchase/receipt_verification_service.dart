import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:picnic_lib/supabase_options.dart';

class ReceiptVerificationService {
  static const String _sandboxEnvironment = 'sandbox';
  static const String _productionEnvironment = 'production';

  Future<void> verifyReceipt(String receipt, String productId, String userId,
      String environment) async {
    // 디버그 정보 로깅
    print('🔍 Receipt verification details:');
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
        // 21002 오류 상세 분석
        final errorData = response.data;
        if (errorData != null && errorData['error'] != null) {
          final errorMessage = errorData['error'].toString();
          print('🚨 Verification error details: $errorMessage');

          if (errorMessage.contains('21002')) {
            print('🚨 21002 Error Analysis:');
            print('   Current environment: $environment');
            print('   This usually means environment mismatch');
            print(
                '   TestFlight should use sandbox, App Store should use production');

            // 21002 오류에 대한 구체적인 예외 던지기
            throw Exception(
                'Environment mismatch error (21002): Receipt was sent to wrong Apple server environment. Current: $environment');
          }
        }

        throw Exception('Receipt verification failed: ${response.data}');
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
    print('   App name: ${packageInfo.appName}');
    print('   Build number: ${packageInfo.buildNumber}');

    if (Platform.isIOS) {
      // iOS 환경 감지 - 더 정확한 로직
      final installer = packageInfo.installerStore;
      String environment;

      // 개발/테스트 환경에서는 무조건 샌드박스
      if (kDebugMode) {
        environment = _sandboxEnvironment;
        print('   Debug mode detected - using sandbox');
      } else if (installer == 'com.apple.testflight') {
        environment = _sandboxEnvironment;
        print('   TestFlight detected - using sandbox');
      } else if (installer == 'com.apple.AppStore') {
        environment = _productionEnvironment;
        print('   App Store detected - using production');
      } else if (installer == null || installer.isEmpty) {
        // TestFlight에서 때때로 installer가 null일 수 있음
        // 추가 검증 로직
        if (packageInfo.packageName.contains('.debug') ||
            packageInfo.packageName.contains('.dev') ||
            packageInfo.buildNumber.contains('beta') ||
            packageInfo.buildNumber.contains('test')) {
          environment = _sandboxEnvironment;
          print('   Development indicators found - using sandbox');
        } else {
          // 확실하지 않은 경우 sandbox로 안전하게 처리
          environment = _sandboxEnvironment;
          print('   Null installer - defaulting to sandbox for safety');
        }
      } else {
        // 알 수 없는 경우 샌드박스로 안전하게 처리
        environment = _sandboxEnvironment;
        print('   Unknown installer ($installer) - defaulting to sandbox');
      }

      print('   Final iOS environment: $environment');
      return environment;
    } else if (Platform.isAndroid) {
      final installer = packageInfo.installerStore;
      String environment;

      if (kDebugMode) {
        environment = _sandboxEnvironment;
      } else if (installer == null || installer == 'com.android.vending') {
        environment = _productionEnvironment;
      } else if (installer == 'com.google.android.apps.internal.testing') {
        environment = _sandboxEnvironment;
      } else {
        environment = _sandboxEnvironment;
      }

      print('   Final Android environment: $environment');
      return environment;
    }

    print('   Unknown platform, defaulting to sandbox');
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
