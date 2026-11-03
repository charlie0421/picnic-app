import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:picnic_lib/core/analytics/analytics_send_markers.dart';
import 'package:picnic_lib/core/analytics/ga4_purchase_item.dart';
import 'package:picnic_lib/core/analytics/ga4_sink.dart';
import 'package:picnic_lib/core/analytics/iso_4217_currency.dart';
import 'package:picnic_lib/core/analytics/ga4_taxonomy.dart';
import 'package:picnic_lib/core/constatns/constants.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/storage/local_storage.dart';

enum AnalyticsOutboxEventKind { purchase, earnVirtualCurrency, login, signUp }

/// purchase 항목이 GA4 로 나갈 수 있는 상태인지.
///
/// 검증·지급이 끝난 스토어 구매는 전부 revenue-bearing 이다. 통화를 아직
/// 확보하지 못한 매출 이벤트를 "필드만 빼고 전송 성공"으로 흡수하면 그 거래의
/// 매출은 GA4 에서 영영 0 이다 — 보내지 않고 기다리는 편이 복구 가능하다.
enum AnalyticsOutboxDeliveryState {
  /// ISO 4217 통화를 확보했다. 다음 drain 에서 sink 로 나간다.
  ready,

  /// 통화가 없어 보류 중이다. sink 대상이 아니며 resolver 재시도를 탄다.
  awaitingCurrency,
}

/// [AnalyticsOutbox.enqueueOrMergePurchase] 의 durable 저장 결과.
///
/// 호출부(`PurchaseService`)는 `ready` 또는 `deferred` 를 확인한 뒤에만 영수증
/// 큐 항목을 제거한다. `failed` 는 복구 재료를 아직 버리면 안 된다는 뜻이다.
enum PurchaseOutboxResult { ready, deferred, failed }

/// 통화를 확보하지 못한 이유. 원문 예외나 영수증은 저장하지 않는다.
enum PurchaseCurrencyError {
  catalogUnavailable,
  productMissing,
  invalidIso4217,
  resolverTimeout,
}

/// 보류 중인 purchase 의 통화를 나중에 다시 찾아보는 경로.
///
/// 정산 시점에 스토어 카탈로그가 메모리에 없어 통화를 못 구한 복구 구매가
/// 대상이다. 앱이 이후 카탈로그를 확보하면 같은 항목이 그대로 되살아난다.
abstract class PurchaseCurrencyResolver {
  Future<String?> resolve(String storeProductId);
}

/// 만료된 purchase 의 요약. payload·영수증은 담지 않는다.
///
/// 만료를 조용한 삭제로 처리하면 "왜 이 거래의 매출이 없는가"에 답할 수 없다.
@immutable
class AnalyticsDeadLetter {
  const AnalyticsDeadLetter({
    required this.id,
    required this.aliases,
    required this.attempts,
    required this.reason,
    required this.expiredAt,
  });

  final String id;
  final List<String> aliases;
  final int attempts;
  final String reason;
  final DateTime expiredAt;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'aliases': aliases,
    'attempts': attempts,
    'reason': reason,
    'expired_at': expiredAt.toIso8601String(),
  };

  static AnalyticsDeadLetter? fromJson(Object? raw) {
    if (raw is! Map) return null;
    try {
      final map = Map<String, dynamic>.from(raw);
      return AnalyticsDeadLetter(
        id: map['id'] as String,
        aliases: <String>[
          for (final value in map['aliases'] as List<dynamic>)
            if (value is String && value.isNotEmpty) value,
        ],
        attempts: (map['attempts'] as num?)?.toInt() ?? 0,
        reason: map['reason'] as String? ?? '',
        expiredAt: DateTime.parse(map['expired_at'] as String).toUtc(),
      );
    } catch (e, s) {
      logger.e('GA4 outbox dead letter 파싱 실패: $raw', error: e, stackTrace: s);
      return null;
    }
  }
}

/// GA4 로 보낼 수 있을 만큼 완성된 payload 를 담는 durable outbox 항목.
///
/// [id] 는 이벤트 종류 안에서 안정적이어야 한다. purchase 는 해석된
/// transaction/operation 키, earn 은 서버 reference, login/sign_up 은 각각
/// 로그인 서명/사용자 가입 서명을 쓴다. [aliases] 는 purchase 의 tx/op처럼 한
/// 사실을 가리키는 여러 키를 한 항목으로 묶는다.
@immutable
class AnalyticsOutboxEntry {
  const AnalyticsOutboxEntry._({
    required this.kind,
    required this.id,
    required this.aliases,
    required this.payload,
    required this.userId,
    required this.createdAt,
    this.deliveryConfirmed = false,
    this.deliveryState = AnalyticsOutboxDeliveryState.ready,
    this.storeProductId,
    this.candidateValue,
    this.currencyAttempts = 0,
    this.currencyNextAt,
    this.lastCurrencyError,
  });

  factory AnalyticsOutboxEntry.event({
    required AnalyticsOutboxEventKind kind,
    required String id,
    required Map<String, Object> parameters,
    Map<String, String?> userProperties = const <String, String?>{},
    String? userId,
    DateTime? createdAt,
  }) {
    assert(kind != AnalyticsOutboxEventKind.purchase);
    return AnalyticsOutboxEntry._(
      kind: kind,
      id: id,
      aliases: <String>[id],
      payload: <String, Object>{
        'parameters': parameters,
        if (userProperties.isNotEmpty) 'user_properties': userProperties,
      },
      userId: userId,
      createdAt: (createdAt ?? DateTime.now()).toUtc(),
    );
  }

  /// GA4 매출 이벤트 하나.
  ///
  /// [currency] 가 ISO 4217 이 아니면(없는 경우 포함) 항목은 전송 대상이 아니라
  /// [AnalyticsOutboxDeliveryState.awaitingCurrency] 로 만들어지고, [value] 는
  /// payload 가 아니라 [candidateValue] 로만 보존된다. 통화 없는 매출 이벤트를
  /// payload 에 담아 둘 수 있게 하면 어느 경로로든 sink 에 닿을 수 있다.
  factory AnalyticsOutboxEntry.purchase({
    required String id,
    required List<String> aliases,
    required String transactionId,
    required String? currency,
    required num? value,
    required List<Ga4PurchaseItem> items,
    String? storeProductId,
    num? candidateValue,
    DateTime? createdAt,
  }) {
    final payload = <String, Object>{
      'transaction_id': transactionId,
      'items': <Map<String, Object?>>[
        for (final item in items)
          <String, Object?>{
            'item_id': item.itemId,
            'item_name': item.itemName,
            'virtual_currency_name': item.virtualCurrencyName,
            'base_amount': item.baseAmount,
            'bonus_amount': item.bonusAmount,
          },
      ],
    };
    final iso = normalizeIso4217(currency);
    if (iso != null) {
      payload['currency'] = iso;
      // B-3: value 는 Number 파라미터라 결측 시 그 키만 생략한다. currency 를
      // 억지로 같이 지울 근거가 없다.
      if (value != null) payload['value'] = value;
    }
    return AnalyticsOutboxEntry._(
      kind: AnalyticsOutboxEventKind.purchase,
      id: id,
      aliases: aliases.isEmpty ? <String>[id] : List<String>.of(aliases),
      payload: payload,
      userId: null,
      createdAt: (createdAt ?? DateTime.now()).toUtc(),
      deliveryState: iso == null
          ? AnalyticsOutboxDeliveryState.awaitingCurrency
          : AnalyticsOutboxDeliveryState.ready,
      storeProductId: storeProductId,
      candidateValue: iso == null ? (candidateValue ?? value) : null,
    );
  }

