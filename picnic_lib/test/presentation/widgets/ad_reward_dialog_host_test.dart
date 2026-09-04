import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/analytics/earn_analytics_store.dart';
import 'package:picnic_lib/core/analytics/ga4_sink.dart';
import 'package:picnic_lib/core/analytics/ga4_taxonomy.dart';
import 'package:picnic_lib/core/analytics/picnic_analytics.dart';
import 'package:picnic_lib/presentation/dialogs/candy_reward_receipt_dialog.dart';
import 'package:picnic_lib/data/models/ad/ad_reward_status.dart';
import 'package:picnic_lib/data/models/wallet/wallet_amount.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';
import 'package:picnic_lib/data/repositories/ad_reward_repository.dart';
import 'package:picnic_lib/data/storage/local_storage.dart';
import 'package:picnic_lib/data/storage/pending_ad_reward_store.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/providers/ad_reward_provider.dart';
import 'package:picnic_lib/presentation/providers/ad_reward_recovery_provider.dart';
import 'package:picnic_lib/presentation/providers/wallet_provider.dart';
import 'package:picnic_lib/presentation/widgets/ad_reward_dialog_host.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/platforms/internal_shortform_reward_flow.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/platforms/internal_shortform_reward_session.dart';

class _MemoryStorage implements LocalStorage {
  final values = <String, String>{};
  @override
  Future<String?> loadData(String key, String? fallback) async =>
      values[key] ?? fallback;
  @override
  Future<void> saveData(String key, String value) async => values[key] = value;
  @override
  Future<void> removeData(String key) async => values.remove(key);
  @override
  Future<void> clearStorage() async => values.clear();
}

class _Repository implements AdRewardApi {
  final statusCompleter = Completer<AdRewardStatusModel>();
  final acknowledged = <AdRewardReference>[];
  @override
  Future<void> acknowledge(AdRewardReference reference) async =>
      acknowledged.add(reference);
  @override
  Future<AdRewardStatusModel> getStatus(AdRewardReference reference) =>
      statusCompleter.future;
  @override
  Future<AdRewardPageModel> listUnacknowledged({
    String? cursor,
    int limit = 20,
  }) async => AdRewardPageModel(
    items: const [],
    totalCount: BigInt.zero,
    nextCursor: null,
    snapshotAt: DateTime.utc(2026),
  );
  @override
  Future<PangleClaimModel> createPangleClaim({
    required String platform,
    required String placementId,
    required String clientRequestId,
  }) => throw UnimplementedError();
  @override
  InternalShortformViewResponse parseInternalViewResponse(
    Map<String, dynamic> json,
  ) => InternalShortformViewResponse.fromJson(json);
}

const reference = AdRewardReference(
  type: AdRewardReferenceType.internalImpression,
  id: '00000000-0000-4000-8000-000000000001',
);

AdRewardStatusModel denied() => AdRewardStatusModel(
  reference: reference,
  state: AdRewardState.denied,
  grant: null,
  wallet: WalletSummaryModel(
    contractVersion: 'wallet.v1',
    star: BigInt.zero,
    bonus: BigInt.zero,
    cotton: BigInt.zero,
    cottonExpiringAmount: BigInt.zero,
    cottonNextExpiresAt: null,
    snapshotAt: DateTime.utc(2026),
  ),
  snapshotAt: DateTime.utc(2026),
);

AdRewardStatusModel pending() => AdRewardStatusModel(
  reference: reference,
  state: AdRewardState.pending,
  grant: null,
  wallet: WalletSummaryModel(
    contractVersion: 'wallet.v1',
    star: BigInt.zero,
    bonus: BigInt.zero,
    cotton: BigInt.zero,
    cottonExpiringAmount: BigInt.zero,
    cottonNextExpiresAt: null,
    snapshotAt: DateTime.utc(2026),
  ),
  snapshotAt: DateTime.utc(2026),
);

AdRewardStatusModel granted() => AdRewardStatusModel(
  reference: reference,
  state: AdRewardState.granted,
  grant: AdRewardGrantModel(
    id: 'grant-1',
    currency: WalletCurrency.cottonCandy,
    amount: BigInt.one,
    grantedAt: DateTime.utc(2026),
    expiresAt: DateTime.utc(2026, 2),
  ),
  wallet: WalletSummaryModel(
    contractVersion: 'wallet.v1',
    star: BigInt.zero,
    bonus: BigInt.zero,
    cotton: BigInt.one,
    cottonExpiringAmount: BigInt.one,
    cottonNextExpiresAt: DateTime.utc(2026, 2),
    snapshotAt: DateTime.utc(2026),
  ),
  snapshotAt: DateTime.utc(2026),
);

