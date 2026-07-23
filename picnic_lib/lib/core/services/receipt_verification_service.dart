import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:picnic_lib/core/services/receipt_queue_service.dart';
import 'package:picnic_lib/core/services/receipt_format_helper.dart';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/constants/purchase_constants.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/data/models/purchase/purchase_settlement_result.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 이미 처리된 구매에 대한 예외
class ReusedPurchaseException implements Exception {
  final String message;
  final String? receiptId;

  ReusedPurchaseException({required this.message, this.receiptId});

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
  Future<PurchaseSettlementResultModel> verifyReceipt(
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

    late final PurchaseSettlementResultModel result;
    if (Platform.isIOS) {
      // iOS: 동일 JWS 재전송 방지 (멱등 키: transactionId + signedDate)
      try {
        final idemKey = _makeIdemKeyFromJWS(receipt);
        if (await _idemCacheContains(idemKey)) {
          logger.w('🍎 동일 JWS 재전송 차단: $idemKey');
          // 중복으로 간주하여 예외를 던져 상위에서 성공 UI를 띄우지 않도록 함
          throw ReusedPurchaseException(message: 'Duplicate iOS receipt');
        }
        result = await _verifyiOSReceipt(
          receipt,
          productId,
          userId,
          environment,
          receiptFormat,
        );
        await _idemCacheAdd(idemKey);
      } catch (e) {
        if (e is ReusedPurchaseException) {
          // 중복은 그대로 상위로 전달하여 성공 플로우를 막는다
          rethrow;
        }
        logger.w('🍎 JWS 파싱/멱등 처리 실패 - 일반 경로로 진행: $e');
        result = await _verifyiOSReceipt(
          receipt,
          productId,
          userId,
          environment,
          receiptFormat,
        );
      }
    } else {
      result = await _verifyAndroidReceipt(
        receipt,
        productId,
        userId,
        environment,
      );
    }

    logger.i('=== Receipt Verification Completed ===');
    return result;
  }

  /// 입력 값 검증
  void _validateInputs(String receipt, String productId, String userId) {
    ReceiptFormatHelper.validateInputs(receipt, productId, userId);
  }

  /// 영수증 형식 감지
  String _detectReceiptFormat(String receipt) {
    return ReceiptFormatHelper.detectReceiptFormat(receipt);
  }

  /// iOS 영수증 검증
  Future<PurchaseSettlementResultModel> _verifyiOSReceipt(
    String receipt,
    String productId,
    String userId,
    String environment,
    String receiptFormat,
  ) async {
    logger.i('iOS receipt verification - Format: $receiptFormat');

    final requestBody = ReceiptFormatHelper.buildIOSRequestBody(
      receipt: receipt,
      productId: productId,
      userId: userId,
      environment: environment,
      receiptFormat: receiptFormat,
    );

    return _callVerificationFunction(requestBody, 'iOS');
  }

  /// Android 영수증 검증
  Future<PurchaseSettlementResultModel> _verifyAndroidReceipt(
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

    // 큐에 적재하고 client_trace_id 생성
    final clientTraceId = await ReceiptQueueService().enqueueAndroid(
      receipt: receipt,
      productId: productId,
      userId: userId,
      environment: environment,
    );

    final requestBody = ReceiptFormatHelper.buildAndroidRequestBody(
      receipt: receipt,
      productId: productId,
      userId: userId,
      environment: environment,
      clientTraceId: clientTraceId,
    );

    logger.i('🚀 Android 서버 검증 호출 시작 (clientTrace: $clientTraceId)');
    final result = await _callVerificationFunction(requestBody, 'Android');
    // 성공 시 큐에서 제거
    await ReceiptQueueService().removeByClientTraceId(clientTraceId);
    logger.i('✅ Android 영수증 검증 완료');
    return result;
  }