  final AnalyticsOutboxEventKind kind;
  final String id;
  final List<String> aliases;
  final Map<String, Object> payload;
  final String? userId;
  final DateTime createdAt;

  /// purchase 이외 이벤트의 durable "sink 성공 확인" 비트.
  ///
  /// GA4 는 earn/login/sign_up 에 transaction_id 같은 중복 제거 장치가 없다.
  /// 그래서 sink가 `true`를 반환한 뒤 이 비트를 먼저 영속화하고, 다음 저장에서
  /// pending을 제거한다. 두 번째 저장만 실패하면 재시작은 재전송 없이 정리할 수
  /// 있다. false/timeout/throw 뒤에는 절대 세우지 않으므로 성공하지 않은 항목이
  /// outbox에서 사라지지 않는다.
  final bool deliveryConfirmed;

  /// purchase 전용. 다른 종류는 항상 [AnalyticsOutboxDeliveryState.ready] 다.
  final AnalyticsOutboxDeliveryState deliveryState;

  /// 카탈로그 재조회 키. GA4 `item_id` 로 정규화하기 전의 실제 스토어 상품 ID.
  final String? storeProductId;

  /// 통화보다 먼저 얻은 금액. payload 가 아니라 여기에만 둔다.
  final num? candidateValue;

  final int currencyAttempts;
  final DateTime? currencyNextAt;
  final PurchaseCurrencyError? lastCurrencyError;

  String get processKey => '${kind.name}:$id';

  bool get isAwaitingCurrency =>
      deliveryState == AnalyticsOutboxDeliveryState.awaitingCurrency;

  AnalyticsOutboxEntry copyWith({
    bool? deliveryConfirmed,
    List<String>? aliases,
    Map<String, Object>? payload,
    AnalyticsOutboxDeliveryState? deliveryState,
    String? storeProductId,
    num? candidateValue,
    bool clearCandidateValue = false,
    int? currencyAttempts,
    DateTime? currencyNextAt,
    bool clearCurrencyNextAt = false,
    PurchaseCurrencyError? lastCurrencyError,
  }) => AnalyticsOutboxEntry._(
    kind: kind,
    id: id,
    aliases: aliases ?? this.aliases,
    payload: payload ?? this.payload,
    userId: userId,
    createdAt: createdAt,
    deliveryConfirmed: deliveryConfirmed ?? this.deliveryConfirmed,
    deliveryState: deliveryState ?? this.deliveryState,
    storeProductId: storeProductId ?? this.storeProductId,
    candidateValue: clearCandidateValue
        ? null
        : (candidateValue ?? this.candidateValue),
    currencyAttempts: currencyAttempts ?? this.currencyAttempts,
    currencyNextAt: clearCurrencyNextAt
        ? null
        : (currencyNextAt ?? this.currencyNextAt),
    lastCurrencyError: lastCurrencyError ?? this.lastCurrencyError,
  );

  Map<String, Object?> toJson() => <String, Object?>{
    'kind': kind.name,
    'id': id,
    'aliases': aliases,
    'payload': payload,
    'user_id': userId,
    'created_at': createdAt.toIso8601String(),
    'delivery_confirmed': deliveryConfirmed,
    'delivery_state': deliveryState.name,
    if (storeProductId != null) 'store_product_id': storeProductId,
    if (candidateValue != null) 'candidate_value': candidateValue,
    if (currencyAttempts > 0) 'currency_attempts': currencyAttempts,
    if (currencyNextAt != null)
      'currency_next_at': currencyNextAt!.toIso8601String(),
    if (lastCurrencyError != null)
      'last_currency_error': lastCurrencyError!.name,
  };

  static AnalyticsOutboxEntry? fromJson(Object? raw) {
    if (raw is! Map) return null;
    try {
      final map = Map<String, dynamic>.from(raw);
      final kindName = map['kind'] as String;
      final kind = AnalyticsOutboxEventKind.values.byName(kindName);
      final id = map['id'] as String;
      final aliases = <String>[
        for (final value in map['aliases'] as List<dynamic>)
          if (value is String && value.isNotEmpty) value,
      ];
      final payload = <String, Object>{};
      for (final item in Map<String, dynamic>.from(
        map['payload'] as Map,
      ).entries) {
        if (item.value != null) payload[item.key] = item.value as Object;
      }
      var candidateValue = map['candidate_value'] as num?;
      final rawState = map['delivery_state'] as String?;
      var state = AnalyticsOutboxDeliveryState.ready;
      if (rawState != null) {
        state = AnalyticsOutboxDeliveryState.values.byName(rawState);
      } else if (kind == AnalyticsOutboxEventKind.purchase &&
          !isIso4217(payload['currency'])) {
        // storage v1 에는 이 상태가 없다. 통화 없이 저장돼 있던 매출 이벤트는
        // 마이그레이션 시점에 보류로 내리고, 이미 담겨 있던 금액은 payload 가
        // 아니라 candidate 로 옮겨 sink 에 닿지 않게 한다.
        state = AnalyticsOutboxDeliveryState.awaitingCurrency;
        candidateValue ??= payload['value'] as num?;
        payload.remove('currency');
        payload.remove('value');
      }
      final rawError = map['last_currency_error'] as String?;
      final rawNextAt = map['currency_next_at'] as String?;
      return AnalyticsOutboxEntry._(
        kind: kind,
        id: id,
        aliases: aliases.isEmpty ? <String>[id] : aliases,
        payload: payload,
        userId: map['user_id'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String).toUtc(),
        deliveryConfirmed: map['delivery_confirmed'] == true,
        deliveryState: state,
        storeProductId: map['store_product_id'] as String?,
        candidateValue: candidateValue,
        currencyAttempts: (map['currency_attempts'] as num?)?.toInt() ?? 0,
        currencyNextAt: rawNextAt == null
            ? null
            : DateTime.parse(rawNextAt).toUtc(),
        lastCurrencyError: rawError == null
            ? null
            : PurchaseCurrencyError.values.byName(rawError),
      );
    } catch (e, s) {
      logger.e(
        'GA4 outbox 항목 파싱 실패 — 항목을 보존할 수 없음: $raw',
        error: e,
        stackTrace: s,
      );
      return null;
    }
  }
}

class _DeliveredEntry {
  const _DeliveredEntry({
    required this.kind,
    required this.aliases,
    required this.deliveredAt,
  });