Widget app(ProviderContainer container) => UncontrolledProviderScope(
  container: container,
  child: MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    // earn 마커/outbox 저장소를 주입하지 않으면 host 가 전역 저장소에 I/O 를
    // 시작하고, 테스트 환경에서는 그 load 가 끝나지 않아 timeout Timer 가
    // pending 으로 남는다(earnApp 과 같은 격리 규칙).
    home: AdRewardDialogHost(
      earnAnalyticsStore: EarnAnalyticsStore(storage: _MemoryStorage()),
      child: const Scaffold(body: Text('home')),
    ),
  ),
);

Widget scheduledApp(
  ProviderContainer container,
  void Function(VoidCallback callback) schedule, {
  void Function(Object error, StackTrace stackTrace)? onAcknowledgeError,
}) => UncontrolledProviderScope(
  container: container,
  child: MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: AdRewardDialogHost(
      schedulePostFrame: schedule,
      onAcknowledgeError: onAcknowledgeError,
      earnAnalyticsStore: EarnAnalyticsStore(storage: _MemoryStorage()),
      child: const Scaffold(body: Text('home')),
    ),
  ),
);

void main() {
  testWidgets('post-ad checking indicator never acknowledges', (tester) async {
    final repository = _Repository();
    final store = PendingAdRewardStore(_MemoryStorage());
    final container = ProviderContainer(
      overrides: [
        adRewardRepositoryProvider.overrideWithValue(repository),
        pendingAdRewardStoreProvider.overrideWithValue(store),
        adRewardOwnerReaderProvider.overrideWithValue(() => 'user-a'),
        adRewardDelayProvider.overrideWithValue((_) async {}),
      ],
    );
    addTearDown(container.dispose);
    await store.add('user-a', reference);
    unawaited(
      container
          .read(adRewardRecoveryProvider.notifier)
          .poll(ownerUserId: 'user-a', reference: reference),
    );
    await tester.pumpWidget(app(container));
    await tester.pump();
    expect(find.text('Checking your reward'), findsOneWidget);
    expect(repository.acknowledged, isEmpty);
  });

  testWidgets('launch recovery never raises the checking indicator', (
    tester,
  ) async {
    // 앱 실행 시 "보상을 확인하고 있어요" 가 오래 남던 자리. 서버가 끝내
    // 해소하지 않는 레퍼런스는 로컬 레코드로 계속 남기 때문에, 스윕이
    // 배너를 띄우면 실행/포그라운드마다 같은 안내가 다시 붙는다.
    final repository = _Repository();
    final store = PendingAdRewardStore(_MemoryStorage());
    final container = ProviderContainer(
      overrides: [
        adRewardRepositoryProvider.overrideWithValue(repository),
        pendingAdRewardStoreProvider.overrideWithValue(store),
        adRewardOwnerReaderProvider.overrideWithValue(() => 'user-a'),
        adRewardDelayProvider.overrideWithValue((_) async {}),
      ],
    );
    addTearDown(container.dispose);
    await store.add('user-a', reference);
    unawaited(
      container.read(adRewardRecoveryProvider.notifier).recover('user-a'),
    );
    await tester.pumpWidget(app(container));
    await tester.pump();
    expect(find.text('Checking your reward'), findsNothing);
    expect(repository.acknowledged, isEmpty);
  });

  testWidgets('sweep still presents a reward granted after its first read', (
    tester,
  ) async {
    // 배너를 없앤다고 재조회까지 없애면, 재개 직후 확정된 보상이 같은 세션에서
    // 조용히 사라진다. 배너 없이도 사다리는 돌아야 한다.
    final repository = _FlippingRepository();
    final store = PendingAdRewardStore(_MemoryStorage());
    final container = ProviderContainer(
      overrides: [
        adRewardRepositoryProvider.overrideWithValue(repository),
        pendingAdRewardStoreProvider.overrideWithValue(store),
        adRewardOwnerReaderProvider.overrideWithValue(() => 'user-a'),
        adRewardDelayProvider.overrideWithValue((_) async {}),
      ],
    );
    addTearDown(container.dispose);
    await store.add('user-a', reference);

    await container.read(adRewardRecoveryProvider.notifier).recover('user-a');
    await tester.pumpWidget(app(container));
    await tester.pump();
    await tester.pump();

    expect(repository.reads, 2);
    expect(find.text('Checking your reward'), findsNothing);
    expect(find.text('Candy added!'), findsOneWidget);
    expect(repository.acknowledged, [reference]);
    await tester.pump();
    expect(await store.readAll('user-a'), isEmpty);
  });

  testWidgets('terminal dialog acknowledges once after its first frame', (
    tester,
  ) async {
    final repository = _Repository();
    final store = PendingAdRewardStore(_MemoryStorage());
    final container = ProviderContainer(
      overrides: [
        adRewardRepositoryProvider.overrideWithValue(repository),
        pendingAdRewardStoreProvider.overrideWithValue(store),
        adRewardOwnerReaderProvider.overrideWithValue(() => 'user-a'),
        adRewardDelayProvider.overrideWithValue((_) async {}),
      ],
    );
    addTearDown(container.dispose);
    await store.add('user-a', reference);
    final recovery = container
        .read(adRewardRecoveryProvider.notifier)
        .recover('user-a');
    repository.statusCompleter.complete(granted());
    await recovery;
    await tester.pumpWidget(app(container));
    expect(repository.acknowledged, isEmpty);
    await tester.pump();
    await tester.pump();
    // 지급된 보상은 영수증 다이얼로그로 보여 준다. 비지급 종결 상태는
    // 다이얼로그 없이 확인만 하고 큐에서 빠진다(아래 별도 케이스).
    expect(find.text('Candy added!'), findsOneWidget);
    expect(repository.acknowledged, [reference]);
    await tester.pump();
    expect(repository.acknowledged, [reference]);
  });

  testWidgets('granted reward renders receipt and acknowledges once', (
    tester,
  ) async {
    final repository = _Repository();
    final store = PendingAdRewardStore(_MemoryStorage());
    final container = ProviderContainer(
      overrides: [
        adRewardRepositoryProvider.overrideWithValue(repository),
        pendingAdRewardStoreProvider.overrideWithValue(store),
        adRewardOwnerReaderProvider.overrideWithValue(() => 'user-a'),
        adRewardDelayProvider.overrideWithValue((_) async {}),
        walletSummaryProvider.overrideWithBuild(
          (ref, notifier) => Completer<WalletSummaryModel>().future,
        ),
      ],
    );
    addTearDown(container.dispose);
    // 실제 파우치가 화면에서 구독 중인 상태를 재현한다. Host 는 보이지 않는
    // 지갑 provider를 팝업만으로 새로 만들지 않지만, 활성 파우치는 즉시 갱신한다.
    container.read(walletSummaryProvider);
    await store.add('user-a', reference);
    final recovery = container
        .read(adRewardRecoveryProvider.notifier)
        .recover('user-a');
    repository.statusCompleter.complete(granted());
    await recovery;
    await tester.pumpWidget(app(container));
    expect(repository.acknowledged, isEmpty);
    await tester.pump();
    await tester.pump();

    expect(find.text('Candy added!'), findsOneWidget);
    expect(find.text('Cotton Candy'), findsOneWidget);
    expect(find.text('+1'), findsOneWidget);
    expect(
      container.read(walletSummaryProvider).value,
      equals(granted().wallet),
      reason:
          'the pouch must use the same settled wallet snapshot as the reward '
          'receipt when the popup appears',
    );
    expect(repository.acknowledged, [reference]);
    await tester.pump();
    expect(repository.acknowledged, [reference]);
  });

  testWidgets('stale A schedule never resets B and only B renders or ACKs', (
    tester,
  ) async {
    var owner = 'user-a';
    final repository = _QueueRepository();
    final store = PendingAdRewardStore(_MemoryStorage());
    final scheduled = <VoidCallback>[];
    final container = ProviderContainer(
      overrides: [
        adRewardRepositoryProvider.overrideWithValue(repository),
        pendingAdRewardStoreProvider.overrideWithValue(store),
        adRewardOwnerReaderProvider.overrideWithValue(() => owner),
        adRewardDelayProvider.overrideWithValue((_) async {}),
      ],
    );
    addTearDown(container.dispose);
    final a = reference;
    const b = AdRewardReference(
      type: AdRewardReferenceType.internalImpression,
      id: '00000000-0000-4000-8000-000000000002',
    );
    repository.statuses[a] = granted();
    repository.statuses[b] = granted().copyWith(reference: b);
    await store.add('user-a', a);
    await container.read(adRewardRecoveryProvider.notifier).recover('user-a');
    await tester.pumpWidget(scheduledApp(container, scheduled.add));
    expect(scheduled, hasLength(1));

    owner = 'user-b';
    await store.add('user-b', b);
    await container.read(adRewardRecoveryProvider.notifier).recover('user-b');
    await tester.pump();
    expect(scheduled, hasLength(2));
    scheduled.first();
    await tester.pump();
    final bState = container.read(adRewardRecoveryProvider);
    expect(bState.activeUserId, 'user-b');
    expect(bState.dialogQueue.single.status.reference, b);
    expect(repository.acknowledged, isEmpty);
    expect(find.byType(CandyRewardReceiptDialog), findsNothing);

    scheduled.last();
    await tester.pump();
    await tester.pump();
    expect(find.byType(CandyRewardReceiptDialog), findsOneWidget);
    expect(repository.acknowledged, [b]);
  });

  testWidgets('removed terminal body does not ACK and repump ACKs once', (
    tester,
  ) async {
    final scheduled = <VoidCallback>[];
    var acknowledgements = 0;
    Widget body() => MaterialApp(
      localizationsDelegates: const [AppLocalizations.delegate],
      supportedLocales: AppLocalizations.supportedLocales,
      home: AdRewardDialogBody(
        status: granted(),
        schedulePostFrame: scheduled.add,
        onFirstFrame: () async => acknowledgements++,
      ),
    );

    await tester.pumpWidget(body());
    expect(scheduled, hasLength(1));
    await tester.pumpWidget(const SizedBox());
    scheduled.removeAt(0)();
    await tester.pump();
    expect(acknowledgements, 0);

    await tester.pumpWidget(body());
    expect(scheduled, hasLength(1));
    scheduled.single();
    await tester.pump();
    expect(acknowledgements, 1);
  });

  testWidgets('same-owner same-reference stale host callback is rejected', (
    tester,
  ) async {
    final repository = _QueueRepository()..statuses[reference] = granted();
    final store = PendingAdRewardStore(_MemoryStorage());
    final scheduled = <VoidCallback>[];
    final container = ProviderContainer(
      overrides: [
        adRewardRepositoryProvider.overrideWithValue(repository),
        pendingAdRewardStoreProvider.overrideWithValue(store),
        adRewardOwnerReaderProvider.overrideWithValue(() => 'user-a'),
        adRewardDelayProvider.overrideWithValue((_) async {}),
      ],
    );
    addTearDown(container.dispose);
    await store.add('user-a', reference);
    final notifier = container.read(adRewardRecoveryProvider.notifier);
    await notifier.recover('user-a');
    await tester.pumpWidget(scheduledApp(container, scheduled.add));
    expect(scheduled, hasLength(1));

    notifier.resetForLogout();
    await notifier.recover('user-a');
    await tester.pump();
    expect(scheduled, hasLength(2));
    scheduled.first();
    await tester.pump();
    expect(find.byType(CandyRewardReceiptDialog), findsNothing);
    expect(repository.acknowledged, isEmpty);

    scheduled.last();
    await tester.pump();
    await tester.pump();
    expect(find.byType(CandyRewardReceiptDialog), findsOneWidget);
    expect(repository.acknowledged, [reference]);
  });

  testWidgets(
    'current shortform reaches ACK and cleanup only through mounted host frame',
    (tester) async {
      const impressionId = '00000000-0000-4000-8000-000000000051';
      const issuedReference = AdRewardReference(
        type: AdRewardReferenceType.internalImpression,
        id: impressionId,
      );
      final repository = _QueueRepository();
      final store = PendingAdRewardStore(_MemoryStorage());
      final session = InternalShortformRewardSession();
      final scheduled = <VoidCallback>[];
      final container = ProviderContainer(
        overrides: [
          adRewardRepositoryProvider.overrideWithValue(repository),
          pendingAdRewardStoreProvider.overrideWithValue(store),
          adRewardOwnerReaderProvider.overrideWithValue(() => 'user-a'),
          adRewardDelayProvider.overrideWithValue((_) async {}),
        ],
      );
      addTearDown(container.dispose);
      final issue = await InternalShortformIssueFlow(
        currentOwner: () => 'user-a',
        invokeIssue: () async => {
          'impression_id': impressionId,
          'ad': {'video_url': 'ads/$impressionId.mp4', 'cta_url': null},
          'tokens': {'view_token': 'view', 'more_token': null},
        },
        persist: (owner, value) => session.bindIssued(
          owner: owner,
          issuedReference: value,
          persist: store.add,
        ),
        rewriteVideoUrl: (_) => 'https://cdn/$impressionId/master.m3u8',
      ).issue();
      expect(issue.videoUrl, isNotEmpty);
      expect((await store.readAll('user-a')).single.reference, issuedReference);
      repository.statuses[issuedReference] = granted().copyWith(
        reference: issuedReference,
      );
      late Future<void> pollCompletion;
      final response = await InternalShortformViewRecoveryFlow(
        view: InternalShortformViewFlow(
          session: session,
          currentOwner: () => 'user-a',
          invokeCallback: () async => {
            'ok': true,
            'reward_added': 0,
            'impression_id': impressionId,
            'new_bonus': null,
            'reward': pending().copyWith(reference: issuedReference).toJson(),
          },
          parse: InternalShortformViewResponse.fromJson,
        ),
        poll: (owner, value) => pollCompletion = container
            .read(adRewardRecoveryProvider.notifier)
            .poll(ownerUserId: owner, reference: value),
      ).report();
      expect(response.reward, isNotNull);
      await pollCompletion;
      final queued = container
          .read(adRewardRecoveryProvider)
          .dialogQueue
          .single;
      expect(queued.status.reference, issuedReference);
      expect(repository.acknowledged, isEmpty);
      await tester.pumpWidget(scheduledApp(container, scheduled.add));
      expect(scheduled, hasLength(1));
      scheduled.single();
      await tester.pump();
      expect(find.byType(CandyRewardReceiptDialog), findsOneWidget);
      await tester.pump();
      await tester.pump();
      expect(repository.acknowledged, [issuedReference]);
      expect(await store.readAll('user-a'), isEmpty);
    },
  );

  testWidgets(
    'owner change before the dialog first frame never escapes as an unhandled error',
    (tester) async {
      var owner = 'user-a';
      final repository = _QueueRepository()..statuses[reference] = granted();
      final store = PendingAdRewardStore(_MemoryStorage());
      final scheduled = <VoidCallback>[];
      final failures = <Object>[];
      final container = ProviderContainer(
        overrides: [
          adRewardRepositoryProvider.overrideWithValue(repository),
          pendingAdRewardStoreProvider.overrideWithValue(store),
          adRewardOwnerReaderProvider.overrideWithValue(() => owner),
          adRewardDelayProvider.overrideWithValue((_) async {}),
        ],
      );
      addTearDown(container.dispose);
      await store.add('user-a', reference);
      await container.read(adRewardRecoveryProvider.notifier).recover('user-a');
      await tester.pumpWidget(
        scheduledApp(
          container,
          scheduled.add,
          onAcknowledgeError: (error, _) => failures.add(error),
        ),
      );
      expect(scheduled, hasLength(1));

      scheduled.single();
      owner = 'user-b';
      await tester.pump();
      await tester.pump();

      expect(failures.single, isStateError);
      expect(find.byType(CandyRewardReceiptDialog), findsOneWidget);
      expect(repository.acknowledged, isEmpty);
      expect(
        (await store.readAll('user-a')).single.state,
        PendingAdRewardLocalState.pendingDisplay,
      );

      await tester.tap(find.text('Confirm').first);
      await tester.pumpAndSettle();
      expect(find.byType(CandyRewardReceiptDialog), findsNothing);
      if (scheduled.length > 1) {
        scheduled.last();
        await tester.pump();
        await tester.pump();
      }
      expect(find.byType(CandyRewardReceiptDialog), findsNothing);
    },
  );

  testWidgets(
    'failed first-frame tombstone drains the queue and stays recoverable',
    (tester) async {
      final repository = _QueueRepository()..statuses[reference] = granted();
      final store = _AckPendingFailingStore(_MemoryStorage());
      final scheduled = <VoidCallback>[];
      final failures = <Object>[];
      final container = ProviderContainer(
        overrides: [
          adRewardRepositoryProvider.overrideWithValue(repository),
          pendingAdRewardStoreProvider.overrideWithValue(store),
          adRewardOwnerReaderProvider.overrideWithValue(() => 'user-a'),
          adRewardDelayProvider.overrideWithValue((_) async {}),
        ],
      );
      addTearDown(container.dispose);
      await store.add('user-a', reference);
      final notifier = container.read(adRewardRecoveryProvider.notifier);
      await notifier.recover('user-a');
      await tester.pumpWidget(
        scheduledApp(
          container,
          scheduled.add,
          onAcknowledgeError: (error, _) => failures.add(error),
        ),
      );
      expect(scheduled, hasLength(1));

      scheduled.single();
      await tester.pump();
      await tester.pump();

      expect(failures.single, isFormatException);
      expect(find.byType(CandyRewardReceiptDialog), findsOneWidget);
      expect(repository.acknowledged, isEmpty);
      expect(
        (await store.readAll('user-a')).single.state,
        PendingAdRewardLocalState.pendingDisplay,
      );
      expect(container.read(adRewardRecoveryProvider).dialogQueue, isEmpty);

      await tester.tap(find.text('Confirm').first);
      await tester.pumpAndSettle();
      expect(find.byType(CandyRewardReceiptDialog), findsNothing);
      expect(scheduled, hasLength(1));

      await notifier.recover('user-a');
      await tester.pump();
      expect(scheduled, hasLength(2));
      scheduled.last();
      await tester.pump();
      await tester.pump();
      expect(find.byType(CandyRewardReceiptDialog), findsOneWidget);
      expect(repository.acknowledged, [reference]);
      expect(await store.readAll('user-a'), isEmpty);
      expect(failures, hasLength(1));
    },
  );

  testWidgets(
    '비지급 종결 상태는 다이얼로그 없이 확인만 하고 큐에서 빠진다',
    (tester) async {
      // 지갑 엔진 도입 전 광고 시청분이 ABANDONED 로 채워지면서, 실행 직후
      // "보상이 지급되지 않았어요 / ABANDONED" 모달이 여러 장 쌓였다.
      final repository = _QueueRepository()
        ..statuses[reference] = denied().copyWith(
          state: AdRewardState.abandoned,
        );
      final store = PendingAdRewardStore(_MemoryStorage());
      final scheduled = <VoidCallback>[];
      final container = ProviderContainer(
        overrides: [
          adRewardRepositoryProvider.overrideWithValue(repository),
          pendingAdRewardStoreProvider.overrideWithValue(store),
          adRewardOwnerReaderProvider.overrideWithValue(() => 'user-a'),
          adRewardDelayProvider.overrideWithValue((_) async {}),
        ],
      );
      addTearDown(container.dispose);
      await store.add('user-a', reference);
      final notifier = container.read(adRewardRecoveryProvider.notifier);
      await notifier.recover('user-a');

      await tester.pumpWidget(scheduledApp(container, scheduled.add));
      expect(scheduled, hasLength(1));
      scheduled.single();
      await tester.pumpAndSettle();

      // 사용자에게는 아무것도 뜨지 않는다.
      expect(find.byType(CandyRewardReceiptDialog), findsNothing);
      expect(find.text('The reward was not granted'), findsNothing);
      // 그러나 서버 확인은 남아서 다음 실행에 다시 폴링되지 않는다.
      expect(repository.acknowledged, contains(reference));
      expect(
        container.read(adRewardRecoveryProvider).dialogQueue,
        isEmpty,
      );
    },
  );

  group('earn_virtual_currency 중복 방어', () {
    late RecordingGa4Sink sink;
    late _MemoryStorage earnStorage;

    setUp(() {
      sink = RecordingGa4Sink();
      PicnicAnalytics.overrideInstance(PicnicAnalytics(sink: sink));
      earnStorage = _MemoryStorage();
      EarnAnalyticsStore.resetProcessCacheForTest();
    });

    tearDown(() {
      PicnicAnalytics.resetInstance();
      EarnAnalyticsStore.resetProcessCacheForTest();
    });

    int earnCount() =>
        sink.events.where((e) => e.name == Ga4Event.earnVirtualCurrency).length;

    /// 한 번의 앱 실행. 위젯 트리와 프로세스 메모리(예약·전송확인 캐시)가 매번
    /// 새로 생기고, 영속 저장소([earnStorage])만 실행 사이에 유지된다.
    Future<void> runSession(WidgetTester tester) async {
      // 앱 재시작 = 위젯 트리 전체 폐기. 같은 위젯 타입으로 바로 다시 pump 하면
      // Flutter 가 State 를 재사용한다.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      // 새 프로세스 = 빈 메모리. 영속 마커만 살아남는다.
      EarnAnalyticsStore.resetProcessCacheForTest();

      final repository = _QueueRepository()..statuses[reference] = granted();
      final store = PendingAdRewardStore(_MemoryStorage());
      final container = ProviderContainer(
        overrides: [
          adRewardRepositoryProvider.overrideWithValue(repository),
          pendingAdRewardStoreProvider.overrideWithValue(store),
          adRewardOwnerReaderProvider.overrideWithValue(() => 'user-a'),
          adRewardDelayProvider.overrideWithValue((_) async {}),
        ],
      );
      addTearDown(container.dispose);
      await store.add('user-a', reference);
      await container.read(adRewardRecoveryProvider.notifier).recover('user-a');

      await tester.pumpWidget(earnApp(container, earnStorage));
      await tester.pumpAndSettle();
      // 발송은 다이얼로그를 막지 않도록 unawaited 라, 예약 조회 → 전송 →
      // 마커 커밋으로 이어지는 microtask 체인이 끝날 틈을 준다.
      for (var i = 0; i < 6; i++) {
        await tester.pump(Duration.zero);
      }
    }

    testWidgets('한 번의 실행에서는 1회 발송된다', (tester) async {
      await runSession(tester);

      expect(earnCount(), 1);
    });

    testWidgets(
      'ACK 실패 후 재큐잉되는 다음 실행에서 다시 발송되지 않는다',
      (tester) async {
        // 위젯 메모리의 Set 은 프로세스마다 새로 생기므로, 영속 마커가 없으면
        // 같은 적립이 실행마다 한 번씩 더 집계된다.
        await runSession(tester);
        expect(earnCount(), 1);

        await runSession(tester);

        expect(earnCount(), 1);
      },
    );

    testWidgets('전송이 실패하면 마커가 남지 않고 다음 실행에서 다시 발송된다', (tester) async {
      // blocker 였던 경로: sink 가 Firebase 미초기화로 조용히 no-op 했는데
      // 마커는 발송 전에 이미 영속화돼 그 적립이 영구히 차단됐다.
      sink.deliver = false;
      await runSession(tester);
      expect(earnCount(), 1, reason: '시도는 했다');

      sink
        ..deliver = true
        ..clear();
      await runSession(tester);

      expect(earnCount(), 1, reason: '보내지 못한 적립은 다음 실행에서 다시 나가야 한다');
    });

    testWidgets('영속 마커가 비어 있는 다른 기기/계정은 정상 발송된다', (tester) async {
      await runSession(tester);
      expect(earnCount(), 1);

      // 새 기기 = 새 저장소.
      earnStorage = _MemoryStorage();
      await runSession(tester);

      expect(earnCount(), 2);
    });
  });
}

