import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/ad/ad_reward_status.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';
import 'package:picnic_lib/data/repositories/ad_reward_repository.dart';
import 'package:picnic_lib/data/storage/local_storage.dart';
import 'package:picnic_lib/data/storage/pending_ad_reward_store.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/providers/ad_reward_provider.dart';
import 'package:picnic_lib/presentation/providers/ad_reward_recovery_provider.dart';
import 'package:picnic_lib/presentation/widgets/ad_reward_dialog_host.dart';

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
    repository.statusCompleter.complete(denied());
    await recovery;
    await tester.pumpWidget(app(container));
    expect(repository.acknowledged, isEmpty);
    await tester.pump();
    await tester.pump();
    expect(find.text('The reward was not granted'), findsOneWidget);
    expect(repository.acknowledged, [reference]);
    await tester.pump();
    expect(repository.acknowledged, [reference]);
  });
}