  final AnalyticsOutboxEventKind kind;
  final List<String> aliases;
  final DateTime deliveredAt;

  Map<String, Object> toJson() => <String, Object>{
    'kind': kind.name,
    'aliases': aliases,
    'delivered_at': deliveredAt.toIso8601String(),
  };

  static _DeliveredEntry? fromJson(Object? raw) {
    if (raw is! Map) return null;
    try {
      final map = Map<String, dynamic>.from(raw);
      return _DeliveredEntry(
        kind: AnalyticsOutboxEventKind.values.byName(map['kind'] as String),
        aliases: <String>[
          for (final value in map['aliases'] as List<dynamic>)
            if (value is String && value.isNotEmpty) value,
        ],
        deliveredAt: DateTime.parse(map['delivered_at'] as String).toUtc(),
      );
    } catch (e, s) {
      logger.e('GA4 outbox delivered 마커 파싱 실패: $raw', error: e, stackTrace: s);
      return null;
    }
  }
}

class _OutboxState {
  _OutboxState({
    required this.pending,
    required this.delivered,
    required this.deadLetters,
  });

  final List<AnalyticsOutboxEntry> pending;
  final List<_DeliveredEntry> delivered;
  final List<AnalyticsDeadLetter> deadLetters;

  Map<String, Object> toJson() => <String, Object>{
    'version': 2,
    'pending': pending.map((entry) => entry.toJson()).toList(),
    'delivered': delivered.map((entry) => entry.toJson()).toList(),
    'dead_letters': deadLetters.map((entry) => entry.toJson()).toList(),
  };
}

/// 스토어 거래, 위젯, 프로세스 수명과 분리된 GA4 durable outbox.
///
/// 저장은 하나의 JSON envelope(`pending` + `delivered`)를 storage-key 전역
/// mutex 안에서 read-modify-write 한다. 성공 반환을 받은 항목만 pending 에서
/// 제거하며, 프로세스 재시작 시 [flush] 가 남은 항목을 재시도한다.
///
/// 전달 보장은 이벤트별로 다르다.
///
/// * purchase: at-least-once. 성공 뒤 제거 저장이 실패해도 다음 실행에서 다시
///   보낸다. GA4 transaction_id 중복 제거가 있으므로 누락 방지가 우선이다.
/// * earn/login/sign_up: 성공 확인 비트를 먼저 영속화해 성공 뒤 cleanup 실패의
///   중복을 막는다. false/timeout/throw는 pending을 유지하고 재시도한다. 서버
///   중복 제거가 없어 성공과 비트 저장 사이의 프로세스 종료에는 중복 가능성이
///   남지만, 성공하지 않은 이벤트를 제거해 영구 누락시키지는 않는다.
class AnalyticsOutbox {
  AnalyticsOutbox({
    LocalStorage? storage,
    Ga4Sink sink = const FirebaseGa4Sink(),
    this.ioTimeout = const Duration(seconds: 2),
    this.sendTimeout = const Duration(seconds: 5),
    this.maxPendingEntries = 200,
    this.maxDeliveredEntries = 500,
    this.pendingMaxAge = const Duration(days: 30),
    this.purchasePendingMaxAge = const Duration(days: 365),
    this.deliveredMaxAge = const Duration(days: 180),
    this.retryDelay = const Duration(seconds: 30),
    this.currencyRetryDelay = const Duration(seconds: 30),
    this.maxCurrencyRetryDelay = const Duration(minutes: 5),
    this.currencyResolveTimeout = const Duration(seconds: 3),
    this.maxDeadLetters = 50,
    PurchaseCurrencyResolver? currencyResolver,
    DateTime Function()? clock,
    String? Function()? activeUserIdReader,
    String? Function()? activeLanguageReader,
  }) : _storage = storage,
       _sink = sink,
       _currencyResolver = currencyResolver,
       _clock = clock ?? DateTime.now,
       _activeUserIdReader = activeUserIdReader,
       _activeLanguageReader = activeLanguageReader;

  static const String storageKey = 'analytics_ga4_outbox_v1';

  static AnalyticsOutbox _instance = AnalyticsOutbox();
  static String? Function()? _globalActiveUserIdReader;
  static String? Function()? _globalActiveLanguageReader;
  static PurchaseCurrencyResolver? _globalCurrencyResolver;

  static AnalyticsOutbox get instance => _instance;

  static void configureActiveUserIdReader(String? Function() reader) {
    _globalActiveUserIdReader = reader;
  }

  static void configureActiveUserContext({
    required String? Function() userIdReader,
    required String? Function() languageReader,
  }) {
    _globalActiveUserIdReader = userIdReader;
    _globalActiveLanguageReader = languageReader;
  }

  /// 보류 중인 매출 이벤트가 통화를 되찾을 유일한 경로를 등록한다.
  ///
  /// 이 등록이 없으면 `awaiting_currency` 항목은 같은 거래가 다시 전달되지
  /// 않는 한 영원히 보류로 남았다가 만료된다 — 상태 머신은 있는데 그걸
  /// 진행시킬 것이 아무것도 없는 상태다. 싱글턴은 스토어 카탈로그를 알지
  /// 못하므로 상위 오케스트레이션이 연결한다.
  static void configureCurrencyResolver(PurchaseCurrencyResolver? resolver) {
    _globalCurrencyResolver = resolver;
  }

  @visibleForTesting
  static void overrideInstance(AnalyticsOutbox outbox) {
    _instance._retryTimer?.cancel();
    _instance = outbox;
  }

  @visibleForTesting
  static void resetInstance() {
    _instance._retryTimer?.cancel();
    _instance = AnalyticsOutbox();
    _globalActiveUserIdReader = null;
    _globalActiveLanguageReader = null;
    _globalCurrencyResolver = null;
  }

  final LocalStorage? _storage;
  final Ga4Sink _sink;
  final DateTime Function() _clock;
  final String? Function()? _activeUserIdReader;
  final String? Function()? _activeLanguageReader;
  final Duration ioTimeout;
  final Duration sendTimeout;
  final int maxPendingEntries;
  final int maxDeliveredEntries;
  final Duration pendingMaxAge;
  final Duration purchasePendingMaxAge;
  final Duration deliveredMaxAge;
  final Duration retryDelay;

  /// 보류 중인 매출 이벤트의 통화 재조회 백오프. 첫 실패 뒤 이만큼 기다리고,
  /// 실패마다 두 배로 늘리되 [maxCurrencyRetryDelay] 에서 멈춘다.
  final Duration currencyRetryDelay;
  final Duration maxCurrencyRetryDelay;
  final Duration currencyResolveTimeout;
  final int maxDeadLetters;
  final PurchaseCurrencyResolver? _currencyResolver;

  LocalStorage get _s => _storage ?? globalStorage;

  static final Set<String> _inFlight = <String>{};
  static final Set<String> _deliveredInProcess = <String>{};

