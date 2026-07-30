import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'package:picnic_lib/core/constants/purchase_constants.dart';
import 'package:picnic_lib/core/services/auth/edge_auth_retry.dart';
import 'package:picnic_lib/core/services/receipt_format_helper.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 과금된 구매의 검증 요청을 기기에 durable 하게 보관하고 재전송하는 큐.
///
/// ## 큐 계약
/// - **적재 시점**: 검증 요청을 보내기 *직전*. 검증이 중단되면(앱 강제 종료,
///   네트워크 단절) 이 항목이 클라이언트에 남는 유일한 기록이다.
/// - **single-flight**: [flushPending] 은 동시에 하나만 돈다. 두 번째
///   호출자는 진행 중인 플러시에 합류한다.
/// - **항목 단위 read-modify-write**: invoke 전후로 큐를 다시 읽고 해당
///   항목만 갱신/제거한다. 스냅샷 전체를 되쓰지 않으므로 invoke 를 기다리는
///   동안 적재된 새 구매가 사라지지 않는다.
/// - **제거 조건**: 200 정산 성공, 그리고 422(서버의 명시적 영구 거부)뿐.
///   그 외(503·5xx·400·네트워크·타임아웃·401 복구 실패)는 백오프 후 유지.
/// - **스토어 트랜잭션은 절대 건드리지 않는다**: 이 큐는 검증 *재전송*만
///   한다. finish/consume/acknowledge 판단은 상위 구매 경로의 몫이다 —
///   미확인 트랜잭션을 파괴하면 과금된 구매가 소멸한다.
class ReceiptQueueService {
  ReceiptQueueService._internal();
  static final ReceiptQueueService _instance = ReceiptQueueService._internal();
  factory ReceiptQueueService() => _instance;

  static const String _spKey = 'receipt_queue_v1';

  static const String platformAndroid = 'android';
  static const String platformIOS = 'ios';

  /// 플러시 1건당 invoke 타임아웃. 프로덕션 값은
  /// [PurchaseConstants.verificationTimeout].
  ///
  /// 타임아웃이 없으면(과거 동작) 응답이 오지 않는 invoke 하나가 플러시를
  /// 무한히 붙잡고, single-flight 게이트 때문에 이후 모든 플러시가 그
  /// future 에 합류해 큐가 영구 정지한다.
  @visibleForTesting
  Duration flushInvokeTimeout = PurchaseConstants.verificationTimeout;

