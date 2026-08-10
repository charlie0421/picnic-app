import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/analytics/analytics_outbox.dart';
import 'package:picnic_lib/core/analytics/auth_analytics_reporter.dart';
import 'package:picnic_lib/core/analytics/auth_analytics_store.dart';
import 'package:picnic_lib/core/analytics/earn_analytics_store.dart';
import 'package:picnic_lib/core/analytics/ga4_purchase_item.dart';
import 'package:picnic_lib/core/analytics/ga4_sink.dart';
import 'package:picnic_lib/core/analytics/ga4_taxonomy.dart';
import 'package:picnic_lib/data/storage/local_storage.dart';
import 'package:picnic_lib/data/models/ad/ad_reward_status.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/free_charge_analytics.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/platforms/ad_shortform_fullscreen_page.dart';

class _MemoryStorage implements LocalStorage {
  final Map<String, String> data = <String, String>{};
  bool failLoad = false;
  bool failSave = false;
  bool neverLoad = false;
  bool neverSave = false;

  @override
  Future<void> clearStorage() async => data.clear();

  @override
  Future<String?> loadData(String key, String? defaultValue) async {
    if (neverLoad) return Completer<String?>().future;
    if (failLoad) throw StateError('load failed');
    return data[key] ?? defaultValue;
  }

  @override
  Future<void> removeData(String key) async => data.remove(key);

  @override
  Future<void> saveData(String key, String value) async {
    if (neverSave) return Completer<void>().future;
    if (failSave) throw StateError('save failed');
    data[key] = value;
  }
}

class _ControllableSink implements Ga4Sink {
  bool deliver = true;
  bool neverComplete = false;
  String? currentUserId;
  final List<String> events = <String>[];
  final List<String?> eventUsers = <String?>[];
  final List<String> purchases = <String>[];
  final Map<String, List<bool>> eventResults = <String, List<bool>>{};

  Future<bool> _result() =>
      neverComplete ? Completer<bool>().future : Future<bool>.value(deliver);

  @override
  Future<bool> logEvent(String name, Map<String, Object> parameters) {
    events.add(name);
    eventUsers.add(currentUserId);
    final results = eventResults[name];
    if (results != null && results.isNotEmpty) {
      return Future<bool>.value(results.removeAt(0));
    }
    return _result();
  }

  @override
  Future<bool> logPurchase({
    required String? transactionId,
    required String? currency,
    required num? value,
    required List<Ga4PurchaseItem> items,
  }) {
    purchases.add(transactionId!);
    return _result();
  }

  @override
  Future<bool> setUserId(String? id) async {
    currentUserId = id;
    return true;
  }

  @override
  Future<bool> setUserProperty(String name, String? value) async => true;
}

AnalyticsOutboxEntry _purchase(String id) => AnalyticsOutboxEntry.purchase(
  id: id,
  aliases: <String>[id, 'op:$id'],
  transactionId: id,
  currency: 'USD',
  value: 0.99,
  items: const <Ga4PurchaseItem>[
    Ga4PurchaseItem(
      itemId: 'star100',
      itemName: 'STAR100',
      virtualCurrencyName: '별사탕',
      baseAmount: 100,
      bonusAmount: 0,
    ),
  ],
);

AnalyticsOutboxEntry _login(String signature, String userId) =>
    AnalyticsOutboxEntry.event(
      kind: AnalyticsOutboxEventKind.login,
      id: signature,
      userId: userId,
      parameters: const <String, Object>{
        Ga4Param.method: 'kakao',
        Ga4Param.selectedLanguage: 'ko',
      },
    );

