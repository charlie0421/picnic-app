import 'dart:io';
import 'dart:convert';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/constants/purchase_constants.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 이미 처리된 구매에 대한 예외
class ReusedPurchaseException implements Exception {
  final String message;
  final String? receiptId;

  ReusedPurchaseException({
    required this.message,
    this.receiptId,
  });

  @override
  String toString() => 'ReusedPurchaseException: $message';
}

class ReceiptVerificationService {
  static const String _sandboxEnvironment = 'sandbox';
  static const String _productionEnvironment = 'production';

  /// 디버깅용 환경 정보 반환
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
      'storeKitSupport': Platform.isIOS ? 'StoreKit2 Ready' : 'N/A',
    };
  }

  /// 영수증 검증 메인 메서드
  Future<void> verifyReceipt(
    String receipt,
    String productId,
    String userId,
    String environment,
  ) async {
    logger.i('=== Receipt Verification Started ===');
    logger.i('Platform: ${Platform.isIOS ? 'iOS' : 'Android'}');
    logger.i('Environment: $environment');
    logger.i('Product: $productId');

    _validateInputs(receipt, productId, userId);

    final receiptFormat = _detectReceiptFormat(receipt);
    logger.i('Receipt format: $receiptFormat');

    if (Platform.isIOS) {
      await _verifyiOSReceipt(
          receipt, productId, userId, environment, receiptFormat);
    } else {
      await _verifyAndroidReceipt(receipt, productId, userId, environment);
    }

    logger.i('=== Receipt Verification Completed ===');
  }

  /// 입력 값 검증
  void _validateInputs(String receipt, String productId, String userId) {
    if (receipt.isEmpty) {
      throw Exception('영수증 데이터가 비어있습니다');
    }
    if (productId.isEmpty) {
      throw Exception('상품 ID가 비어있습니다');
    }
    if (userId.isEmpty) {
      throw Exception('사용자 ID가 비어있습니다');
    }
  }

  /// 영수증 형식 감지
  String _detectReceiptFormat(String receipt) {
    if (receipt.startsWith('eyJ')) {
      return 'StoreKit2 JWT';
    } else if (receipt.startsWith('MIIT') || receipt.startsWith('MIIK')) {
      return 'StoreKit1 Base64';
    } else if (receipt.contains('.') && receipt.split('.').length == 3) {
      return 'JWT Custom';
    }
    return 'Unknown';
  }

  /// iOS 영수증 검증
  Future<void> _verifyiOSReceipt(
    String receipt,
    String productId,
    String userId,
    String environment,
    String receiptFormat,
  ) async {
    logger.i('iOS receipt verification - Format: $receiptFormat');

    final requestBody = {
      'receipt': receipt,
      'platform': 'ios',
      'productId': productId,
      'user_id': userId,
      'environment': environment,
      'format':
          receiptFormat.contains('StoreKit2 JWT') ? 'storekit2_jwt' : 'legacy',
    };

    await _callVerificationFunction(requestBody, 'iOS');
  }

  /// Android 영수증 검증
  Future<void> _verifyAndroidReceipt(
    String receipt,
    String productId,
    String userId,
    String environment,
  ) async {
    logger.i('🤖 Android 영수증 검증 시작');
    logger.i('  - Product ID: $productId');
    logger.i('  - User ID: $userId');
    logger.i('  - Environment: $environment');
    logger.i('  - Receipt length: ${receipt.length}');

    final requestBody = {
      'receipt': receipt,
      'platform': 'android',
      'productId': productId,
      'user_id': userId,
      'environment': environment,
      'format': 'google_play',
    };

    logger.i('🚀 Android 서버 검증 호출 시작');
    await _callVerificationFunction(requestBody, 'Android');
    logger.i('✅ Android 영수증 검증 완료');
  }

  /// 검증 함수 호출 (재시도 로직 포함)
  Future<void> _callVerificationFunction(
    Map<String, dynamic> requestBody,
    String verificationType,
  ) async {
    // 환경에 따른 타임아웃 설정
    final environment = requestBody['environment'] as String;
    final timeoutDuration = environment == _sandboxEnvironment
        ? PurchaseConstants.sandboxVerificationTimeout
        : PurchaseConstants.verificationTimeout;

    logger.i(
        'Using timeout: ${timeoutDuration.inSeconds}s for $environment environment');

    // 환경에 따른 재시도 횟수 설정
    final maxRetries = environment == _sandboxEnvironment
        ? PurchaseConstants.sandboxMaxRetries
        : PurchaseConstants.maxRetries;
    logger.i('Max retries: $maxRetries for $environment environment');

    Exception? lastException;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        logger.i('$verificationType verification attempt $attempt/$maxRetries');

        await supabase.functions
            .invoke('verify_receipt', body: requestBody) // 함수 이름 변경
            .timeout(timeoutDuration);

        logger.i('Verification successful');
        return; // 성공 시 즉시 반환
      } catch (error) {
        lastException =
            error is Exception ? error : Exception(error.toString());

        // 409 Conflict (중복) 에러인지 확인
        if (error is FunctionException && error.status == 409) {
          logger.w('Duplicate receipt detected (409 Conflict)');
          throw ReusedPurchaseException(
            message: PurchaseConstants.duplicatePurchaseError,
          );
        }
        
        // ReusedPurchaseException은 재시도하지 않음
        if (error is ReusedPurchaseException) {
          rethrow;
        }

        logger.w(
            '$verificationType verification attempt $attempt failed: $error');

        // 마지막 시도가 아니면 재시도
        if (attempt < maxRetries) {
          final delay = PurchaseConstants.baseRetryDelay * attempt;
          logger.i('Retrying in ${delay}s...');
          await Future.delayed(Duration(seconds: delay));
        }
      }
    }

    // 모든 시도 실패 시 처리
    logger.e('All $verificationType verification attempts failed');

    // 🔥 타임아웃의 경우 관대한 처리 (구매는 성공했을 가능성 높음)
    final isTimeout = lastException is TimeoutException ||
        lastException.toString().contains('TimeoutException') ||
        lastException.toString().contains('timeout');

    if (isTimeout) {
      logger.w('⚠️ 영수증 검증 타임아웃 - 관대한 처리 적용');
      logger.w('📝 ${PurchaseConstants.timeoutGracefulHandling}');
      logger.w(
          '🌍 Environment: $environment, Timeout: ${timeoutDuration.inSeconds}s');
      logger.w('🔄 Retries completed: $maxRetries attempts');
      return; // 성공으로 간주
    }

    throw lastException ?? Exception('영수증 검증 실패');
  }



  /// 환경 감지
  Future<String> getEnvironment() async {
    logger.d('Determining environment...');

    if (kDebugMode) {
      logger.d('Debug mode detected - using sandbox');
      return _sandboxEnvironment;
    }

    final packageInfo = await PackageInfo.fromPlatform();
    logger.d('Package info: ${packageInfo.installerStore}');

    if (Platform.isIOS) {
      return _getIOSEnvironment(packageInfo);
    } else {
      return _getAndroidEnvironment(packageInfo);
    }
  }

  /// iOS 환경 감지
  String _getIOSEnvironment(PackageInfo packageInfo) {
    final installerStore = packageInfo.installerStore;

    // 테스트 환경 감지
    final isTestEnvironment = installerStore == 'com.apple.testflight' ||
        installerStore == null ||
        packageInfo.appName.toLowerCase().contains('testflight') ||
        packageInfo.buildSignature.isNotEmpty;

    final environment =
        isTestEnvironment ? _sandboxEnvironment : _productionEnvironment;
    logger.d('iOS environment: $environment');
    return environment;
  }

  /// Android 환경 감지
  String _getAndroidEnvironment(PackageInfo packageInfo) {
    final installerStore = packageInfo.installerStore;

    // Google Play가 아닌 경우 샌드박스
    final environment = installerStore != 'com.android.vending'
        ? _sandboxEnvironment
        : _productionEnvironment;

    logger.d('Android environment: $environment');
    return environment;
  }

  /// StoreKit2 JWT 형식 감지
  static bool isStoreKit2JWT(String receiptData) {
    try {
      return receiptData.startsWith('eyJ') &&
          receiptData.split('.').length == 3;
    } catch (e) {
      return false;
    }
  }

  /// JWT 부분 디코딩 헬퍼
  static Map<String, dynamic> _decodeJWTPart(String part) {
    // Base64URL 디코딩을 위한 패딩 추가
    String normalized = part.replaceAll('-', '+').replaceAll('_', '/');
    while (normalized.length % 4 != 0) {
      normalized += '=';
    }

    final decoded = base64.decode(normalized);
    return json.decode(utf8.decode(decoded));
  }

  /// 통합 영수증 검증 (정적 메서드)
  static Future<Map<String, dynamic>> verifyReceiptV2({
    required String receiptData,
    required String productId,
    required String transactionId,
    String? packageName,
  }) async {
    logger.i('Starting unified receipt verification');
    logger.i('Product: $productId, Transaction: $transactionId');

    try {
      if (isStoreKit2JWT(receiptData)) {
        logger.i('Detected StoreKit2 JWT receipt');
        return await _verifyStoreKit2Receipt(
          jwtToken: receiptData,
          productId: productId,
          transactionId: transactionId,
        );
      } else {
        logger.i('Detected Legacy receipt');
        return {
          'status': 0,
          'receipt_type': 'Legacy',
          'validation_method': 'Server Required',
          'message': 'Legacy receipt requires server verification',
        };
      }
    } catch (e) {
      logger.e('Receipt verification error: $e');
      return {
        'status': 21000,
        'error': 'Receipt verification failed: $e',
        'receipt_type': 'Unknown',
      };
    }
  }

  /// StoreKit2 JWT 영수증 검증 (정적 메서드)
  static Future<Map<String, dynamic>> _verifyStoreKit2Receipt({
    required String jwtToken,
    required String productId,
    required String transactionId,
  }) async {
    try {
      logger.i('Verifying StoreKit2 JWT receipt');

      final jwtParts = jwtToken.split('.');
      if (jwtParts.length != 3) {
        throw Exception('Invalid JWT format');
      }

      // JWT 헤더와 페이로드 디코딩
      final headerDecoded = _decodeJWTPart(jwtParts[0]);
      final payloadDecoded = _decodeJWTPart(jwtParts[1]);

      logger.d('JWT validated - Algorithm: ${headerDecoded['alg']}');

      if (payloadDecoded['transactionId'] != null) {
        logger.d('Transaction found: ${payloadDecoded['transactionId']}');
      }

      return {
        'status': 0,
        'receipt_type': 'StoreKit2_JWT',
        'transaction_id': transactionId,
        'product_id': productId,
        'jwt_token': jwtToken,
        'validation_method': 'format_check',
        'message': 'StoreKit2 JWT format validated'
      };
    } catch (e) {
      logger.e('StoreKit2 JWT verification failed: $e');
      return {
        'status': -1,
        'error': 'JWT verification failed: $e',
        'receipt_type': 'StoreKit2_JWT_ERROR'
      };
    }
  }
}