  /// sink 실패(false/timeout/throw) 시각. 같은 프로세스의 후속 flush 가
  /// [retryDelay] 이 지나기 전에 같은 항목을 즉시 재전송하지 않게 한다.
  /// 재시도는 [_scheduleRetry] 타이머나 프로세스 재시작이 담당한다.
  static final Map<String, DateTime> _lastSinkFailureAt = <String, DateTime>{};
  Future<void> _drainTail = Future<void>.value();

  @visibleForTesting
  static void resetProcessStateForTest() {
    _inFlight.clear();
    _deliveredInProcess.clear();
    _lastSinkFailureAt.clear();
    AnalyticsMarkerMutex.resetForTest();
  }

  /// payload 를 먼저 영속화한다. 저장이 확인된 뒤에만 `true`다.
  ///
  /// [flush] 를 true 로 주면 저장 뒤 drain까지 기다리지만, 제품 호출부는 UX를
  /// 막지 않도록 false 로 enqueue한 다음 `unawaited(outbox.flush())`를 쓴다.
  Future<bool> enqueue(AnalyticsOutboxEntry entry, {bool flush = false}) async {
    if (entry.id.trim().isEmpty) {
      logger.e('GA4 outbox enqueue 거부 — idempotency key 가 비어 있음');
      return false;
    }

    final stored = await AnalyticsMarkerMutex.runExclusive(
      storageKey,
      () async {
        final state = await _load();
        if (state == null) return false;
        final beforePending = state.pending.length;
        final beforeDelivered = state.delivered.length;
        _pruneExpired(state);
        if (_contains(state, entry)) {
          if (beforePending != state.pending.length ||
              beforeDelivered != state.delivered.length) {
            return _save(state);
          }
          return true;
        }
        if (state.pending.length >= maxPendingEntries) {
          logger.e(
            'GA4 outbox 용량 상한($maxPendingEntries) 도달 — '
            '미전송 기존 항목을 밀어내지 않고 신규 항목 거부: '
            '${entry.processKey}',
          );
          return false;
        }
        state.pending.add(entry);
        return _save(state);
      },
    );
    if (flush && stored) await this.flush();
    return stored;
  }

  /// 매출 purchase 를 durable 하게 저장하거나, 같은 거래의 기존 항목을 보강한다.
  ///
  /// tx/op alias 가 하나라도 겹치는 pending 항목이 있으면 새 항목을 만들지 않고
  /// 같은 mutex 안에서 비어 있던 통화·금액만 채운다. 같은 거래가 foreground
  /// 응답과 큐 복구 양쪽으로 도착해도 이벤트는 하나다.
  ///
  /// 통화 우선순위는 §7 그대로다.
  ///
  /// 1. 서버 통화가 있으면 무조건 서버 값 — 금액도 서버 것만 쓴다. 카탈로그
  ///    가격을 끌어와 "서버 통화 + 클라이언트 금액"으로 짜깁기하지 않는다.
  ///    카탈로그 가격은 카탈로그 자신의 통화 기준이라 쌍 자체가 틀려진다.
  /// 2. 서버 통화가 없으면 카탈로그의 통화·금액을 **쌍으로** 쓴다(오늘의 동작).
  /// 3. 그것도 없으면 요청과 함께 관측한 storefront 통화를 통화만 쓴다.
  /// 4. 어느 것도 없으면 저장은 하되 보류한다 — 전송하지 않는다.
  Future<PurchaseOutboxResult> enqueueOrMergePurchase({
    required String id,
    required List<String> aliases,
    required String transactionId,
    required List<Ga4PurchaseItem> items,
    String? serverCurrency,
    num? serverValue,
    String? catalogCurrency,
    num? catalogValue,
    String? clientObservedCurrency,
    String? storeProductId,
    DateTime? createdAt,
  }) async {
    if (id.trim().isEmpty) {
      logger.e('GA4 outbox purchase 저장 거부 — idempotency key 가 비어 있음');
      return PurchaseOutboxResult.failed;
    }

    final server = normalizeIso4217(serverCurrency);
    final catalog = normalizeIso4217(catalogCurrency);
    final observed = normalizeIso4217(clientObservedCurrency);
    final String? currency = server ?? catalog ?? observed;
    final num? value = server != null
        ? serverValue
        : (catalog != null ? catalogValue : null);
    final num? candidate = currency == null
        ? (serverValue ?? catalogValue)
        : null;

    final incoming = AnalyticsOutboxEntry.purchase(
      id: id,
      aliases: aliases,
      transactionId: transactionId,
      currency: currency,
      value: value,
      items: items,
      storeProductId: storeProductId,
      candidateValue: candidate,
      createdAt: createdAt,
    );

    return AnalyticsMarkerMutex.runExclusive(storageKey, () async {
      final state = await _load();
      if (state == null) return PurchaseOutboxResult.failed;
      _pruneExpired(state);

      if (_deliveredInProcess.contains(incoming.processKey) ||
          _deliveredContains(state, incoming)) {
        // 이미 GA4 로 나간 거래다. 다시 큐에 넣지 않지만, 호출부 입장에서는
        // "durable 하게 처리됐다"가 맞으므로 성공으로 답한다.
        await _save(state);
        return PurchaseOutboxResult.ready;
      }

      final index = state.pending.indexWhere(
        (candidate) =>
            candidate.kind == AnalyticsOutboxEventKind.purchase &&
            _overlaps(candidate.aliases, incoming.aliases),
      );
      if (index < 0) {
        if (state.pending.length >= maxPendingEntries) {
          logger.e(
            'GA4 outbox 용량 상한($maxPendingEntries) 도달 — '
            '미전송 기존 항목을 밀어내지 않고 신규 항목 거부: '
            '${incoming.processKey}',
          );
          return PurchaseOutboxResult.failed;
        }
        state.pending.add(incoming);
        if (!await _save(state)) return PurchaseOutboxResult.failed;
        return incoming.isAwaitingCurrency
            ? PurchaseOutboxResult.deferred
            : PurchaseOutboxResult.ready;
      }

      final merged = _mergePurchase(state.pending[index], incoming);
      state.pending[index] = merged;
      if (!await _save(state)) return PurchaseOutboxResult.failed;
      return merged.isAwaitingCurrency
          ? PurchaseOutboxResult.deferred
          : PurchaseOutboxResult.ready;
    });
  }

