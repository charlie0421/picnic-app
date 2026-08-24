import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'package:picnic_lib/core/analytics/iso_4217_currency.dart';
import 'package:picnic_lib/core/constants/purchase_constants.dart';
import 'package:picnic_lib/data/models/purchase/purchase_settlement_result.dart';
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

  /// 큐에 대한 모든 read-modify-write(로드→수정→저장)를 직렬화하는 락.
  ///
  /// [flushPending]의 single-flight는 "플러시끼리" 겹치지 않게만 한다.
  /// 그런데 `enqueue()`(실제 구매 도중, 플러시와 무관하게 호출됨)와
  /// `_scheduleRetry`/`_dropItem`(플러시가 항목별로 호출)은 전부 독립적으로
  /// 큐 전체를 다시 읽고 다시 쓴다 - 이 락이 없으면 두 호출이 같은 스냅샷을
  /// 읽은 뒤 나중에 저장하는 쪽이 먼저 저장된 쪽의 변경(예: 방금 적재된
  /// 새 영수증)을 통째로 덮어써 조용히 사라질 수 있다. 스토어 쪽 리컨사일이
  /// 있어 영구 손실은 아니지만, 이 큐가 존재하는 이유(durable *빠른*
  /// 재시도 경로) 자체가 깨진다.
  Future<void>? _mutationLock;

  Future<T> _withMutationLock<T>(Future<T> Function() body) async {
    while (_mutationLock != null) {
      try {
        await _mutationLock;
      } catch (_) {
        // 이전 뮤테이션의 실패는 이번 호출 실행 여부와 무관하다.
      }
    }
    final completer = Completer<void>();
    _mutationLock = completer.future;
    try {
      return await body();
    } finally {
      completer.complete();
      if (identical(_mutationLock, completer.future)) {
        _mutationLock = null;
      }
    }
  }

  /// [_pruneStale]이 항목을 실제로 잘랐을 때 알림을 받는 콜백.
  ///
  /// 이 서비스는 `PurchaseService`/`GlobalPurchaseListener`를 알지 못한다
  /// (역방향 의존 방지 - `PurchaseService`가 이미 이 클래스를 가져다 쓴다).
  /// 그래서 스토어 리컨사일을 직접 걸지 않고, 상위 오케스트레이션이 설정한
  /// 콜백으로만 "지금 뭔가 잘렸다"를 알린다. 잘린 항목의 실제 결제는
  /// 원래도 스토어 트랜잭션이 미확정으로 남아 있어 다음 콜드스타트/재개
  /// 스윕이 되찾지만, 콜백을 설정해 두면 그 회수를 다음 기회까지 미루지
  /// 않고 즉시 시도할 수 있다.
  void Function()? onItemsEvicted;

  /// 큐 복구가 200 정산 응답을 받았을 때, 그 매출 이벤트를 durable 하게
  /// 넘겨받는 곳.
  ///
  /// `true` 를 돌려줄 때만 큐 항목을 제거한다. 정산 응답을 받자마자 큐를
  /// 비우면, 그 뒤 analytics 저장이 실패하고 스토어가 consume 된 순간 그
  /// 거래의 매출을 되살릴 재료가 클라이언트 어디에도 남지 않는다.
  Future<bool> Function(
    PurchaseSettlementResultModel settlement, {
    required String storeProductId,
    required String? clientObservedCurrency,
  })?
  onSettlementRecovered;

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

  DateTime? _parseCreatedAt(Map<String, dynamic> item) {
    final raw = item['createdAt'] as String?;
    return raw == null ? null : DateTime.tryParse(raw);
  }

  /// [_pruneStale]이 지운 항목이 있으면 그 결과를 저장한다. `enqueue`/
  /// `_flushPending` 양쪽에서 재사용해, 두 경로 모두 상한을 즉시 지킨다.
  ///
  /// 잘라내도 안전한 이유: 이 큐는 검증 재전송의 *빠른* 경로일 뿐이다.
  /// 스토어 트랜잭션은 절대 finish/consume 하지 않으므로, 여기서 잘린
  /// 항목의 실제 결제는 다음 콜드 스타트·재개 스윕(`PurchaseService
  /// .sweepUnfinishedPurchases`)이 스토어(`queryPastPurchases`/
  /// `SKPaymentQueue`)에서 직접 다시 찾아내 재검증한다. 그 스윕은 스토어
  /// 화면이 떠 있는 동안은 건너뛰므로(`GlobalPurchaseListener
  /// .sweepOnResume`), "다음 콜드 스타트, 또는 스토어 화면을 벗어난 뒤의
  /// 재개 시점까지" 재시도가 늦어질 수 있다는 뜻이다 - 정산 기록 자체가
  /// 사라지지는 않지만, 5분 안에 반드시 재시도된다는 보장은 아니다.
  Future<List<Map<String, dynamic>>> _pruneStale(
    List<Map<String, dynamic>> items,
  ) async {
    final now = DateTime.now();
    final fresh = items.where((item) {
      // 정산이 끝나고 매출 이벤트 인계만 남은 항목은 나이로 자르지 않는다.
      // 이 거래의 스토어 트랜잭션은 이미 finish 됐으므로 아래 주석의
      // "스윕이 다시 찾아낸다" 전제가 성립하지 않는다.
      if (_isAnalyticsPending(item)) return true;
      final createdAt = _parseCreatedAt(item);
      if (createdAt == null) return true; // createdAt 없는/파싱 불가 옛 항목은 보존
      return now.difference(createdAt) <= PurchaseConstants.receiptQueueMaxAge;
    }).toList();

    final overflow = fresh.length - PurchaseConstants.receiptQueueMaxEntries;
    List<Map<String, dynamic>> trimmed = fresh;
    if (overflow > 0) {
      // 실제 createdAt 기준으로 가장 오래된 것부터 자른다 - 리스트 순서에만
      // 의존하면 동시 쓰기나 복구된 데이터에서 실제로는 최근인 항목이
      // 잘릴 수 있다. createdAt 을 못 읽는 항목은 안전 쪽으로(가장 오래된
      // 것으로) 취급해 먼저 잘린다.
      // 인계 대기 항목은 마지막에 자른다. 상한을 지키느라 잘라야 한다면
      // 그때는 매출 유실이 확정되므로 조용히 넘기지 않고 error 로 남긴다.
      final byAge = [...fresh]..sort((a, b) {
        final pendingA = _isAnalyticsPending(a);
        final pendingB = _isAnalyticsPending(b);
        if (pendingA != pendingB) return pendingA ? 1 : -1;
        final da = _parseCreatedAt(a);
        final db = _parseCreatedAt(b);
        if (da == null && db == null) return 0;
        if (da == null) return -1;
        if (db == null) return 1;
        return da.compareTo(db);
      });
      final toDrop = byAge.take(overflow).toSet();
      final droppedPending = toDrop.where(_isAnalyticsPending).length;
      if (droppedPending > 0) {
        logger.e(
          '🧹 영수증 큐 상한 초과로 정산 완료·매출 인계 대기 항목 '
          '$droppedPending건 제거 — 이 거래들의 매출은 복구되지 않는다',
        );
      }
      trimmed = fresh.where((item) => !toDrop.contains(item)).toList();
    }

    if (trimmed.length != items.length) {
      logger.w(
        '🧹 영수증 큐 정리: ${items.length - trimmed.length}건 제거'
        '(TTL/상한, 남은 건: ${trimmed.length}) - 스토어 재전달·리컨사일이 회수한다',
      );
      await _saveQueue(trimmed);
      onItemsEvicted?.call();
    }
    return trimmed;
  }

  /// 검증 요청을 큐에 적재하고 `client_trace_id` 를 돌려준다.
  ///
  /// [platform] 은 `'android'` 또는 `'ios'`. 요청 본문 재구성에 필요한
  /// 필드(receipt/productId/user_id/environment/format)를 모두 저장하므로
  /// [flushPending] 이 플랫폼별로 올바른 본문을 다시 만들 수 있다.
  Future<String> enqueue({
    required String platform,
    required String receipt,
    required String productId,
    required String userId,
    required String environment,
    String? clientObservedCurrency,
  }) => _withMutationLock(() async {
    final normalizedPlatform = platform.toLowerCase();
    final clientTraceId = normalizedPlatform == platformIOS
        ? (iosClientTraceId(receipt) ??
              _generateClientTraceId(normalizedPlatform))
        : _generateClientTraceId(normalizedPlatform);

    final items = await _pruneStale(await _loadQueue());

    // 같은 키가 이미 있으면 새로 쌓지 않고 기존 항목을 재사용한다. iOS 키는
    // 결정적이라 재전달/폴백 재검증이 이 경로를 타고, Android 키는 난수라
    // 절대 타지 않는다(기존 동작 그대로).
    final existing = items.indexWhere(
      (e) => e['client_trace_id'] == clientTraceId,
    );
    if (existing >= 0) {
      // 결정적 iOS 키는 재전달마다 같은 항목으로 돌아온다. 그 사이 카탈로그가
      // 로드돼 통화를 알게 됐다면 비어 있던 자리만 채운다. 이미 다른 값이
      // 있으면 최초 값을 정본으로 두고 덮어쓰지 않는다 — 같은 거래의 통화가
      // 재전달마다 바뀌면 어느 쪽이 맞는지 판단할 근거가 없다.
      final observed = normalizeIso4217(clientObservedCurrency);
      final stored = items[existing]['client_observed_currency'];
      if (observed != null && stored == null) {
        items[existing] = <String, dynamic>{
          ...items[existing],
          'client_observed_currency': observed,
        };
        await _saveQueue(items);
      } else if (observed != null && stored != observed) {
        logger.w(
          '📥 큐 항목의 관측 통화가 재전달마다 다르다 — 최초 값 유지: '
          '$clientTraceId ($stored vs $observed)',
        );
      }
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
      if (normalizeIso4217(clientObservedCurrency) != null)
        'client_observed_currency': normalizeIso4217(clientObservedCurrency),
      'attempt': 0,
      'createdAt': DateTime.now().toIso8601String(),
      'nextAt': 0,
    });
    // enqueue 는 방금 프룬한 스냅샷에 새 항목 하나를 더할 뿐이므로, 그
    // 결과가 다시 상한을 넘을 수 없다(프룬 직후 길이 <= 상한이었고 +1).
    // 그래도 상한이 0으로 설정되는 극단적 상황을 방어하려면 한 번 더
    // 잘라내는 편이 안전하다.
    final overflow = items.length - PurchaseConstants.receiptQueueMaxEntries;
    final toSave = overflow > 0 ? items.sublist(overflow) : items;
    await _saveQueue(toSave);
    if (overflow > 0) onItemsEvicted?.call();
    logger.i('📥 큐 적재: $clientTraceId ($normalizedPlatform/$productId)');
    return clientTraceId;
  });

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
      // 재전송 본문이 foreground 본문과 달라지면 서버는 capability 없는
      // 구버전 클라이언트로 읽고 7키로 낮춰 답한다 — 큐 복구 경로만 조용히
      // 매출을 잃는다.
      'parser_capabilities': ReceiptFormatHelper.parserCapabilities,
      if (item['client_observed_currency'] != null)
        'client_observed_currency': item['client_observed_currency'],
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
      final snapshot = await _withMutationLock(
        () async => _pruneStale(await _loadQueue()),
      );
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

  /// 큐 복구가 받은 200 정산을 analytics outbox 로 넘긴다.
  ///
  /// 넘길 곳이 없거나(콜백 미설정) 응답이 레거시 `{success: true}` 라 넘길
  /// 정산이 없으면 `true` 다 — 그 경우 큐를 남겨 둬도 할 수 있는 일이 없다.
  Future<bool> _handOffSettlement(
    Map<String, dynamic> item,
    Object? data,
  ) async {
    // 먼저 "넘길 것이 있는가", 그다음 "넘길 곳이 있는가" 순서다.
    //
    // 레거시 `{success: true}` 응답에는 넘길 정산 자체가 없다. 붙잡아 둬도
    // 할 수 있는 일이 없으므로 예전처럼 제거한다.
    if (data is! Map || data['contract_version'] != 'wallet.v1') return true;

    PurchaseSettlementResultModel settlement;
    try {
      settlement = PurchaseSettlementResultModel.fromJson(
        Map<String, dynamic>.from(data),
      );
    } catch (e, s) {
      // 같은 요청을 다시 보내도 같은 본문이 돌아온다 — 붙잡아 두면 TTL 만큼
      // 같은 손실을 미루며 네트워크만 쓴다. 매출 이벤트는 만들 수 없지만
      // 정산 자체는 서버에서 끝났으므로 제거하되 error 로 남긴다.
      logger.e('🧾 큐 복구 정산 파싱 실패 — 매출 이벤트 없이 제거', error: e, stackTrace: s);
      return true;
    }

    final handOff = onSettlementRecovered;
    if (handOff == null) {
      // 넘길 곳이 아직 연결되지 않았다(부팅 순서상 일시적일 수 있다). 여기서
      // 제거하면 그 거래의 매출은 되살릴 재료 없이 사라지므로, 콜백이 연결된
      // 다음 플러시에 맡긴다. 영구히 미연결이면 TTL 이 상한을 준다 — 그래서
      // 이 경우는 인계 대기 표시를 세우지 않는다.
      logger.w('🧾 큐 복구 인계 대상 미연결 — 항목을 남긴다');
      return false;
    }

    try {
      return await handOff(
        settlement,
        storeProductId: item['productId']?.toString() ?? '',
        clientObservedCurrency: item['client_observed_currency']?.toString(),
      );
    } catch (e, s) {
      logger.e('🧾 큐 복구 analytics 인계 실패', error: e, stackTrace: s);
      return false;
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
        if (!await _handOffSettlement(item, data)) {
          // 정산은 확정됐지만 매출 이벤트를 durable 하게 넘기지 못했다. 큐를
          // 비우면 이 거래를 되살릴 재료가 사라지므로 남기고 백오프한다.
          //
          // 인계 대기 표시는 소비자가 실제로 실패를 답했을 때만 세운다.
          // 소비자가 아예 없는 상태까지 TTL 밖으로 고정하면, 콜백이 영영
          // 연결되지 않는 빌드에서 큐가 영구히 잠긴다.
          await _scheduleRetry(
            clientTraceId,
            'analytics durable 저장 미확인',
            analyticsPending: onSettlementRecovered != null,
          );
          return;
        }
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
  Future<void> _scheduleRetry(
    String clientTraceId,
    String reason, {
    bool analyticsPending = false,
  }) => _withMutationLock(() async {
    final items = await _loadQueue();
    final index = items.indexWhere((e) => e['client_trace_id'] == clientTraceId);
    if (index < 0) return;
    final attempt = ((items[index]['attempt'] as num?)?.toInt() ?? 0) + 1;
    items[index]['attempt'] = attempt;
    items[index]['nextAt'] = _computeNextAt(attempt);
    if (analyticsPending) items[index][_analyticsPendingKey] = true;
    await _saveQueue(items);
    logger.w('⏳ 큐 전송 실패($reason), 재시도 예약: $clientTraceId');
  });

  /// 서버 정산은 끝났지만 매출 이벤트를 아직 넘기지 못한 항목의 표시.
  ///
  /// [_pruneStale] 의 "잘라도 스윕이 되찾는다" 전제가 이 항목들에는 성립하지
  /// 않는다. 이 거래의 스토어 트랜잭션은 이미 finish 됐으므로 스윕이 다시
  /// 찾아낼 것이 없다.
  static const String _analyticsPendingKey = 'analytics_pending';

  static bool _isAnalyticsPending(Map<String, dynamic> item) =>
      item[_analyticsPendingKey] == true;

  Future<void> _dropItem(String clientTraceId, String reason) =>
      _withMutationLock(() async {
        final items = await _loadQueue();
        final before = items.length;
        items.removeWhere((e) => e['client_trace_id'] == clientTraceId);
        if (items.length == before) return;
        await _saveQueue(items);
        logger.i('$reason: $clientTraceId');
      });
}