  /// 진행 중인 플러시(single-flight 게이트).
  Future<void>? _inFlightFlush;

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<List<Map<String, dynamic>>> _loadQueue() async {
    final sp = await _prefs;
    final raw = sp.getString(_spKey);
    if (raw == null || raw.isEmpty) return <Map<String, dynamic>>[];
    try {
      final list = (json.decode(raw) as List<dynamic>)
          .cast<Map<String, dynamic>>();
      return list;
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  Future<void> _saveQueue(List<Map<String, dynamic>> items) async {
    final sp = await _prefs;
    await sp.setString(_spKey, json.encode(items));
  }

  String _generateClientTraceId(String platform) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rand = Random().nextInt(1 << 32).toRadixString(16);
    return '$platform-$ts-$rand';
  }

  /// iOS 큐 키. StoreKit `transactionId` 기반의 결정적 값이다.
  ///
  /// 미완료 StoreKit 트랜잭션은 앱 실행마다 재전달되고, iOS 검증 경로는
  /// JWS 파싱 실패 시 같은 영수증으로 두 번째 루프를 돈다. 키가 매번
  /// 달라지면 같은 트랜잭션이 큐에 계속 쌓이므로 transactionId 로 고정한다.
  /// 파싱할 수 없는 영수증은 null → 난수 키로 폴백한다.
  ///
  /// 프로덕션 API 다: 이미 정산된 트랜잭션의 재전달을 처리하는
  /// `ReceiptVerificationService` 도 이 키로 해당 항목을 큐에서 지운다.
  static String? iosClientTraceId(String receipt) {
    final transactionId = ReceiptFormatHelper.appleTransactionIdFromJWS(receipt);
    return transactionId == null ? null : 'ios-$transactionId';
  }

  /// 검증 요청을 큐에 적재하고 `client_trace_id` 를 돌려준다.
  ///
  /// [platform] 은 `'android'` 또는 `'ios'`. 요청 본문 재구성에 필요한
  /// 필드(receipt/productId/user_id/environment/format)를 모두 저장하므로
  /// [flushPending] 이 플랫폼별로 올바른 본문을 다시 만들 수 있다.
  ///
  /// TODO(receipt-queue): 무한 성장 방어가 없다. `createdAt` 은 기록만 되고
  /// 아무도 읽지 않으며, 영구 거부(422)도 성공도 아닌 항목은 백오프 상한
  /// 5분으로 영원히 재전송된다. TTL·건수 상한과 purchaseToken 기준 upsert 는
  /// 이 패치에서 의도적으로 제외했다(별도 작업).
  Future<String> enqueue({
    required String platform,
    required String receipt,
    required String productId,
    required String userId,
    required String environment,
  }) async {
    final normalizedPlatform = platform.toLowerCase();
    final clientTraceId = normalizedPlatform == platformIOS
        ? (iosClientTraceId(receipt) ??
              _generateClientTraceId(normalizedPlatform))
        : _generateClientTraceId(normalizedPlatform);

    final items = await _loadQueue();

    // 같은 키가 이미 있으면 새로 쌓지 않고 기존 항목을 재사용한다. iOS 키는
    // 결정적이라 재전달/폴백 재검증이 이 경로를 타고, Android 키는 난수라
    // 절대 타지 않는다(기존 동작 그대로).
    final existing = items.indexWhere(
      (e) => e['client_trace_id'] == clientTraceId,
    );
    if (existing >= 0) {
      logger.i('📥 큐 항목 재사용: $clientTraceId ($normalizedPlatform/$productId)');
      return clientTraceId;
    }

    items.add({
      'client_trace_id': clientTraceId,
      'receipt': receipt,
      'productId': productId,
      'user_id': userId,
      'platform': normalizedPlatform,
      'environment': environment,
      'format': ReceiptFormatHelper.verificationFormatFor(
        platform: normalizedPlatform,
        receipt: receipt,
      ),
      'attempt': 0,
      'createdAt': DateTime.now().toIso8601String(),
      'nextAt': 0,
    });
    await _saveQueue(items);
    logger.i('📥 큐 적재: $clientTraceId ($normalizedPlatform/$productId)');
    return clientTraceId;
  }

  Future<void> removeByClientTraceId(String clientTraceId) =>
      _dropItem(clientTraceId, '🧹 큐 제거');

  /// 409 응답이 "보상 지급까지 완료된 중복"인지 판별한다.
  ///
  /// 레거시 `verify_receipt`(v162)는 영수증 행만 있고 보상 지급이 실패한
  /// 경로에서도 409(DUPLICATE_RECEIPT)를 반환한다. 그 경우 큐 항목이 유일한
  /// 재시도 수단이므로 지우면 안 된다.
  ///
  /// 판별은 구조화된 `grant_confirmed` 필드를 우선한다(하드닝된 서버).
  /// 필드가 없는 배포본(v161)에 한해 알려진 실패 문구 부재로 fallback하며,
  /// 판별할 수 없는 응답은 보수적으로 유지한다.
  ///
  /// **이 큐의 플러시는 이 판정을 쓰지 않는다** — 큐가 호출하는
  /// `verify-receipt-v2` 는 409 를 반환하지 않는다([_flushItem] 주석 참고).
  /// foreground 검증 경로가 레거시 409 를 만났을 때만 쓰인다.
  @visibleForTesting
  static bool duplicateConfirmsGrant(dynamic details) {
    if (details is! Map) return false;
    final structured = details['grant_confirmed'];
    if (structured is bool) return structured;
    if (details['code'] != 'DUPLICATE_RECEIPT') return false;
    final message = details['message']?.toString() ?? '';
    return !message.contains('실패');
  }

  bool _shouldSendNow(Map<String, dynamic> item) {
    final nextAt = (item['nextAt'] as num?)?.toInt() ?? 0;
    return DateTime.now().millisecondsSinceEpoch >= nextAt;
  }

  int _computeNextAt(int attempt) {
    final base = PurchaseConstants.baseRetryDelay;
    final seconds = base * (1 << (attempt.clamp(0, 6))); // 2,4,8,16,32,64,128
    final cap = 300; // 5분 상한
    final backoffSec = seconds > cap ? cap : seconds;
    return DateTime.now()
        .add(Duration(seconds: backoffSec))
        .millisecondsSinceEpoch;
  }

  /// 큐 항목을 verify-receipt-v2 요청 본문으로 되돌린다.
  ///
  /// `format` 은 플랫폼별로 갈린다. 과거 구현은 iOS 항목에도
  /// `'google_play'` 를 하드코딩했으므로, iOS 항목을 큐에 넣는 순간
  /// 잘못된 본문으로 재전송될 수밖에 없었다.
  ///
  /// `platform`/`format` 이 없는 옛 항목(v1 큐)은 Android 전용이었으므로
  /// Android 로 해석한다.
  @visibleForTesting
  static Map<String, dynamic> buildQueuedRequestBody(
    Map<String, dynamic> item,
  ) {
    final rawPlatform = item['platform']?.toString().toLowerCase();
    final platform = (rawPlatform == null || rawPlatform.isEmpty)
        ? platformAndroid
        : rawPlatform;
    final storedFormat = item['format'];
    return {
      'receipt': item['receipt'],
      'platform': platform,
      'productId': item['productId'],
      'user_id': item['user_id'],
      'environment': item['environment'],
      'format': storedFormat is String && storedFormat.isNotEmpty
          ? storedFormat
          : ReceiptFormatHelper.verificationFormatFor(
              platform: platform,
              receipt: item['receipt']?.toString() ?? '',
            ),
      'client_trace_id': item['client_trace_id'],
    };
  }

  /// 큐에 남은 검증 요청을 재전송한다.
  ///
  /// single-flight: 진행 중인 플러시가 있으면 그 future 를 그대로 돌려준다.
  /// 부팅 시 `PurchaseService` 는 초기화 경로와 Android 과거 구매 reconcile
  /// 경로에서 각각 unawaited 로 이 메서드를 호출한다. 두 플러시가 교차하면
  /// (과거 구현) 서로의 스냅샷을 통째로 되쓰면서 사이에 적재된 항목이
  /// 소멸했다.
  Future<void> flushPending() => _inFlightFlush ??= _flushPending();

  Future<void> _flushPending() async {
    // `_inFlightFlush = ...` 대입이 아래 finally 보다 먼저 끝나도록 한 틱
    // 양보한다(동기 예외로 게이트가 완료된 future 에 고정되는 것 방지).
    await Future<void>.value();
    try {
      final snapshot = await _loadQueue();
      if (snapshot.isEmpty) return;
      logger.i('🧾 영수증 큐 플러시 시작: ${snapshot.length}건');

      // 스냅샷은 "이번에 시도할 대상 목록"으로만 쓴다. 실제 읽기/쓰기는
      // 항목마다 다시 한다.
      for (final snapshotItem in snapshot) {
        final clientTraceId = snapshotItem['client_trace_id']?.toString();
        if (clientTraceId == null || clientTraceId.isEmpty) continue;
        await _flushItem(clientTraceId);
      }

      final remaining = await _loadQueue();
      logger.i('🧾 영수증 큐 플러시 완료. 남은 건: ${remaining.length}');
    } finally {
      _inFlightFlush = null;
    }
  }

  Future<void> _flushItem(String clientTraceId) async {
    // invoke 를 기다리는 동안 큐가 바뀔 수 있으므로 매번 다시 읽는다.
    final item = await _findByClientTraceId(clientTraceId);
    if (item == null) return; // foreground 경로가 이미 정리함
    if (!_shouldSendNow(item)) return;

    try {
      // foreground 검증과 동일한 auth 복구를 쓴다. 부팅 직후 플러시는 세션
      // 복원과 경쟁하므로 401 이 정상 시나리오인데, 과거 구현은 이를 그냥
      // 백오프로 넘겨 첫 플러시를 통째로 낭비했다.
      final response = await invokeWithAuthRecovery(
        invoke: () => supabase.functions
            .invoke(
              PurchaseConstants.receiptVerificationFunction,
              body: buildQueuedRequestBody(item),
            )
            .timeout(flushInvokeTimeout),
        refresh: () async {
          logger.w('🔑 큐 플러시 401 - 세션 갱신 후 1회 재시도: $clientTraceId');
          final refreshed = await supabase.auth.refreshSession();
          final ok = refreshed.session != null;
          logger.i('🔑 세션 갱신 ${ok ? '성공' : '실패'}: $clientTraceId');
          return ok;
        },
      );

      // 성공 판정은 foreground 검증과 같은 기준을 공유해야 한다:
      // 레거시 서버는 {success: true, ...}, wallet.v1 서버는 정산 객체
      // 자체(contract_version == 'wallet.v1')를 200으로 반환한다.
      // 후자를 실패로 오판하면 이미 정산된 영수증을 영원히 재전송한다.
      final data = response.data;
      final ok =
          response.status == 200 &&
          data is Map &&
          (data['success'] == true ||
              data['contract_version'] == 'wallet.v1');
      if (ok) {
        await _dropItem(clientTraceId, '✅ 큐 전송 성공');
        return;
      }

      // 그 외 응답은 백오프 후 유지
      await _scheduleRetry(clientTraceId, '상태 ${response.status}');
    } on FunctionException catch (e) {
      // invoke 는 2xx 외 상태코드에서 FunctionException 을 던지고 JSON body 는
      // details 에 담긴다.
      //
      // 422 는 wallet.v1 워커의 명시적 비재시도 판정이다. 재전송해도 결코
      // 성공하지 못하는 영수증이 큐를 영원히 돌지 않게 제거한다. (엔진은
      // 워커 5xx → 503, 그 외 워커 실패 → 422 로 나눈다. 503 은 아래 백오프
      // 경로로 유지된다.)
      if (e.status == 422) {
        await _dropItem(clientTraceId, '🚫 서버 영구 거부(422)');
        return;
      }

      // 과거 여기 있던 두 "제거" 분기는 삭제했다. 이 큐가 호출하는
      // 엔드포인트는 `verify-receipt-v2` 뿐이고, 그 핸들러(engine
      // supabase/functions/verify-receipt-v2 → verify_receipt/index.ts)가
      // 돌려주는 상태코드는 200/400/401/403/422/503/405 뿐이다:
      //   - 409 DUPLICATE_RECEIPT 는 레거시 `verify_receipt`(v162) 전용
      //     응답이다. v2 엔진 전체 grep 결과 409 는 0건이라 분기가 실행될
      //     수 없었다.
      //   - `details['code'] == 'PURCHASE_CANCELED'` 도 같은 이유로 v2 가
      //     반환하지 않는다(v2 의 400 은 PURCHASE_INVALID_PROOF /
      //     PURCHASE_INVALID_PLATFORM 과 핸들러 catch-all 뿐).
      // 실행되지 않는 "제거" 분기를 남겨 두면 서버 계약이 바뀌는 순간
      // 과금된 영수증의 유일한 durable 기록을 조용히 지우는 함정이 된다.
      // (409 판정 헬퍼 [duplicateConfirmsGrant] 는 레거시 409 를 만나는
      // foreground 경로가 계속 쓰므로 그대로 둔다.)
      await _scheduleRetry(clientTraceId, '상태 ${e.status}');
    } catch (e) {
      // 네트워크/타임아웃/401 복구 실패 등 → 백오프
      await _scheduleRetry(clientTraceId, '$e');
    }
  }

  Future<Map<String, dynamic>?> _findByClientTraceId(
    String clientTraceId,
  ) async {
    final items = await _loadQueue();
    for (final item in items) {
      if (item['client_trace_id'] == clientTraceId) return item;
    }
    return null;
  }

  /// 큐를 다시 읽어 해당 항목만 백오프 갱신한다.
  ///
  /// 스냅샷 전체를 되쓰지 않는 것이 핵심이다 — 되쓰면 invoke 대기 중에
  /// 적재된 신규 구매(=과금된 영수증의 유일한 durable 기록)가 사라진다.
  Future<void> _scheduleRetry(String clientTraceId, String reason) async {
    final items = await _loadQueue();
    final index = items.indexWhere(
      (e) => e['client_trace_id'] == clientTraceId,
    );
    if (index < 0) return;
    final attempt = ((items[index]['attempt'] as num?)?.toInt() ?? 0) + 1;
    items[index]['attempt'] = attempt;
    items[index]['nextAt'] = _computeNextAt(attempt);
    await _saveQueue(items);
    logger.w('⏳ 큐 전송 실패($reason), 재시도 예약: $clientTraceId');
  }

  Future<void> _dropItem(String clientTraceId, String reason) async {
    final items = await _loadQueue();
    final before = items.length;
    items.removeWhere((e) => e['client_trace_id'] == clientTraceId);
    if (items.length == before) return;
    await _saveQueue(items);
    logger.i('$reason: $clientTraceId');
  }
}