  /// 검증 함수 호출 (재시도 로직 포함)
  Future<PurchaseSettlementResultModel> _callVerificationFunction(
    Map<String, dynamic> requestBody,
    String verificationType,
  ) async {
    // 환경에 따른 타임아웃 설정
    final environment = requestBody['environment'] as String;
    final timeoutDuration = environment == _sandboxEnvironment
        ? PurchaseConstants.sandboxVerificationTimeout
        : PurchaseConstants.verificationTimeout;

    logger.i(
      'Using timeout: ${timeoutDuration.inSeconds}s for $environment environment',
    );

    // 환경에 따른 재시도 횟수 설정
    final maxRetries = environment == _sandboxEnvironment
        ? PurchaseConstants.sandboxMaxRetries
        : PurchaseConstants.maxRetries;
    logger.i('Max retries: $maxRetries for $environment environment');

    Exception? lastException;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        logger.i('$verificationType verification attempt $attempt/$maxRetries');

        final response = await supabase.functions
            .invoke('verify_receipt', body: requestBody) // 함수 이름 변경
            .timeout(timeoutDuration);

        logger.i('Verification successful');
        if (response.data is! Map) {
          throw const FormatException(
            'verify_receipt response must be an object',
          );
        }
        return PurchaseSettlementResultModel.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );
      } catch (error) {
        lastException = error is Exception
            ? error
            : Exception(error.toString());

        // 409 Conflict (중복) 에러인지 확인
        if (error is FunctionException && error.status == 409) {
          logger.w('Duplicate receipt detected (409 Conflict)');
          throw ReusedPurchaseException(
            message: PurchaseConstants.errPrevTransactionPending,
          );
        }

        // ReusedPurchaseException은 재시도하지 않음
        if (error is ReusedPurchaseException) {
          rethrow;
        }

        logger.w(
          '$verificationType verification attempt $attempt failed: $error',
        );

        // 마지막 시도가 아니면 재시도
        if (attempt < maxRetries) {
          final delay = ReceiptFormatHelper.calculateRetryDelay(
            attempt: attempt,
            baseRetryDelaySeconds: PurchaseConstants.baseRetryDelay,
          );
          logger.i('Retrying in ${delay.inSeconds}s...');
          await Future.delayed(delay);
        }
      }
    }

    // 모든 시도 실패 시 처리(타임아웃도 실패로 간주)
    logger.e('All $verificationType verification attempts failed');
    final isTimeout = ReceiptFormatHelper.isTimeoutError(lastException);
    if (isTimeout) {
      logger.w('⚠️ 영수증 검증 타임아웃 - 실패로 처리 (관대한 처리 비활성화)');
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
    final environment = ReceiptFormatHelper.detectIOSEnvironment(
      installerStore: packageInfo.installerStore,
      appName: packageInfo.appName,
      buildSignature: packageInfo.buildSignature,
    );
    logger.d('iOS environment: $environment');
    return environment;
  }

  /// Android 환경 감지
  String _getAndroidEnvironment(PackageInfo packageInfo) {
    final environment = ReceiptFormatHelper.detectAndroidEnvironment(
      installerStore: packageInfo.installerStore,
    );
    logger.d('Android environment: $environment');
    return environment;
  }

  /// StoreKit2 JWT 형식 감지
  static bool isStoreKit2JWT(String receiptData) {
    return ReceiptFormatHelper.isStoreKit2JWT(receiptData);
  }

  // ===== iOS JWS 멱등 캐시 =====
  static const _spKeySentReceipts = 'sent_receipts_idem_keys';

  Future<Set<String>> _loadIdemCache() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getStringList(_spKeySentReceipts)?.toSet() ?? <String>{};
  }

  Future<bool> _idemCacheContains(String key) async {
    final s = await _loadIdemCache();
    return s.contains(key);
  }

  Future<void> _idemCacheAdd(String key) async {
    final sp = await SharedPreferences.getInstance();
    final s = await _loadIdemCache()
      ..add(key);
    await sp.setStringList(_spKeySentReceipts, s.toList());
  }

  String _makeIdemKeyFromJWS(String jws) {
    return ReceiptFormatHelper.makeIdemKeyFromJWS(jws);
  }

  /// JWT 부분 디코딩 헬퍼
  static Map<String, dynamic> _decodeJWTPart(String part) {
    return ReceiptFormatHelper.decodeJWTPart(part);
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
        'message': 'StoreKit2 JWT format validated',
      };
    } catch (e) {
      logger.e('StoreKit2 JWT verification failed: $e');
      return {
        'status': -1,
        'error': 'JWT verification failed: $e',
        'receipt_type': 'StoreKit2_JWT_ERROR',
      };
    }
  }
}
