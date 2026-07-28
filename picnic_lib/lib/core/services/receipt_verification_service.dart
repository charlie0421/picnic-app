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
import 'package:picnic_lib/core/services/auth/edge_auth_retry.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/data/models/purchase/purchase_settlement_result.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 이미 처리된 구매에 대한 예외
class ReusedPurchaseException implements Exception {
  final String message;
  final String? receiptId;

  /// 서버 응답이 "보상 지급까지 완료된 중복"임을 확인한 경우 true.
  ///
  /// 서버는 영수증 행만 있고 보상 지급이 실패한 경우에도 409를 반환하므로,
  /// 이 값이 true일 때만 구매를 완료(consume)해도 안전하다. false면 구매를
  /// 남겨 두어야 큐/reconcile이 재시도할 수 있다.
  final bool grantConfirmed;

  ReusedPurchaseException({
    required this.message,
    this.receiptId,
    this.grantConfirmed = false,
  });

  @override
  String toString() => 'ReusedPurchaseException: $message';
}

/// 응답은 정상적으로 도착했지만 정산 계약(스키마)을 만족하지 않아
/// 해석할 수 없는 경우의 예외.
///
/// 서버는 이미 정산을 마친 상태이므로 재전송은 중복 요청만 만든다.
/// 따라서 이 예외는 재시도 대상이 아니며, "응답을 못 받은" 네트워크/타임아웃
/// 실패와 구분되어 상위로 전달된다.
class ReceiptResponseContractException implements Exception {
  final String message;
  final Object? cause;

  ReceiptResponseContractException({required this.message, this.cause});

  @override
  String toString() => 'ReceiptResponseContractException: $message';
}

/// verify_receipt 요청을 실제로 몇 번 전송했는지 세는 카운터.
///
/// Counts the verify_receipt requests this client actually put on the wire for
/// one receipt - across the retry loop and across the iOS fallback that starts
/// a second loop. A `replayed` settlement answering the very first request was
/// settled by somebody else (an earlier delivery or session); answering any
/// later request it was settled by a request of ours whose response was lost,
/// which is a replay we caused and the user has not seen.
@visibleForTesting
class SentVerificationRequests {
  int count = 0;
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
    if (Environment.isInitialized &&
        Environment.currentEnvironment != 'test' &&
        !isPaymentEnvironmentAllowed(
          buildEnvironment: Environment.currentEnvironment,
          requestedEnvironment: environment,
        )) {
      throw StateError('Payment environment rejected by build policy');
    }
    logger.i('=== Receipt Verification Started ===');
    logger.i('Platform: ${Platform.isIOS ? 'iOS' : 'Android'}');
    logger.i('Environment: $environment');
    logger.i('Product: $productId');

    _validateInputs(receipt, productId, userId);

    final receiptFormat = _detectReceiptFormat(receipt);
    logger.i('Receipt format: $receiptFormat');