  /// 기존 항목을 정본으로 두고 비어 있던 것만 채운다.
  ///
  /// 이미 통화가 확정된 항목은 재전달이 덮어쓰지 않는다 — 최초 확정값이
  /// 정본이고, 뒤늦게 도착한 다른 값으로 갈아타면 같은 거래의 매출이 세션마다
  /// 달라진다.
  AnalyticsOutboxEntry _mergePurchase(
    AnalyticsOutboxEntry existing,
    AnalyticsOutboxEntry incoming,
  ) {
    final aliases = <String>[
      ...existing.aliases,
      for (final alias in incoming.aliases)
        if (!existing.aliases.contains(alias)) alias,
    ];
    if (!existing.isAwaitingCurrency) {
      return existing.copyWith(
        aliases: aliases,
        storeProductId: existing.storeProductId ?? incoming.storeProductId,
      );
    }

    final incomingCurrency = incoming.payload['currency'] as String?;
    if (incomingCurrency == null) {
      return existing.copyWith(
        aliases: aliases,
        storeProductId: existing.storeProductId ?? incoming.storeProductId,
        candidateValue: existing.candidateValue ?? incoming.candidateValue,
      );
    }

    final payload = Map<String, Object>.from(existing.payload)
      ..['currency'] = incomingCurrency;
    // 들어온 쌍만 쓴다. 보류 중 모아 둔 candidate 금액을 이 통화 옆에 붙이면
    // 서로 다른 출처의 통화와 금액이 한 쌍이 된다 — 서버가 통화만 준
    // 정상 케이스(Google 폴백)에서 예전 카탈로그 금액이 서버 매출로 둔갑한다.
    final value = incoming.payload['value'] as num?;
    if (value != null) payload['value'] = value;
    return existing.copyWith(
      aliases: aliases,
      payload: payload,
      storeProductId: existing.storeProductId ?? incoming.storeProductId,
      deliveryState: AnalyticsOutboxDeliveryState.ready,
      clearCandidateValue: true,
      clearCurrencyNextAt: true,
    );
  }

  /// 남은 모든 항목을 한 번씩 시도한다. 항목 하나의 timeout/실패가 다음 항목을
  /// 막지 않으며, 같은 항목은 저장소 키 전역 in-flight set 으로 원자 예약된다.
  Future<void> flush() async {
    final next = _drainTail.then((_) => _flushOnce());
    _drainTail = next.catchError((Object _) {});
    return next;
  }

  Future<void> _flushOnce() async {
    final state = await AnalyticsMarkerMutex.runExclusive(storageKey, () async {
      final loaded = await _load();
      if (loaded == null) return null;
      final beforePending = loaded.pending.length;
      final beforeDelivered = loaded.delivered.length;
      _pruneExpired(loaded);
      if (beforePending != loaded.pending.length ||
          beforeDelivered != loaded.delivered.length) {
        await _save(loaded);
      }
      return loaded;
    });
    if (state == null) {
      _scheduleRetry();
      return;
    }
    for (final entry in List<AnalyticsOutboxEntry>.of(state.pending)) {
      var current = entry;
      if (current.isAwaitingCurrency) {
        // 통화가 없는 매출 이벤트는 sink 대상이 아니다. 이 자리에서 한 번
        // 되찾아 보고, 실패하면 다음 항목으로 넘어간다 — 하나가 막혀도 나머지
        // drain 은 계속돼야 한다.
        final resolved = await _resolveDeferredCurrency(current);
        if (resolved == null) continue;
        current = resolved;
      }
      final lastFailure = _lastSinkFailureAt[current.processKey];
      if (lastFailure != null &&
          _clock().toUtc().difference(lastFailure) < retryDelay) {
        // 직전에 실패한 항목을 같은 세션의 연쇄 flush 가 즉시 다시 보내면
        // 진짜 실패는 어차피 또 실패하고, 일시 실패는 중복 발송이 된다.
        _scheduleRetry();
        continue;
      }
      await _sendOne(current);
    }
  }

  /// 보류 중인 매출 이벤트의 통화를 한 번 되찾아 본다.
  ///
  /// 성공하면 payload 를 원자 보강한 항목을, 실패하면 `null` 을 돌려준다.
  /// 실패는 시도 횟수와 다음 시각으로 영속화돼 재시작 뒤에도 이어진다.
  Future<AnalyticsOutboxEntry?> _resolveDeferredCurrency(
    AnalyticsOutboxEntry entry,
  ) async {
    final now = _clock().toUtc();
    final nextAt = entry.currencyNextAt;
    if (nextAt != null && now.isBefore(nextAt)) {
      _scheduleRetry();
      return null;
    }

    final resolver = _currencyResolver ?? _globalCurrencyResolver;
    final productId = entry.storeProductId ?? _productIdFromItems(entry);
    String? resolved;
    var failure = PurchaseCurrencyError.catalogUnavailable;
    if (resolver == null) {
      failure = PurchaseCurrencyError.catalogUnavailable;
    } else if (productId == null || productId.isEmpty) {
      failure = PurchaseCurrencyError.productMissing;
    } else {
      try {
        final raw = await resolver
            .resolve(productId)
            .timeout(currencyResolveTimeout);
        resolved = normalizeIso4217(raw);
        if (resolved == null) {
          failure = raw == null
              ? PurchaseCurrencyError.productMissing
              : PurchaseCurrencyError.invalidIso4217;
        }
      } on TimeoutException {
        failure = PurchaseCurrencyError.resolverTimeout;
      } catch (e, s) {
        logger.w(
          'GA4 outbox 통화 재조회 실패: ${entry.processKey}',
          error: e,
          stackTrace: s,
        );
        failure = PurchaseCurrencyError.catalogUnavailable;
      }
    }

    if (resolved == null) {
      await _recordCurrencyFailure(entry.processKey, failure);
      _scheduleRetry();
      return null;
    }
    return _promoteToReady(entry.processKey, resolved);
  }

  /// storage v1 에서 올라온 항목에는 `store_product_id` 가 없다. 그 시절에도
  /// item_name 에는 canonical 스토어 상품 ID 가 들어가 있었으므로 재조회 키로
  /// 쓴다. 맞지 않으면 resolver 가 못 찾을 뿐이고, 없는 것보다 나쁘지 않다.
  String? _productIdFromItems(AnalyticsOutboxEntry entry) {
    final items = entry.payload['items'];
    if (items is! List || items.isEmpty) return null;
    final first = items.first;
    if (first is! Map) return null;
    final name = first['item_name'];
    return name is String && name.isNotEmpty ? name : null;
  }

  /// 다음 재조회까지의 간격. 30초에서 시작해 두 배씩, 5분에서 멈춘다.
  Duration _currencyBackoff(int attempts) {
    var delay = currencyRetryDelay;
    for (var i = 1; i < attempts && delay < maxCurrencyRetryDelay; i++) {
      delay *= 2;
    }
    return delay > maxCurrencyRetryDelay ? maxCurrencyRetryDelay : delay;
  }

  Future<void> _recordCurrencyFailure(
    String processKey,
    PurchaseCurrencyError error,
  ) {
    return AnalyticsMarkerMutex.runExclusive(storageKey, () async {
      final state = await _load();
      if (state == null) return;
      final index = state.pending.indexWhere(
        (entry) => entry.processKey == processKey,
      );
      if (index < 0) return;
      final attempts = state.pending[index].currencyAttempts + 1;
      state.pending[index] = state.pending[index].copyWith(
        currencyAttempts: attempts,
        currencyNextAt: _clock().toUtc().add(_currencyBackoff(attempts)),
        lastCurrencyError: error,
      );
      await _save(state);
    });
  }

