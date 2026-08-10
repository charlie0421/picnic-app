import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:picnic_lib/core/analytics/analytics_send_markers.dart';
import 'package:picnic_lib/core/analytics/ga4_purchase_item.dart';
import 'package:picnic_lib/core/analytics/ga4_sink.dart';
import 'package:picnic_lib/core/analytics/ga4_taxonomy.dart';
import 'package:picnic_lib/core/constatns/constants.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/storage/local_storage.dart';

enum AnalyticsOutboxEventKind { purchase, earnVirtualCurrency, login, signUp }

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

  factory AnalyticsOutboxEntry.purchase({
    required String id,
    required List<String> aliases,
    required String transactionId,
    required String? currency,
    required num? value,
    required List<Ga4PurchaseItem> items,
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
    if (currency != null) payload['currency'] = currency;
    if (value != null) payload['value'] = value;
    return AnalyticsOutboxEntry._(
      kind: AnalyticsOutboxEventKind.purchase,
      id: id,
      aliases: aliases.isEmpty ? <String>[id] : List<String>.of(aliases),
      payload: payload,
      userId: null,
      createdAt: (createdAt ?? DateTime.now()).toUtc(),
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

  String get processKey => '${kind.name}:$id';

  AnalyticsOutboxEntry copyWith({bool? deliveryConfirmed}) =>
      AnalyticsOutboxEntry._(
        kind: kind,
        id: id,
        aliases: aliases,
        payload: payload,
        userId: userId,
        createdAt: createdAt,
        deliveryConfirmed: deliveryConfirmed ?? this.deliveryConfirmed,
      );

  Map<String, Object?> toJson() => <String, Object?>{
    'kind': kind.name,
    'id': id,
    'aliases': aliases,
    'payload': payload,
    'user_id': userId,
    'created_at': createdAt.toIso8601String(),
    'delivery_confirmed': deliveryConfirmed,
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
      return AnalyticsOutboxEntry._(
        kind: kind,
        id: id,
        aliases: aliases.isEmpty ? <String>[id] : aliases,
        payload: payload,
        userId: map['user_id'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String).toUtc(),
        deliveryConfirmed: map['delivery_confirmed'] == true,
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
  _OutboxState({required this.pending, required this.delivered});

  final List<AnalyticsOutboxEntry> pending;
  final List<_DeliveredEntry> delivered;

  Map<String, Object> toJson() => <String, Object>{
    'version': 1,
    'pending': pending.map((entry) => entry.toJson()).toList(),
    'delivered': delivered.map((entry) => entry.toJson()).toList(),
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
    DateTime Function()? clock,
    String? Function()? activeUserIdReader,
    String? Function()? activeLanguageReader,
  }) : _storage = storage,
       _sink = sink,
       _clock = clock ?? DateTime.now,
       _activeUserIdReader = activeUserIdReader,
       _activeLanguageReader = activeLanguageReader;

  static const String storageKey = 'analytics_ga4_outbox_v1';

  static AnalyticsOutbox _instance = AnalyticsOutbox();
  static String? Function()? _globalActiveUserIdReader;
  static String? Function()? _globalActiveLanguageReader;

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
      final lastFailure = _lastSinkFailureAt[entry.processKey];
      if (lastFailure != null &&
          _clock().toUtc().difference(lastFailure) < retryDelay) {
        // 직전에 실패한 항목을 같은 세션의 연쇄 flush 가 즉시 다시 보내면
        // 진짜 실패는 어차피 또 실패하고, 일시 실패는 중복 발송이 된다.
        _scheduleRetry();
        continue;
      }
      await _sendOne(entry);
    }
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
            currency: entry.payload['currency'] as String?,
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
      );
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) throw const FormatException('root is not object');
      final map = Map<String, dynamic>.from(decoded);
      if (map['version'] != 1) {
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
      return _OutboxState(pending: pending, delivered: delivered);
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