    // 이 영수증에 대해 실제로 전송한 요청 수 (replay 귀속 판별용)
    final sentRequests = SentVerificationRequests();

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
          sentRequests,
        );
        await _idemCacheAdd(idemKey);
      } catch (e) {
        if (e is ReusedPurchaseException) {
          // 중복은 그대로 상위로 전달하여 성공 플로우를 막는다
          rethrow;
        }
        if (e is ReceiptResponseContractException) {
          // 서버 정산은 이미 끝났고 응답만 해석하지 못한 상태 → 재전송 금지
          rethrow;
        }
        logger.w('🍎 JWS 파싱/멱등 처리 실패 - 일반 경로로 진행: $e');
        // 같은 카운터를 그대로 넘겨, 위 루프가 이미 보낸 요청도 replay 귀속에 반영한다.
        result = await _verifyiOSReceipt(
          receipt,
          productId,
          userId,
          environment,
          receiptFormat,
          sentRequests,
        );
      }
    } else {
      result = await _verifyAndroidReceipt(
        receipt,
        productId,
        userId,
        environment,
        sentRequests,
      );
    }

    logger.i('=== Receipt Verification Completed ===');
    return result;
  }

  @visibleForTesting
  static bool isPaymentEnvironmentAllowed({
    required String buildEnvironment,
    required String requestedEnvironment,
  }) {
    if (buildEnvironment == 'prod') {
      return requestedEnvironment == _productionEnvironment;
    }
    if (buildEnvironment == 'local' || buildEnvironment == 'dev') {
      return requestedEnvironment == _sandboxEnvironment;
    }
    return false;
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
    SentVerificationRequests sentRequests,
  ) async {
    logger.i('iOS receipt verification - Format: $receiptFormat');

    final requestBody = ReceiptFormatHelper.buildIOSRequestBody(
      receipt: receipt,
      productId: productId,
      userId: userId,
      environment: environment,
      receiptFormat: receiptFormat,
    );

    return callVerificationFunction(requestBody, 'iOS', sentRequests);
  }

  /// Android 영수증 검증
  Future<PurchaseSettlementResultModel> _verifyAndroidReceipt(
    String receipt,
    String productId,
    String userId,
    String environment,
    SentVerificationRequests sentRequests,
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
    final result = await callVerificationFunction(
      requestBody,
      'Android',
      sentRequests,
    );
    // 성공 시 큐에서 제거
    await ReceiptQueueService().removeByClientTraceId(clientTraceId);
    logger.i('✅ Android 영수증 검증 완료');
    return result;
  }

  /// 검증 함수 호출 (재시도 로직 포함)
  /// 검증 재시도 루프 본체. 플랫폼 분기(iOS/Android 요청 구성) 밖의 공통
  /// 경로라서 테스트가 직접 진입한다 — 401 auth 복구와 fail-fast 는 여기서
  /// 고정된다.
  @visibleForTesting
  Future<PurchaseSettlementResultModel> callVerificationFunction(
    Map<String, dynamic> requestBody,
    String verificationType,
    SentVerificationRequests sentRequests,
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
      // 이 요청을 보내기 전에 이미 보낸 요청이 있으면, 돌아온 replay 는 우리가
      // 만든 것이다: 앞선 요청이 서버에서 정산됐고 응답만 유실된 경우이므로
      // 사용자는 아직 아무것도 보지 못했다.
      final replayWouldAnswerOurOwnRequest = sentRequests.count > 0;
      sentRequests.count++;
      try {
        logger.i('$verificationType verification attempt $attempt/$maxRetries');

        // 액세스 토큰이 만료된 채 도착하면 게이트웨이가 함수 실행 전에
        // 401 을 돌려준다. 결제 시트에 머무는 동안 토큰이 만료되는 것은
        // 정상 시나리오라(실측: 스테이징에서 8회 연속 401), 같은 토큰으로
        // 재시도만 반복하면 전부 실패한다 — 투표 경로와 동일하게 401 이면
        // 세션을 갱신하고 한 번 더 시도한다.
        final response = await invokeWithAuthRecovery(
          invoke: () => supabase.functions
              .invoke('verify_receipt', body: requestBody)
              .timeout(timeoutDuration),
          refresh: () async {
            logger.w(
              '$verificationType verification got 401 - refreshing session',
            );
            final refreshed = await supabase.auth.refreshSession();
            final ok = refreshed.session != null;
            logger.i(
              'Session refresh ${ok ? 'succeeded' : 'failed'} for '
              '$verificationType verification retry',
            );
            return ok;
          },
        );

        logger.i('Verification successful');
        // 응답이 도착한 뒤의 파싱 실패는 영구적인 계약 오류이므로
        // 전송 실패(재시도 대상)와 분리해서 처리한다.
        try {
          if (response.data is! Map) {
            throw const FormatException(
              'verify_receipt response must be an object',
            );
          }
          final settlement = PurchaseSettlementResultModel.fromJson(
            Map<String, dynamic>.from(response.data as Map),
          );
          return settlement.replayed && replayWouldAnswerOurOwnRequest
              ? settlement.copyWith(replayCausedByRetry: true)
              : settlement;
        } catch (parseError) {
          throw ReceiptResponseContractException(
            message: 'verify_receipt response could not be parsed: $parseError',
            cause: parseError,
          );
        }
      } catch (error) {
        lastException = error is Exception
            ? error
            : Exception(error.toString());

        // 409 Conflict (중복) 에러인지 확인
        if (error is FunctionException && error.status == 409) {
          logger.w('Duplicate receipt detected (409 Conflict)');
          throw ReusedPurchaseException(
            message: PurchaseConstants.errPrevTransactionPending,
            grantConfirmed: ReceiptQueueService.duplicateConfirmsGrant(
              error.details,
            ),
          );
        }

        // ReusedPurchaseException은 재시도하지 않음
        if (error is ReusedPurchaseException) {
          rethrow;
        }

        // 세션 갱신까지 실패한 401 은 재시도해도 같은 결과다 — 백오프
        // 루프로 사용자를 붙잡아 두는 대신 즉시 실패시켜 오류 안내로
        // 빠진다. (StoreKit 트랜잭션은 미완료로 남아 다음 실행에서
        // 재전달되므로 구매가 유실되지 않는다.)
        if (error is EdgeAuthRecoveryException) {
          logger.e(
            '$verificationType verification auth recovery failed '
            '(${error.reason.name}) - not retrying',
          );
          rethrow;
        }

        // 서버 응답을 받았으나 해석할 수 없는 경우는 영구 오류 → 재시도하지 않음
        // (서버는 이미 정산했으므로 재전송하면 중복 요청만 발생)
        if (error is ReceiptResponseContractException) {
          logger.e(
            '$verificationType verification response contract violated - '
            'not retrying: ${error.message}',
          );
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

    if (Environment.isInitialized && Environment.currentEnvironment != 'test') {
      return Environment.paymentEnvironment;
    }

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
