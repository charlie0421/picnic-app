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
import 'package:picnic_lib/core/services/purchase_failure_classifier.dart';
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

/// 서버가 이 영수증을 영구 거부(비재시도)했는지.
///
/// **클라이언트 큐의 재전송을 멈추는 판정에만 쓴다.** 스토어 트랜잭션
/// (StoreKit finish / Play consume·acknowledge) 파괴에는 절대 쓰지 않는다
/// — 오판 시 과금된 영수증이 소멸하고, Android는 미승인 구매의 3일 자동
/// 환불이라는 사용자 구제책까지 차단하기 때문이다. 큐 항목 제거는
/// 오판해도 스토어측 재전달·reconcile 경로가 남는다.
///
/// 서버의 명시적 비재시도 판정인 422만 포함한다:
/// - 400 제외: wallet.v1 verify_receipt의 핸들러 catch-all이 임의 예외를
///   400으로 돌려주므로 일시 오류가 섞인다.
/// - 403 제외: 레거시 검증 서버는 IP 차단에도 403을 주므로 영수증 자체에
///   대한 영구 판정이 아니다.
/// - 409 제외: 중복은 [ReusedPurchaseException.grantConfirmed]가 소비
///   안전 여부를 따로 판정한다.
/// - 401·5xx·타임아웃 제외: 재시도로 회복될 수 있다.
bool isPermanentSettlementRejection(Object? error) =>
    error is FunctionException && error.status == 422;

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

  /// Whether this build talks to StoreKit.
  ///
  /// Injectable because the iOS-only idempotency-cache branch of
  /// [verifyReceipt] is where a re-delivered transaction is decided, and a host
  /// test (`Platform.isIOS == false`) could otherwise never reach it.
  @visibleForTesting
  bool isIOSPlatform = Platform.isIOS;

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
    String environment, {
    String? clientObservedCurrency,
  }) async {
    if (Environment.isInitialized &&
        Environment.currentEnvironment != 'test' &&
        !isPaymentEnvironmentAllowed(
          buildEnvironment: Environment.currentEnvironment,
          requestedEnvironment: environment,
        )) {
      throw StateError('Payment environment rejected by build policy');
    }
    logger.i('=== Receipt Verification Started ===');
    logger.i('Platform: ${isIOSPlatform ? 'iOS' : 'Android'}');
    logger.i('Environment: $environment');
    logger.i('Product: $productId');

    _validateInputs(receipt, productId, userId);

    final receiptFormat = _detectReceiptFormat(receipt);
    logger.i('Receipt format: $receiptFormat');

    // 이 영수증에 대해 실제로 전송한 요청 수 (replay 귀속 판별용)
    final sentRequests = SentVerificationRequests();

    final result = isIOSPlatform
        ? await _verifyiOSWithIdempotency(
            receipt,
            productId,
            userId,
            environment,
            receiptFormat,
            sentRequests,
            clientObservedCurrency,
          )
        : await _settleOrPromoteDuplicate(
            run: () => _verifyAndroidReceipt(
              receipt,
              productId,
              userId,
              environment,
              sentRequests,
              clientObservedCurrency,
            ),
            receipt: receipt,
            productId: productId,
            userId: userId,
            environment: environment,
            receiptFormat: receiptFormat,
          );

    logger.i('=== Receipt Verification Completed ===');
    return result;
  }

  /// iOS 검증 + 동일 JWS 재전달 처리 (멱등 키: transactionId + signedDate).
  ///
  /// iOS 는 서버 정산이 확인되지 않은 트랜잭션을 **절대** finish 하지 않는다
  /// (과금-미적립 방지). 그 결과 아직 finish 되지 않은 과거 트랜잭션은
  /// StoreKit 이 새 구매와 나란히, 앱 실행마다 다시 전달한다 — 정상 동작이다.
  ///
  /// 예전에는 그 재전달이 이 멱등 캐시에 걸리는 순간
  /// [ReusedPurchaseException] 이 되어 `ERR_PREV_TX` → "이전 결제가 스토어에서
  /// 처리 중입니다. 잠시 후 다시 시도해 주세요." 로 보고됐다. 이미 지급까지
  /// 끝난 구매에 대한 거짓 경고이고, 연속 구매 중이던 사용자에게는 방금 성공한
  /// 결제가 실패한 것처럼 보였다 (1.3.0 TestFlight patch 8).
  ///
  /// 지금은 로컬 기억으로 추측하지 않고 서버에 다시 묻는다: wallet.v1 인테이크는
  /// 이미 아는 트랜잭션에 REPLAY(200 + 정본 정산)로 답하므로 이 질문은 싸고
  /// 멱등하다. 서버에 닿지 못한 경우에만 로컬 기록으로 폴백한다.
  Future<PurchaseSettlementResultModel> _verifyiOSWithIdempotency(
    String receipt,
    String productId,
    String userId,
    String environment,
    String receiptFormat,
    SentVerificationRequests sentRequests,
    String? clientObservedCurrency,
  ) async {
    try {
      final idemKey = _makeIdemKeyFromJWS(receipt);
      if (await _idemCacheContains(idemKey)) {
        logger.w('🍎 이미 정산한 JWS 재전달 - 서버에 정산 상태 재확인: $idemKey');
        final settled = await confirmSettlementWithServer(
          receipt: receipt,
          productId: productId,
          userId: userId,
          environment: environment,
          receiptFormat: receiptFormat,
          // 이 캐시에 있는 영수증은 이미 정산되어 사용자가 결과를 본 것이다.
          alreadyPresented: true,
        );
        if (settled != null) {
          // 큐 항목은 여기서 지우지 않는다. 이 영수증의 정산은 끝났지만 그
          // 매출 이벤트는 아직 outbox 로 넘어가지 않았고, 지금 지우면 저장이
          // 실패하는 동안 프로세스가 죽었을 때 복구 재료가 사라진다. 실제
          // 제거는 durable 저장을 확인한 호출부가 한다.
          return settled.copyWith(
            receiptQueueClientTraceId: ReceiptQueueService.iosClientTraceId(
              receipt,
            ),
          );
        }
        // 서버 판정을 얻지 못했다. 이 캐시는 200 정산 직후에만 기록되므로
        // (아래 _idemCacheAdd) 지급은 확정된 것으로 다룬다 — grantConfirmed 를
        // 세워야 상위가 트랜잭션을 finish 해서 재전달 루프가 끊긴다.
        throw ReusedPurchaseException(
          message: 'Duplicate iOS receipt',
          grantConfirmed: true,
        );
      }

      final result = await _settleOrPromoteDuplicate(
        run: () => _verifyiOSReceipt(
          receipt,
          productId,
          userId,
          environment,
          receiptFormat,
          sentRequests,
          clientObservedCurrency,
        ),
        receipt: receipt,
        productId: productId,
        userId: userId,
        environment: environment,
        receiptFormat: receiptFormat,
      );
      // 캐시 쓰기 실패가 아래 폴백을 타고 정산 요청을 한 번 더 보내서는
      // 안 된다 - 정산은 이미 끝났다.
      try {
        await _idemCacheAdd(idemKey);
      } catch (e) {
        logger.w('🍎 멱등 캐시 기록 실패(정산은 이미 확정): $e');
      }
      return result;
    } catch (e) {
      if (e is ReusedPurchaseException) {
        // 중복 판정은 그대로 상위로 전달한다 (상위가 지급 확정 여부로 갈린다).
        rethrow;
      }
      if (e is ReceiptResponseContractException) {
        // 서버 정산은 이미 끝났고 응답만 해석하지 못한 상태 → 재전송 금지
        rethrow;
      }
      if (PurchaseFailureClassifier.isPermanentRejection(e)) {
        // 서버가 이 본문에 판정을 내렸다 - 다시 보내도 같은 답이다.
        rethrow;
      }
      logger.w('🍎 JWS 파싱/멱등 처리 실패 - 일반 경로로 진행: $e');
      // 같은 카운터를 그대로 넘겨, 위 루프가 이미 보낸 요청도 replay 귀속에 반영한다.
      return await _verifyiOSReceipt(
        receipt,
        productId,
        userId,
        environment,
        receiptFormat,
        sentRequests,
        clientObservedCurrency,
      );
    }
  }

  /// 중복(409) 판정을 서버의 정산 응답으로 승격시킨다.
  ///
  /// 레거시 `verify_receipt` 는 "영수증 행만 있고 지급은 실패했다" 와
  /// "지급까지 끝났다" 를 **둘 다** 409 로 답한다. 그 구분을 클라이언트가
  /// 로컬 정보로 추측하면 이미 지급된 구매를 실패로 안내하거나(=거짓 경고),
  /// 미지급 구매를 성공으로 안내하게 된다. 그래서 서버에 정본 정산을 한 번 더
  /// 물어보고, 답이 정산이면 그 정산으로 계속 진행한다.
  ///
  /// 서버가 정산을 확인해 주지 못하면 원래의 중복 예외를 그대로 올려보낸다 —
  /// 그 경로는 트랜잭션을 보존한다.
  Future<PurchaseSettlementResultModel> _settleOrPromoteDuplicate({
    required Future<PurchaseSettlementResultModel> Function() run,
    required String receipt,
    required String productId,
    required String userId,
    required String environment,
    required String receiptFormat,
  }) async {
    try {
      return await run();
    } on ReusedPurchaseException catch (e) {
      if (e.grantConfirmed) rethrow;
      logger.w('♻️ 지급 미확정 중복 - 서버에 정산 상태 재확인');
      final settled = await confirmSettlementWithServer(
        receipt: receipt,
        productId: productId,
        userId: userId,
        environment: environment,
        receiptFormat: receiptFormat,
        // 지급이 확인되지 않은 중복은 사용자가 아무 결과도 보지 못한
        // 상태다 - 정산이 확인되면 정본 영수증을 보여줘야 한다.
        alreadyPresented: false,
      );
      if (settled == null) rethrow;
      logger.w('♻️ 중복 판정이 서버 정산으로 확인됨 - 정산 성공으로 처리');
      return settled;
    }
  }

  /// 서버에 "이 영수증은 이미 정산됐는가" 를 다시 묻는다.
  ///
  /// 큐에 적재하지 않는다: 이 호출은 새 결제의 최초 전송이 아니라 이미
  /// 정산됐을 가능성이 큰 영수증의 상태 조회이고, Android 큐 키는 난수라
  /// 적재하면 같은 구매가 큐에 계속 쌓인다.
  ///
  /// `null` 은 "서버 판정을 얻지 못했다" 는 뜻이다(네트워크·타임아웃·다시
  /// 중복 응답·영구 거부). 호출자는 그때 로컬 정보로 폴백한다.
  @visibleForTesting
  Future<PurchaseSettlementResultModel?> confirmSettlementWithServer({
    required String receipt,
    required String productId,
    required String userId,
    required String environment,
    required String receiptFormat,
    required bool alreadyPresented,
  }) async {
    try {
      final settlement = await callVerificationFunction(
        _requestBodyFor(
          receipt: receipt,
          productId: productId,
          userId: userId,
          environment: environment,
          receiptFormat: receiptFormat,
          clientTraceId: 'reverify-${DateTime.now().millisecondsSinceEpoch}',
        ),
        isIOSPlatform ? 'iOS' : 'Android',
        SentVerificationRequests(),
      );
      // 재전달은 사용자가 이미 영수증을 본 정산이다 → `replayed` 를 그대로
      // 두어 공용 다이얼로그가 "재전달 안내" 로 라우팅되게 한다. 반대로
      // 지급 미확정 중복은 아무것도 보지 못한 상태이므로 정본 영수증을
      // 보여줘야 한다 (`replayCausedByRetry` 의 정의 그대로: 우리가 만든
      // replay 이고 사용자는 아직 아무것도 못 봤다).
      return alreadyPresented || !settlement.replayed
          ? settlement
          : settlement.copyWith(replayCausedByRetry: true);
    } catch (e) {
      logger.w('중복 영수증의 서버 정산 재확인 실패 - 로컬 판정으로 폴백: $e');
      return null;
    }
  }

  /// verify-receipt-v2 요청 본문.
  ///
  /// 플랫폼 분기와 [ReceiptFormatHelper] 접촉을 한곳으로 모은다 — 정산 상태를
  /// 다시 묻는 경로가 최초 전송과 다른 본문을 보내면 서버는 다른 트랜잭션으로
  /// 읽는다. (`clientTraceId` 는 Android 본문에만 실린다.)
  Map<String, dynamic> _requestBodyFor({
    required String receipt,
    required String productId,
    required String userId,
    required String environment,
    required String receiptFormat,
    required String clientTraceId,
    String? clientObservedCurrency,
  }) => isIOSPlatform
      ? ReceiptFormatHelper.buildIOSRequestBody(
          receipt: receipt,
          productId: productId,
          userId: userId,
          environment: environment,
          receiptFormat: receiptFormat,
          clientObservedCurrency: clientObservedCurrency,
        )
      : ReceiptFormatHelper.buildAndroidRequestBody(
          receipt: receipt,
          productId: productId,
          userId: userId,
          environment: environment,
          clientTraceId: clientTraceId,
          clientObservedCurrency: clientObservedCurrency,
        );

  /// analytics outbox 가 이 정산을 durable 하게 넘겨받은 뒤 큐 항목을 비운다.
  Future<void> releaseQueuedReceipt(String clientTraceId) =>
      ReceiptQueueService().removeByClientTraceId(clientTraceId);

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
    String? clientObservedCurrency,
  ) async {
    logger.i('iOS receipt verification - Format: $receiptFormat');

    // iOS 도 검증 전에 큐에 적재한다. 검증이 중단되면(앱 강제 종료, 네트워크
    // 단절) 이 항목이 클라이언트에 남는 유일한 durable 기록이고, 없으면
    // 사용자가 스토어에 다시 진입할 때까지 복구 계기가 아예 없다.
    // 키는 StoreKit transactionId 기반이라 미완료 트랜잭션 재전달과 아래
    // JWS 폴백 재검증이 큐를 부풀리지 않는다.
    //
    // 적재는 "검증 재전송" 만 가능하게 한다 — 미확인 스토어 트랜잭션을
    // finish/consume 하는 판단에는 절대 관여하지 않는다.
    final clientTraceId = await ReceiptQueueService().enqueue(
      platform: ReceiptQueueService.platformIOS,
      receipt: receipt,
      productId: productId,
      userId: userId,
      environment: environment,
      clientObservedCurrency: clientObservedCurrency,
    );

    final requestBody = _requestBodyFor(
      receipt: receipt,
      productId: productId,
      userId: userId,
      environment: environment,
      receiptFormat: receiptFormat,
      clientTraceId: clientTraceId,
      clientObservedCurrency: clientObservedCurrency,
    );

    final result = await callVerificationFunction(
      requestBody,
      'iOS',
      sentRequests,
    );
    // 정산이 끝났다고 곧바로 큐를 비우지 않는다. 이 항목은 이 거래의 매출을
    // 되살릴 마지막 재료이고, analytics outbox 가 그 소유권을 넘겨받았다고
    // 확인되기 전에 버리면 그 사이의 실패가 곧 영구 유실이다. 실제 제거는
    // 호출부가 durable 저장을 확인한 뒤 releaseQueuedReceipt 로 한다.
    return result.copyWith(receiptQueueClientTraceId: clientTraceId);
  }

  /// Android 영수증 검증
  Future<PurchaseSettlementResultModel> _verifyAndroidReceipt(
    String receipt,
    String productId,
    String userId,
    String environment,
    SentVerificationRequests sentRequests,
    String? clientObservedCurrency,
  ) async {
    logger.i('🤖 Android 영수증 검증 시작');
    logger.i('  - Product ID: $productId');
    logger.i('  - User ID: $userId');
    logger.i('  - Environment: $environment');
    logger.i('  - Receipt length: ${receipt.length}');

    // 큐에 적재하고 client_trace_id 생성
    final clientTraceId = await ReceiptQueueService().enqueue(
      platform: ReceiptQueueService.platformAndroid,
      receipt: receipt,
      productId: productId,
      userId: userId,
      environment: environment,
      clientObservedCurrency: clientObservedCurrency,
    );

    final requestBody = _requestBodyFor(
      receipt: receipt,
      productId: productId,
      userId: userId,
      environment: environment,
      receiptFormat: ReceiptFormatHelper.verificationFormatFor(
        platform: ReceiptQueueService.platformAndroid,
        receipt: receipt,
      ),
      clientTraceId: clientTraceId,
      clientObservedCurrency: clientObservedCurrency,
    );

    logger.i('🚀 Android 서버 검증 호출 시작 (clientTrace: $clientTraceId)');
    try {
      final result = await callVerificationFunction(
        requestBody,
        'Android',
        sentRequests,
      );
      // 큐 제거는 analytics outbox 가 이 매출 이벤트를 durable 하게 넘겨받은
      // 뒤에 호출부가 한다(releaseQueuedReceipt). 여기서 먼저 비우면 저장
      // 실패와 스토어 consume 사이에 복구 재료가 사라진다.
      logger.i('✅ Android 영수증 검증 완료');
      return result.copyWith(receiptQueueClientTraceId: clientTraceId);
    } catch (e) {
      if (isPermanentSettlementRejection(e)) {
        // 영구 거부(422) 영수증을 큐에 남기면 앱 시작마다 재전송만 된다.
        await ReceiptQueueService().removeByClientTraceId(clientTraceId);
        logger.w('🚫 서버 영구 거부 - 큐에서 제거 (clientTrace: $clientTraceId)');
      } else if (e is ReusedPurchaseException && e.grantConfirmed) {
        // 지급까지 확정된 중복은 정산이 끝난 영수증이다. 큐에 남겨 두면
        // 같은 409를 영원히 다시 받는다. 지급이 확인되지 않은 중복
        // (grantConfirmed == false)은 큐 항목이 유일한 재시도 수단이므로
        // 반드시 남긴다.
        await ReceiptQueueService().removeByClientTraceId(clientTraceId);
        logger.w('♻️ 지급 확정 중복 - 큐에서 제거 (clientTrace: $clientTraceId)');
      }
      rethrow;
    }
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
              .invoke(PurchaseConstants.receiptVerificationFunction,
                  body: requestBody)
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

        // 서버가 이 요청에 대해 판정을 내린 실패(422 비재시도 / 400 계약
        // 위반 / 403 거부)는 같은 본문을 다시 보내도 같은 답이 온다.
        // 그런데도 루프를 계속 돌리면 사용자를 2초+4초 더 붙잡아 둔 뒤
        // 같은 실패를 알리게 되고, 그 사이에 90초 안전망이 먼저 울려
        // "구매 처리 지연" 팝업과 오류 다이얼로그가 겹친다. 즉시 실패시켜
        // 정확한 안내로 빠진다.
        //
        // 이 fail-fast 가 안전한 이유는 여기서 아무것도 파괴하지 않기
        // 때문이다: 스토어 트랜잭션은 미확정으로 남고(handleOptimizedPurchase
        // 의 finally), 큐 항목은 422 에서만 제거된다
        // (isPermanentSettlementRejection). 정말로 일시 오류였던 400 은
        // 다음 실행의 재전달·큐 플러시가 다시 시도한다.
        if (PurchaseFailureClassifier.isPermanentRejection(error)) {
          logger.e(
            '$verificationType verification rejected by the server '
            '(status ${(error as FunctionException).status}) - not retrying',
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
    // Set 은 삽입 순서를 보장하지 않으므로, FIFO 로 오래된 키를 잘라내려면
    // 리스트로 다뤄야 한다.
    final existing = sp.getStringList(_spKeySentReceipts) ?? <String>[];
    final list = existing.where((k) => k != key).toList()..add(key);
    final overflow = list.length - PurchaseConstants.maxIdemCacheEntries;
    final trimmed = overflow > 0 ? list.sublist(overflow) : list;
    await sp.setStringList(_spKeySentReceipts, trimmed);
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