  Future<AnalyticsOutboxEntry?> _promoteToReady(
    String processKey,
    String currency,
  ) {
    return AnalyticsMarkerMutex.runExclusive(storageKey, () async {
      final state = await _load();
      if (state == null) return null;
      final index = state.pending.indexWhere(
        (entry) => entry.processKey == processKey,
      );
      if (index < 0) return null;
      final entry = state.pending[index];
      if (!entry.isAwaitingCurrency) {
        // resolver 를 await 하는 동안 같은 거래의 재전달이 서버 통화로 이미
        // 승격시켰다. 그 값이 정본이다 — 늦게 끝난 카탈로그 조회 결과로
        // 덮어쓰면 서버가 확정한 통화와 금액 쌍이 어긋난다.
        return entry;
      }
      final payload = Map<String, Object>.from(entry.payload)
        ..['currency'] = currency;
      final value = entry.candidateValue;
      if (value != null) payload['value'] = value;
      final promoted = entry.copyWith(
        payload: payload,
        deliveryState: AnalyticsOutboxDeliveryState.ready,
        clearCandidateValue: true,
        clearCurrencyNextAt: true,
      );
      state.pending[index] = promoted;
      if (!await _save(state)) return null;
      return promoted;
    });
  }

  /// payload 의 통화가 더 이상 ISO 4217 이 아니면 다시 보류로 내린다.
  Future<void> _demoteToAwaitingCurrency(String processKey) {
    return AnalyticsMarkerMutex.runExclusive(storageKey, () async {
      final state = await _load();
      if (state == null) return;
      final index = state.pending.indexWhere(
        (entry) => entry.processKey == processKey,
      );
      if (index < 0) return;
      final entry = state.pending[index];
      final payload = Map<String, Object>.from(entry.payload);
      final value = payload.remove('value') as num?;
      payload.remove('currency');
      state.pending[index] = entry.copyWith(
        payload: payload,
        deliveryState: AnalyticsOutboxDeliveryState.awaitingCurrency,
        candidateValue: entry.candidateValue ?? value,
        lastCurrencyError: PurchaseCurrencyError.invalidIso4217,
      );
      await _save(state);
    });
  }

  void _recordDeadLetter(
    _OutboxState state,
    AnalyticsOutboxEntry entry,
    DateTime now,
  ) {
    _purchaseCurrencyDeadLetterTotal++;
    state.deadLetters.add(
      AnalyticsDeadLetter(
        id: entry.id,
        aliases: entry.aliases,
        attempts: entry.currencyAttempts,
        reason:
            entry.lastCurrencyError?.name ??
            (entry.isAwaitingCurrency ? 'awaiting_currency' : 'sink_failure'),
        expiredAt: now,
      ),
    );
    while (state.deadLetters.length > maxDeadLetters) {
      state.deadLetters.removeAt(0);
    }
  }

  static int _purchaseCurrencyDeadLetterTotal = 0;

  /// `ga4_purchase_currency_dead_letter_total` — 만료로 끝난 매출 이벤트 수.
  static int get purchaseCurrencyDeadLetterTotal =>
      _purchaseCurrencyDeadLetterTotal;

  @visibleForTesting
  Future<int> awaitingCurrencyCount() async {
    final state = await AnalyticsMarkerMutex.runExclusive(
      storageKey,
      () => _load(),
    );
    return state?.pending.where((entry) => entry.isAwaitingCurrency).length ?? 0;
  }

  @visibleForTesting
  Future<int> awaitingCurrencyAttempts(String id) async {
    final state = await AnalyticsMarkerMutex.runExclusive(
      storageKey,
      () => _load(),
    );
    for (final entry in state?.pending ?? const <AnalyticsOutboxEntry>[]) {
      if (entry.id == id) return entry.currencyAttempts;
    }
    return 0;
  }

  @visibleForTesting
  Future<Duration?> currencyRetryDelayFor(String id) async {
    final attempts = await awaitingCurrencyAttempts(id);
    return attempts == 0 ? null : _currencyBackoff(attempts);
  }

  @visibleForTesting
  Future<List<AnalyticsDeadLetter>> deadLetters() async {
    final state = await AnalyticsMarkerMutex.runExclusive(
      storageKey,
      () => _load(),
    );
    return state?.deadLetters ?? const <AnalyticsDeadLetter>[];
  }

  @visibleForTesting
  Future<int> pendingCount() async {
    final state = await AnalyticsMarkerMutex.runExclusive(
      storageKey,
      () => _load(),
    );
    return state?.pending.length ?? 0;
  }

  Future<void> _sendOne(AnalyticsOutboxEntry entry) async {
    final key = entry.processKey;
    // async 메서드의 첫 await 전 동기 구간. 동시에 시작한 flush 둘 중 하나만
    // true 를 얻는다.
    if (!_inFlight.add(key)) return;
    try {
      await AnalyticsMarkerMutex.runExclusive(
        '$storageKey:delivery',
        () => _deliveredInProcess.contains(key)
            ? _cleanupKnownDelivered(entry)
            : _deliverClaimed(entry),
      );
    } finally {
      _inFlight.remove(key);
    }
  }

  /// 현재 프로세스에서 sink 성공을 확인했지만 저장 단계가 실패한 항목은
  /// 재전송하지 않고 checkpoint/cleanup만 다시 시도한다.
  Future<void> _cleanupKnownDelivered(AnalyticsOutboxEntry original) async {
    var entry = await _readCurrent(original.processKey);
    if (entry == null) return;
    if (entry.kind != AnalyticsOutboxEventKind.purchase &&
        !entry.deliveryConfirmed) {
      if (!await _setDeliveryConfirmed(entry.processKey)) {
        _scheduleRetry();
        return;
      }
      entry = entry.copyWith(deliveryConfirmed: true);
    }
    if (!await _markDelivered(entry)) _scheduleRetry();
  }

