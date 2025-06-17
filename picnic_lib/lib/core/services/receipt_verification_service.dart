import 'dart:io';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/constants/purchase_constants.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:http/http.dart' as http;

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
  static const String _appleVerifyUrl =
      'https://buy.itunes.apple.com/verifyReceipt';
  static const String _appleSandboxUrl =
      'https://sandbox.itunes.apple.com/verifyReceipt';

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
    logger.i('Android receipt verification');

    final requestBody = {
      'receipt': receipt,
      'platform': 'android',
      'productId': productId,
      'user_id': userId,
      'environment': environment,
      'format': 'google_play',
    };

    await _callVerificationFunction(requestBody, 'Android');
  }

  /// 검증 함수 호출 (재시도 로직 포함)
  Future<void> _callVerificationFunction(
    Map<String, dynamic> requestBody,
    String verificationType,
  ) async {
    Exception? lastException;

    for (int attempt = 1; attempt <= PurchaseConstants.maxRetries; attempt++) {
      try {
        logger.i(
            '$verificationType verification attempt $attempt/${PurchaseConstants.maxRetries}');

        final response = await supabase.functions
            .invoke('verify_receipt', body: requestBody)
            .timeout(PurchaseConstants.verificationTimeout);

        logger.i('Verification successful');

        // 재사용 검증 우선 확인
        if (_isReusedPurchase(response.data)) {
          final reusedInfo = _extractReusedInfo(response.data);
          throw ReusedPurchaseException(
            message: reusedInfo['message'] ??
                PurchaseConstants.duplicatePurchaseError,
            receiptId: reusedInfo['receiptId'],
          );
        }

        // 성공 시 즉시 반환
        return;
      } catch (error) {
        lastException =
            error is Exception ? error : Exception(error.toString());

        // ReusedPurchaseException은 재시도하지 않음
        if (error is ReusedPurchaseException) {
          rethrow;
        }

        logger.w(
            '$verificationType verification attempt $attempt failed: $error');

        // 마지막 시도가 아니면 재시도
        if (attempt < PurchaseConstants.maxRetries) {
          final delay = PurchaseConstants.baseRetryDelay * attempt;
          logger.i('Retrying in ${delay}s...');
          await Future.delayed(Duration(seconds: delay));
        }
      }
    }

    // 모든 시도 실패 시 예외 발생
    logger.e('All $verificationType verification attempts failed');
    throw lastException ?? Exception('영수증 검증 실패');
  }

  /// 재사용된 구매인지 확인
  bool _isReusedPurchase(dynamic responseData) {
    if (responseData == null) return false;

    // 직접 reused 필드 확인
    if (responseData['reused'] == true) return true;

    // data 필드 내부 확인
    final data = responseData['data'];
    if (data != null && data['reused'] == true) return true;

    return false;
  }

  /// 재사용 정보 추출
  Map<String, String?> _extractReusedInfo(dynamic responseData) {
    if (responseData == null) {
      return {'message': null, 'receiptId': null};
    }

    // 직접 필드에서 추출
    if (responseData['reused'] == true) {
      return {
        'message': responseData['message']?.toString(),
        'receiptId': responseData['receipt_id']?.toString(),
      };
    }

    // data 필드에서 추출
    final data = responseData['data'];
    if (data != null && data['reused'] == true) {
      return {
        'message': data['message']?.toString(),
        'receiptId': data['receipt_id']?.toString(),
      };
    }

    return {'message': null, 'receiptId': null};
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
