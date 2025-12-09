import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:picnic_lib/core/services/receipt_queue_service.dart';

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
      // iOS: 동일 JWS 재전송 방지 (멱등 키: transactionId + signedDate)
      try {
        final idemKey = _makeIdemKeyFromJWS(receipt);
        if (await _idemCacheContains(idemKey)) {
          logger.w('🍎 동일 JWS 재전송 차단: $idemKey');
          // 중복으로 간주하여 예외를 던져 상위에서 성공 UI를 띄우지 않도록 함
          throw ReusedPurchaseException(message: 'Duplicate iOS receipt');
        }
        await _verifyiOSReceipt(
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
        await _verifyiOSReceipt(
          receipt,
          productId,
          userId,
          environment,
          receiptFormat,
        );
      }
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
      'format': receiptFormat.contains('StoreKit2 JWT')
          ? 'storekit2_jwt'
          : 'legacy',
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

    // 큐에 적재하고 client_trace_id 생성
    final clientTraceId = await ReceiptQueueService().enqueueAndroid(
      receipt: receipt,
      productId: productId,
      userId: userId,
      environment: environment,
    );

    final requestBody = {
      'receipt': receipt,
      'platform': 'android',
      'productId': productId,
      'user_id': userId,
      'environment': environment,
      'format': 'google_play',
      'client_trace_id': clientTraceId,
    };

    logger.i('🚀 Android 서버 검증 호출 시작 (clientTrace: $clientTraceId)');
    await _callVerificationFunction(requestBody, 'Android');
    // 성공 시 큐에서 제거
    await ReceiptQueueService().removeByClientTraceId(clientTraceId);
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

        await supabase.functions
            .invoke('verify_receipt', body: requestBody) // 함수 이름 변경
            .timeout(timeoutDuration);

        logger.i('Verification successful');
        return; // 성공 시 즉시 반환
      } catch (error) {
        lastException = error is Exception
            ? error
            : Exception(error.toString());

        // 409 Conflict (중복) 에러인지 확인
        // 서버에서 409가 반환되면 이미 성공적으로 처리된 영수증임
        // 따라서 에러가 아닌 "이미 완료됨"으로 처리하여 사용자 경험 개선
        if (error is FunctionException && error.status == 409) {
          logger.i('✅ 영수증이 이미 서버에서 처리됨 (409 Conflict) - 성공으로 간주');
          // 기존: 에러 throw → 변경: 정상 완료로 처리
          return; // 성공으로 반환
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
          final delay = PurchaseConstants.baseRetryDelay * attempt;
          logger.i('Retrying in ${delay}s...');
          await Future.delayed(Duration(seconds: delay));
        }
      }
    }

    // 모든 시도 실패 시 처리(타임아웃도 실패로 간주)
    logger.e('All $verificationType verification attempts failed');
    final isTimeout =
        lastException is TimeoutException ||
        lastException.toString().toLowerCase().contains('time');
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
    final installerStore = packageInfo.installerStore;

    // 테스트 환경 감지
    final isTestEnvironment =
        installerStore == 'com.apple.testflight' ||
        installerStore == null ||
        packageInfo.appName.toLowerCase().contains('testflight') ||
        packageInfo.buildSignature.isNotEmpty;

    final environment = isTestEnvironment
        ? _sandboxEnvironment
        : _productionEnvironment;
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

  // ===== iOS JWS 멱등 캐시 (TTL 적용) =====
  static const _spKeySentReceipts = 'sent_receipts_idem_keys_v2';
  static const Duration _idemCacheTTL = Duration(minutes: 5); // 5분 후 만료

  Future<Map<String, int>> _loadIdemCache() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getStringList(_spKeySentReceipts) ?? [];
    final cache = <String, int>{};
    for (final entry in raw) {
      final parts = entry.split('|');
      if (parts.length == 2) {
        cache[parts[0]] = int.tryParse(parts[1]) ?? 0;
      }
    }
    return cache;
  }

  Future<bool> _idemCacheContains(String key) async {
    final cache = await _loadIdemCache();
    final timestamp = cache[key];
    if (timestamp == null) return false;

    final age = DateTime.now().millisecondsSinceEpoch - timestamp;
    if (age > _idemCacheTTL.inMilliseconds) {
      // TTL 만료 - 캐시에서 제거
      await _idemCacheRemove(key);
      logger.i('🍎 JWS 캐시 TTL 만료로 제거: $key');
      return false;
    }
    return true;
  }

  Future<void> _idemCacheAdd(String key) async {
    final sp = await SharedPreferences.getInstance();
    final cache = await _loadIdemCache();

    // 만료된 항목들 정리 (최대 50개 유지)
    final now = DateTime.now().millisecondsSinceEpoch;
    cache.removeWhere((k, v) => now - v > _idemCacheTTL.inMilliseconds);
    if (cache.length >= 50) {
      // 가장 오래된 항목 제거
      final oldest = cache.entries.reduce((a, b) => a.value < b.value ? a : b);
      cache.remove(oldest.key);
    }

    cache[key] = now;
    final entries = cache.entries.map((e) => '${e.key}|${e.value}').toList();
    await sp.setStringList(_spKeySentReceipts, entries);
  }

  Future<void> _idemCacheRemove(String key) async {
    final sp = await SharedPreferences.getInstance();
    final cache = await _loadIdemCache();
    cache.remove(key);
    final entries = cache.entries.map((e) => '${e.key}|${e.value}').toList();
    await sp.setStringList(_spKeySentReceipts, entries);
  }

  String _makeIdemKeyFromJWS(String jws) {
    try {
      if (!isStoreKit2JWT(jws)) return 'raw:${jws.hashCode}';
      final parts = jws.split('.');
      String normalize(String s) {
        s = s.replaceAll('-', '+').replaceAll('_', '/');
        while (s.length % 4 != 0) {
          s += '=';
        }
        return s;
      }

      final payload = json.decode(
        utf8.decode(base64.decode(normalize(parts[1]))),
      );
      final tx =
          (payload['transactionId'] ?? payload['originalTransactionId'] ?? '')
              .toString();
      final time =
          (payload['signedDate'] ??
                  payload['purchaseDate'] ??
                  payload['originalPurchaseDate'] ??
                  '')
              .toString();
      return 'ios:$tx:$time';
    } catch (_) {
      return 'raw:${jws.hashCode}';
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