void main() {
  setUp(AnalyticsOutbox.resetProcessStateForTest);
  tearDown(AnalyticsOutbox.resetProcessStateForTest);

  test('sink 실패 후 재시작하면 pending purchase 를 재전송한다', () async {
    final storage = _MemoryStorage();
    final firstSink = _ControllableSink()..deliver = false;
    final first = AnalyticsOutbox(storage: storage, sink: firstSink);

    expect(await first.enqueue(_purchase('tx-1')), isTrue);
    await first.flush();
    expect(firstSink.purchases, <String>['tx-1']);
    expect(await first.pendingCount(), 1);

    AnalyticsOutbox.resetProcessStateForTest();
    final secondSink = _ControllableSink();
    final restarted = AnalyticsOutbox(storage: storage, sink: secondSink);
    await restarted.flush();

    expect(secondSink.purchases, <String>['tx-1']);
    expect(await restarted.pendingCount(), 0);
  });

  test('purchase 성공 후 제거 저장 실패는 재시작 재전송을 허용한다', () async {
    final storage = _MemoryStorage();
    final firstSink = _ControllableSink();
    final outbox = AnalyticsOutbox(storage: storage, sink: firstSink);
    expect(await outbox.enqueue(_purchase('tx-1'), flush: false), isTrue);
    storage.failSave = true;

    await outbox.flush();
    expect(firstSink.purchases, <String>['tx-1']);

    storage.failSave = false;
    AnalyticsOutbox.resetProcessStateForTest();
    final restartedSink = _ControllableSink();
    await AnalyticsOutbox(storage: storage, sink: restartedSink).flush();

    expect(
      restartedSink.purchases,
      <String>['tx-1'],
      reason: 'purchase 는 transaction_id GA4 dedup 전제로 누락보다 재전송을 택한다',
    );
  });

  test('earn/auth 성공 후 제거 실패는 확인 checkpoint로 재시작 중복을 막는다', () async {
    final storage = _MemoryStorage();
    final firstSink = _ControllableSink();
    final outbox = AnalyticsOutbox(storage: storage, sink: firstSink);
    expect(
      await outbox.enqueue(_login('sig-1', 'user-a'), flush: false),
      isTrue,
    );

    // non-purchase 는 sink true 뒤 delivery_confirmed=true 를 영속화한다.
    // 그 다음 cleanup 저장만 실패시켜 재시작 복구 상태를 재현한다.
    var saves = 0;
    final original = storage.data;
    final selective = _SaveCountingStorage(
      original,
      onSave: () {
        saves++;
        if (saves >= 2) throw StateError('remove failed');
      },
    );
    final selectiveOutbox = AnalyticsOutbox(
      storage: selective,
      sink: firstSink,
    );
    await selectiveOutbox.flush();
    expect(firstSink.events, <String>[Ga4Event.login]);

    AnalyticsOutbox.resetProcessStateForTest();
    final restartedSink = _ControllableSink();
    await AnalyticsOutbox(storage: selective, sink: restartedSink).flush();

    expect(
      restartedSink.events,
      isEmpty,
      reason: 'GA4 dedup 없는 auth/earn 은 확인된 성공 뒤 cleanup만 재시도한다',
    );
  });

  test('never-completing sink 는 timeout 후 다음 항목을 막지 않는다', () async {
    final storage = _MemoryStorage();
    final sink = _ControllableSink()..neverComplete = true;
    final outbox = AnalyticsOutbox(
      storage: storage,
      sink: sink,
      sendTimeout: const Duration(milliseconds: 10),
    );
    await outbox.enqueue(_purchase('tx-hung'), flush: false);
    await outbox.enqueue(_purchase('tx-next'), flush: false);

    final watch = Stopwatch()..start();
    await outbox.flush();
    watch.stop();

    expect(sink.purchases, <String>['tx-hung', 'tx-next']);
    expect(watch.elapsed, lessThan(const Duration(seconds: 1)));
    expect(await outbox.pendingCount(), 2);
  });

  test('auth sink timeout 항목은 제거하지 않고 재시작 후 재시도한다', () async {
    final storage = _MemoryStorage();
    final hangingSink = _ControllableSink()..neverComplete = true;
    final first = AnalyticsOutbox(
      storage: storage,
      sink: hangingSink,
      sendTimeout: const Duration(milliseconds: 10),
    );
    await first.enqueue(_login('sig-timeout', 'user-a'), flush: false);

    await first.flush();
    expect(await first.pendingCount(), 1);

    AnalyticsOutbox.resetProcessStateForTest();
    final restartedSink = _ControllableSink();
    final restarted = AnalyticsOutbox(storage: storage, sink: restartedSink);
    await restarted.flush();

    expect(restartedSink.events, <String>[Ga4Event.login]);
    expect(await restarted.pendingCount(), 0);
  });

  test('auth A 전송 중 B 로 전환해도 A 로 기록하고 B 를 복원한다', () async {
    final storage = _MemoryStorage();
    final sink = _ControllableSink()..currentUserId = 'user-b';
    String? activeUserId = 'user-b';
    final outbox = AnalyticsOutbox(
      storage: storage,
      sink: sink,
      activeUserIdReader: () => activeUserId,
    );

    await outbox.enqueue(_login('sig-a', 'user-a'));
    await outbox.flush();

    expect(sink.eventUsers, <String?>['user-a']);
    expect(sink.currentUserId, 'user-b');

    activeUserId = null;
    await outbox.enqueue(_login('sig-a2', 'user-a'));
    await outbox.flush();
    expect(sink.eventUsers.last, 'user-a');
    expect(
      sink.currentUserId,
      isNull,
      reason: 'A 대기 중 logout 된 상태에서 A user_id 를 되살리면 안 된다',
    );
  });

  test('sign_up 실패 + login 성공이어도 다음 세션에 sign_up을 재시도한다', () async {
    final storage = _MemoryStorage();
    final firstSink = _ControllableSink()
      ..eventResults[Ga4Event.signUp] = <bool>[false]
      ..eventResults[Ga4Event.login] = <bool>[true];
    final firstOutbox = AnalyticsOutbox(storage: storage, sink: firstSink);
    final reporter = AuthAnalyticsReporter(
      store: AuthAnalyticsStore(storage: storage),
      outbox: firstOutbox,
    );

    await reporter.onSignedIn(
      userId: 'user-a',
      provider: 'kakao',
      createdAt: '2026-08-07T01:00:00.000Z',
      lastSignInAt: '2026-08-07T01:00:00.100Z',
      selectedLanguage: 'ko',
    );
    await firstOutbox.flush();
    expect(firstSink.events, <String>[Ga4Event.signUp, Ga4Event.login]);
    expect(await firstOutbox.pendingCount(), 1);

    AnalyticsOutbox.resetProcessStateForTest();
    final restartedSink = _ControllableSink();
    final restarted = AnalyticsOutbox(storage: storage, sink: restartedSink);
    await restarted.flush();

    expect(restartedSink.events, <String>[Ga4Event.signUp]);
    expect(await restarted.pendingCount(), 0);
  });

  test('legacy shortform earn 경로도 reference 기반 outbox 계약을 탄다', () async {
    final storage = _MemoryStorage();
    final failedSink = _ControllableSink()..deliver = false;
    final firstOutbox = AnalyticsOutbox(storage: storage, sink: failedSink);
    const response = InternalShortformViewResponse(
      ok: true,
      rewardAdded: 3,
      impressionId: 'impression-1',
      newBonus: 10,
    );
    const ga4 = FreeChargeAdGa4Context(
      adPlatform: FreeChargeGa4.platformInternalShortform,
      adSource: FreeChargeGa4.sourceInternalShortform,
      adUnitName: null,
      adCategory: '글로벌 픽 #1',
      virtualCurrencyName: '보너스 별사탕',
      rewardAmount: 3,
    );

    expect(
      await enqueueLegacyShortformEarnAnalytics(
        response: response,
        ga4: ga4,
        store: EarnAnalyticsStore(outbox: firstOutbox),
      ),
      isTrue,
    );
    await firstOutbox.flush();
    expect(await firstOutbox.pendingCount(), 1);

    AnalyticsOutbox.resetProcessStateForTest();
    final restartedSink = _ControllableSink();
    final restarted = AnalyticsOutbox(storage: storage, sink: restartedSink);
    await restarted.flush();
    expect(restartedSink.events, <String>[Ga4Event.earnVirtualCurrency]);
  });

  test('I/O 가 완료되지 않아도 timeout 후 동일 키 후속 작업이 무한 대기하지 않는다', () async {
    final storage = _MemoryStorage()..neverLoad = true;
    final outbox = AnalyticsOutbox(
      storage: storage,
      sink: _ControllableSink(),
      ioTimeout: const Duration(milliseconds: 10),
    );

    expect(await outbox.enqueue(_purchase('tx-1')), isFalse);
    storage.neverLoad = false;
    expect(await outbox.enqueue(_purchase('tx-1'), flush: false), isTrue);
  });

  test('용량 상한에서 미전송 기존 항목을 조용히 밀어내지 않고 신규 추가를 거부한다', () async {
    final outbox = AnalyticsOutbox(
      storage: _MemoryStorage(),
      sink: _ControllableSink()..deliver = false,
      maxPendingEntries: 1,
    );

    expect(await outbox.enqueue(_purchase('tx-1'), flush: false), isTrue);
    expect(await outbox.enqueue(_purchase('tx-2'), flush: false), isFalse);
    expect(await outbox.pendingCount(), 1);
  });

  test('sink 실패 항목은 retryDelay 안에는 재전송하지 않고, 시간이 지나면 재전송한다', () async {
    final storage = _MemoryStorage();
    final sink = _ControllableSink()..deliver = false;
    var now = DateTime.utc(2026, 8, 7, 12);
    final outbox = AnalyticsOutbox(
      storage: storage,
      sink: sink,
      retryDelay: const Duration(seconds: 30),
      clock: () => now,
    );

    await outbox.enqueue(_purchase('tx-retry'), flush: false);
    await outbox.flush();
    expect(sink.purchases, <String>['tx-retry']);

    // 실패 직후의 연쇄 flush 는 같은 항목을 즉시 다시 보내지 않는다.
    sink.deliver = true;
    now = now.add(const Duration(seconds: 29));
    await outbox.flush();
    expect(sink.purchases, <String>['tx-retry']);
    expect(await outbox.pendingCount(), 1);

    // retryDelay 를 넘긴 뒤의 flush 는 재전송한다.
    now = now.add(const Duration(seconds: 2));
    await outbox.flush();
    expect(sink.purchases, <String>['tx-retry', 'tx-retry']);
    expect(await outbox.pendingCount(), 0);
  });
}

class _SaveCountingStorage implements LocalStorage {
  _SaveCountingStorage(this.data, {required this.onSave});

  final Map<String, String> data;
  final void Function() onSave;

  @override
  Future<void> clearStorage() async => data.clear();

  @override
  Future<String?> loadData(String key, String? defaultValue) async =>
      data[key] ?? defaultValue;

  @override
  Future<void> removeData(String key) async => data.remove(key);

  @override
  Future<void> saveData(String key, String value) async {
    onSave();
    data[key] = value;
  }
}
