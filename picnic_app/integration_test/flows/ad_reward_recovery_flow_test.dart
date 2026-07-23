import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:picnic_lib/data/models/ad/ad_reward_status.dart';
import 'package:picnic_lib/data/repositories/ad_reward_repository.dart';
import 'package:picnic_lib/data/storage/local_storage.dart';
import 'package:picnic_lib/data/storage/pending_ad_reward_store.dart';
import 'package:picnic_lib/presentation/providers/ad_reward_provider.dart';
import 'package:picnic_lib/presentation/providers/ad_reward_recovery_provider.dart';

import '../fixtures/wallet_contract_fixtures.g.dart';

class MemoryLocalStorage implements LocalStorage {
  final values = <String, String>{};

  @override
  Future<void> saveData(String key, String value) async => values[key] = value;

  @override
  Future<String?> loadData(String key, String? defaultValue) async =>
      values[key] ?? defaultValue;

  @override
  Future<void> removeData(String key) async => values.remove(key);

  @override
  Future<void> clearStorage() async => values.clear();
}

class FakeAdRewardApi implements AdRewardApi {
  FakeAdRewardApi({required this.statuses});
  final Map<AdRewardReference, AdRewardStatusModel> statuses;
  int ackCount = 0;

  @override
  Future<AdRewardStatusModel> getStatus(AdRewardReference reference) async =>
      statuses[reference]!;

  @override
  Future<AdRewardPageModel> listUnacknowledged({
    String? cursor,
    int limit = 20,
  }) async =>
      AdRewardPageModel(
        items: statuses.values.toList(),
        totalCount: BigInt.from(statuses.length),
        nextCursor: null,
        snapshotAt: DateTime.utc(2026, 7, 21),
      );

  @override
  Future<void> acknowledge(AdRewardReference reference) async {
    ackCount += 1;
  }

  @override
  Future<PangleClaimModel> createPangleClaim({
    required String platform,
    required String placementId,
    required String clientRequestId,
  }) =>
      throw StateError('Claim creation is outside this recovery test');

  @override
  InternalShortformViewResponse parseInternalViewResponse(
    Map<String, dynamic> json,
  ) =>
      throw StateError('Shortform parsing is outside this recovery test');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('reward queue survives process restart until rendered ACK', (
    tester,
  ) async {
    final granted = AdRewardStatusModel.fromJson(
      Map<String, dynamic>.from(
        jsonDecode(
          walletContractFixtureJson['ad_reward_granted_v1.json']!,
        ) as Map,
      ),
    );
    final internalReference = granted.reference;
    const pangleReference = AdRewardReference(
      type: AdRewardReferenceType.pangleClaim,
      id: '00000000-0000-4000-8000-000000000403',
    );
    final pangleGranted = granted.copyWith(reference: pangleReference);
    final memory = MemoryLocalStorage();
    final pendingStore = PendingAdRewardStore(memory);
    await pendingStore.add('user-a', internalReference);
    final api = FakeAdRewardApi(
      statuses: {
        internalReference: granted,
        pangleReference: pangleGranted,
      },
    );

    ProviderContainer createContainer() => ProviderContainer(
          overrides: [
            adRewardRepositoryProvider.overrideWithValue(api),
            pendingAdRewardStoreProvider.overrideWithValue(pendingStore),
            adRewardDelayProvider.overrideWithValue((_) async {}),
            adRewardOwnerReaderProvider.overrideWithValue(() => 'user-a'),
          ],
        );

    final beforeAck = createContainer();
    await beforeAck.read(adRewardRecoveryProvider.notifier).recover('user-a');
    expect(beforeAck.read(adRewardRecoveryProvider).dialogQueue.length, 2);
    beforeAck.dispose();
    expect(api.ackCount, 0);

    final afterRestart = createContainer();
    await afterRestart
        .read(adRewardRecoveryProvider.notifier)
        .recover('user-a');
    final queue =
        afterRestart.read(adRewardRecoveryProvider).dialogQueue.toList();
    expect(queue.length, 2);
    for (final queued in queue) {
      expect(queued.ownerUserId, 'user-a');
      await afterRestart
          .read(adRewardRecoveryProvider.notifier)
          .acknowledgeAfterRender(queued);
    }
    expect(api.ackCount, 2);
    expect(await pendingStore.readAll('user-a'), isEmpty);
    afterRestart.dispose();
  });
}