Widget earnApp(ProviderContainer container, LocalStorage earnStorage) =>
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: AdRewardDialogHost(
          earnAnalyticsStore: EarnAnalyticsStore(storage: earnStorage),
          child: const Scaffold(body: Text('home')),
        ),
      ),
    );

class _QueueRepository extends _Repository {
  final statuses = <AdRewardReference, AdRewardStatusModel>{};
  @override
  Future<AdRewardStatusModel> getStatus(AdRewardReference reference) async =>
      statuses[reference]!;
}

/// Serves PENDING once and the terminal state afterwards, so a sweep only sees
/// the reward if it reads the reference more than once.
class _FlippingRepository extends _Repository {
  int reads = 0;
  @override
  Future<AdRewardStatusModel> getStatus(AdRewardReference reference) async =>
      reads++ == 0 ? pending() : granted();
}

/// Mirrors a corrupt `pending_ad_rewards_v1` entry: the first tombstone write
/// rethrows the `FormatException` that `readAll` raises on bad JSON.
class _AckPendingFailingStore extends PendingAdRewardStore {
  _AckPendingFailingStore(super.storage);
  int failures = 1;

  @override
  Future<void> markAckPending(
    String userId,
    AdRewardReference reference,
  ) async {
    if (failures > 0) {
      failures--;
      throw const FormatException('Invalid pending ad rewards');
    }
    return super.markAckPending(userId, reference);
  }
}