  Future<void> _deliverClaimed(AnalyticsOutboxEntry original) async {
    var entry = await _readCurrent(original.processKey);
    if (entry == null || _deliveredInProcess.contains(original.processKey)) {
      return;
    }

    // 최종 방어선. 저장 이후 어떤 경로로 payload 가 바뀌었든, 통화 없는 매출
    // 이벤트가 sink 에 닿는 일은 없어야 한다 — GA4 는 그런 purchase 의 매출을
    // 통째로 무시하므로 "보냈지만 매출은 0" 이 조용히 만들어진다.
    if (entry.kind == AnalyticsOutboxEventKind.purchase &&
        !isIso4217(entry.payload['currency'])) {
      logger.e(
        'GA4 outbox 매출 purchase 의 통화가 ISO 4217 이 아님 — '
        '전송하지 않고 보류로 되돌림: ${entry.processKey}',
      );
      await _demoteToAwaitingCurrency(entry.processKey);
      _scheduleRetry();
      return;
    }

    if (entry.kind != AnalyticsOutboxEventKind.purchase &&
        entry.deliveryConfirmed) {
      // 이 비트는 sink가 true를 반환한 뒤에만 저장된다. 이전 프로세스가
      // pending cleanup에서 실패한 것이므로 재전송하지 않고 정리만 재시도한다.
      if (!await _markDelivered(entry)) _scheduleRetry();
      return;
    }

    var delivered = false;
    try {
      delivered = await _dispatch(entry);
    } on TimeoutException catch (e, s) {
      logger.e(
        'GA4 outbox sink timeout(${sendTimeout.inMilliseconds}ms): '
        '${entry.processKey}',
        error: e,
        stackTrace: s,
      );
    } catch (e, s) {
      logger.e(
        'GA4 outbox sink 실패: ${entry.processKey}',
        error: e,
        stackTrace: s,
      );
    }

    if (!delivered) {
      _lastSinkFailureAt[entry.processKey] = _clock().toUtc();
      _scheduleRetry();
      return;
    }
    _lastSinkFailureAt.remove(entry.processKey);

    if (entry.kind != AnalyticsOutboxEventKind.purchase &&
        !await _setDeliveryConfirmed(entry.processKey)) {
      // 성공은 확인했지만 그 사실을 durable하게 남기지 못했다. 같은 실행의
      // 재진입은 막되, 재시작에서는 at-least-once 원칙상 다시 보낼 수 있다.
      _deliveredInProcess.add(entry.processKey);
      logger.e(
        'GA4 outbox sink 성공 후 확인 비트 저장 실패 — 재시작 시 중복 가능: '
        '${entry.processKey}',
      );
      _scheduleRetry();
      return;
    }

    if (await _markDelivered(entry)) {
      _deliveredInProcess.add(entry.processKey);
    } else {
      final policy = entry.kind == AnalyticsOutboxEventKind.purchase
          ? '재시작 후 재전송(transaction_id dedup)'
          : '재시작 후 delivery_confirmed로 재전송 없이 cleanup 재시도';
      logger.e(
        'GA4 outbox 전송 성공 후 제거 저장 실패 — $policy: '
        '${entry.processKey}',
      );
      _scheduleRetry();
    }
  }

  Timer? _retryTimer;

  void _scheduleRetry() {
    // 제품은 singleton을 쓰고, 테스트/호출부 주입 인스턴스는 명시적으로 flush
    // 한다. 주입 인스턴스의 Timer가 테스트 종료 뒤 남는 것도 막는다.
    if (!identical(this, _instance) || _retryTimer != null) return;
    _retryTimer = Timer(retryDelay, () {
      _retryTimer = null;
      unawaited(flush());
    });
  }

  Future<bool> _dispatch(AnalyticsOutboxEntry entry) {
    if (entry.kind == AnalyticsOutboxEventKind.purchase) {
      final rawItems = entry.payload['items'] as List<dynamic>;
      return _sink
          .logPurchase(
            transactionId: entry.payload['transaction_id'] as String?,
            // 저장된 철자가 아니라 관문을 통과한 값을 보낸다. v1 에서 올라온
            // 항목이나 손으로 만든 저장소 값은 ' krw ' 같은 모양일 수 있다.
            currency: normalizeIso4217(entry.payload['currency']),
            value: entry.payload['value'] as num?,
            items: <Ga4PurchaseItem>[
              for (final raw in rawItems)
                Ga4PurchaseItem(
                  itemId: (raw as Map)['item_id'] as String?,
                  itemName: raw['item_name'] as String?,
                  virtualCurrencyName: raw['virtual_currency_name'] as String?,
                  baseAmount: raw['base_amount'] as num?,
                  bonusAmount: raw['bonus_amount'] as num?,
                ),
            ],
          )
          .timeout(sendTimeout);
    }

    return _dispatchEvent(entry);
  }

  Future<bool> _dispatchEvent(AnalyticsOutboxEntry entry) async {
    final eventName = switch (entry.kind) {
      AnalyticsOutboxEventKind.earnVirtualCurrency =>
        Ga4Event.earnVirtualCurrency,
      AnalyticsOutboxEventKind.login => Ga4Event.login,
      AnalyticsOutboxEventKind.signUp => Ga4Event.signUp,
      AnalyticsOutboxEventKind.purchase => throw StateError('unreachable'),
    };
    final parameters = Map<String, Object>.from(
      entry.payload['parameters'] as Map,
    );

    if (entry.kind == AnalyticsOutboxEventKind.earnVirtualCurrency) {
      return _sink.logEvent(eventName, parameters).timeout(sendTimeout);
    }

    // auth 이벤트의 GA4 user_id 는 전역 mutable 상태다. captured user 를 설정하고
    // 이벤트를 기록한 뒤, 그 사이 실제로 바뀐 현재 사용자(B 또는 logout)를
    // 반드시 복원한다. delivery mutex 가 다른 auth 이벤트와 이 묶음을 섞지 않는다.
    final captured = entry.userId;
    final rawUserProperties = entry.payload['user_properties'];
    final userProperties = rawUserProperties is Map
        ? Map<String, dynamic>.from(rawUserProperties)
        : const <String, dynamic>{};
    final capturedLanguage =
        userProperties[Ga4UserProperty.language] as String?;
    final setFuture = _applyAuthContext(
      userId: captured,
      isLogin: true,
      language: capturedLanguage,
    );
    try {
      final set = await setFuture.timeout(sendTimeout);
      if (!set) {
        await _restoreActiveUser();
        return false;
      }
    } on TimeoutException {
      // Future.timeout 은 하위 future 를 취소하지 않는다. 늦게 A 를 설정하는
      // completion 이 오면 그 직후 현재 사용자로 다시 돌려 전역 부활을 막는다.
      unawaited(
        setFuture
            .whenComplete(() => _restoreActiveUser())
            .catchError((Object e, StackTrace s) => false),
      );
      await _restoreActiveUser();
      rethrow;
    } catch (_) {
      await _restoreActiveUser();
      rethrow;
    }

    try {
      return await _sink.logEvent(eventName, parameters).timeout(sendTimeout);
    } finally {
      await _restoreActiveUser();
    }
  }

  Future<bool> _restoreActiveUser() async {
    String? active;
    String? language;
    try {
      active = (_activeUserIdReader ?? _globalActiveUserIdReader)?.call();
      language = (_activeLanguageReader ?? _globalActiveLanguageReader)?.call();
    } catch (e, s) {
      logger.e(
        'GA4 outbox 현재 auth user 조회 실패 — logout 상태로 복원',
        error: e,
        stackTrace: s,
      );
    }
    try {
      return await _applyAuthContext(
        userId: active,
        isLogin: active != null,
        language: language,
      );
    } catch (e, s) {
      logger.e(
        'GA4 outbox auth user_id 복원 실패: $active',
        error: e,
        stackTrace: s,
      );
      return false;
    }
  }

