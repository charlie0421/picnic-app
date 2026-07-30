import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
    home: const AdRewardDialogHost(child: Scaffold(body: Text('home'))),
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
      child: const Scaffold(body: Text('home')),
    ),
  ),
);

void main() {
  testWidgets('checking indicator never acknowledges', (tester) async {
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
    expect(find.text('Checking your reward'), findsOneWidget);
    expect(repository.acknowledged, isEmpty);
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

    expect(find.text('Candy added!'), findsOneWidget);
    expect(find.text('Cotton Candy'), findsOneWidget);
    expect(find.text('+1'), findsOneWidget);
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
            'reward': repository.statuses[issuedReference]!.toJson(),
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

}

class _QueueRepository extends _Repository {
  final statuses = <AdRewardReference, AdRewardStatusModel>{};
  @override
  Future<AdRewardStatusModel> getStatus(AdRewardReference reference) async =>
      statuses[reference]!;
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