  Future<bool> _applyAuthContext({
    required String? userId,
    required bool isLogin,
    required String? language,
  }) async {
    final results = await Future.wait<bool>(<Future<bool>>[
      _sink.setUserId(userId),
      _sink.setUserProperty(
        Ga4UserProperty.isLogin,
        isLogin ? Ga4Value.loggedIn : Ga4Value.loggedOut,
      ),
      if (language != null)
        _sink.setUserProperty(Ga4UserProperty.language, language),
    ]).timeout(sendTimeout);
    return results.every((result) => result);
  }

  Future<AnalyticsOutboxEntry?> _readCurrent(String processKey) {
    return AnalyticsMarkerMutex.runExclusive(storageKey, () async {
      final state = await _load();
      if (state == null) return null;
      for (final entry in state.pending) {
        if (entry.processKey == processKey) return entry;
      }
      return null;
    });
  }

  Future<bool> _setDeliveryConfirmed(String processKey) {
    return AnalyticsMarkerMutex.runExclusive(storageKey, () async {
      final state = await _load();
      if (state == null) return false;
      final index = state.pending.indexWhere(
        (entry) => entry.processKey == processKey,
      );
      if (index < 0) return false;
      state.pending[index] = state.pending[index].copyWith(
        deliveryConfirmed: true,
      );
      return _save(state);
    });
  }

  Future<bool> _markDelivered(AnalyticsOutboxEntry entry) {
    return AnalyticsMarkerMutex.runExclusive(storageKey, () async {
      final state = await _load();
      if (state == null) return false;
      state.pending.removeWhere(
        (candidate) => candidate.processKey == entry.processKey,
      );
      if (!_deliveredContains(state, entry)) {
        state.delivered.add(
          _DeliveredEntry(
            kind: entry.kind,
            aliases: entry.aliases,
            deliveredAt: _clock().toUtc(),
          ),
        );
      }
      while (state.delivered.length > maxDeliveredEntries) {
        final removed = state.delivered.removeAt(0);
        logger.w(
          'GA4 outbox delivered 마커 용량 초과로 관측 가능하게 '
          '밀어냄: ${removed.kind.name}:${removed.aliases}',
        );
      }
      final saved = await _save(state);
      return saved;
    });
  }

  bool _contains(_OutboxState state, AnalyticsOutboxEntry entry) {
    if (_deliveredInProcess.contains(entry.processKey)) return true;
    for (final pending in state.pending) {
      if (pending.kind == entry.kind &&
          _overlaps(pending.aliases, entry.aliases)) {
        return true;
      }
    }
    return _deliveredContains(state, entry);
  }

  bool _deliveredContains(_OutboxState state, AnalyticsOutboxEntry entry) {
    for (final delivered in state.delivered) {
      if (delivered.kind == entry.kind &&
          _overlaps(delivered.aliases, entry.aliases)) {
        return true;
      }
    }
    return false;
  }

  static bool _overlaps(List<String> a, List<String> b) {
    final left = a.toSet();
    return b.any(left.contains);
  }

  void _pruneExpired(_OutboxState state) {
    final now = _clock().toUtc();
    state.pending.removeWhere((entry) {
      final maxAge = entry.kind == AnalyticsOutboxEventKind.purchase
          ? purchasePendingMaxAge
          : pendingMaxAge;
      final expired = now.difference(entry.createdAt) > maxAge;
      if (expired) {
        logger.e(
          'GA4 outbox 미전송 항목 만료($maxAge) — '
          '관측 가능하게 제거: ${entry.processKey}',
        );
        if (entry.kind == AnalyticsOutboxEventKind.purchase) {
          // 만료돼도 통화 없이 보내는 폴백은 없다. 대신 왜 이 거래의 매출이
          // 없는지 나중에 답할 수 있게 요약만 남긴다. payload·영수증은 담지
          // 않는다.
          _recordDeadLetter(state, entry, now);
        }
      }
      return expired;
    });
    state.delivered.removeWhere((entry) {
      final expired = now.difference(entry.deliveredAt) > deliveredMaxAge;
      if (expired) {
        logger.w(
          'GA4 outbox delivered 마커 만료($deliveredMaxAge): '
          '${entry.kind.name}:${entry.aliases}',
        );
      }
      return expired;
    });
  }

  Future<_OutboxState?> _load() async {
    String? raw;
    try {
      raw = await _s.loadData(storageKey, null).timeout(ioTimeout);
    } on TimeoutException catch (e, s) {
      logger.e(
        'GA4 outbox 로드 timeout(${ioTimeout.inMilliseconds}ms)',
        error: e,
        stackTrace: s,
      );
      return null;
    } catch (e, s) {
      logger.e('GA4 outbox 로드 실패', error: e, stackTrace: s);
      return null;
    }
    if (raw == null || raw.isEmpty) {
      return _OutboxState(
        pending: <AnalyticsOutboxEntry>[],
        delivered: <_DeliveredEntry>[],
        deadLetters: <AnalyticsDeadLetter>[],
      );
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) throw const FormatException('root is not object');
      final map = Map<String, dynamic>.from(decoded);
      // v1 은 currency/value 보류 상태가 없던 형태다. 항목 파서가 마이그레이션을
      // 담당하므로 여기서는 읽기만 허용하면 된다.
      if (map['version'] != 1 && map['version'] != 2) {
        throw FormatException('unsupported version: ${map['version']}');
      }
      final pending = <AnalyticsOutboxEntry>[];
      for (final rawEntry in map['pending'] as List<dynamic>) {
        final entry = AnalyticsOutboxEntry.fromJson(rawEntry);
        if (entry != null) pending.add(entry);
      }
      final delivered = <_DeliveredEntry>[];
      for (final rawEntry in map['delivered'] as List<dynamic>) {
        final entry = _DeliveredEntry.fromJson(rawEntry);
        if (entry != null) delivered.add(entry);
      }
      final deadLetters = <AnalyticsDeadLetter>[];
      for (final rawEntry in (map['dead_letters'] as List<dynamic>?) ??
          const <dynamic>[]) {
        final entry = AnalyticsDeadLetter.fromJson(rawEntry);
        if (entry != null) deadLetters.add(entry);
      }
      return _OutboxState(
        pending: pending,
        delivered: delivered,
        deadLetters: deadLetters,
      );
    } catch (e, s) {
      // 깨진 목록 위에 빈 목록을 저장하면 모든 미전송 이벤트가 조용히 사라진다.
      logger.e('GA4 outbox 파싱 실패 — 기존 값을 덮어쓰지 않음', error: e, stackTrace: s);
      return null;
    }
  }

  Future<bool> _save(_OutboxState state) async {
    try {
      await _s
          .saveData(storageKey, jsonEncode(state.toJson()))
          .timeout(ioTimeout);
      return true;
    } on TimeoutException catch (e, s) {
      logger.e(
        'GA4 outbox 저장 timeout(${ioTimeout.inMilliseconds}ms)',
        error: e,
        stackTrace: s,
      );
      return false;
    } catch (e, s) {
      logger.e('GA4 outbox 저장 실패', error: e, stackTrace: s);
      return false;
    }
  }
}
