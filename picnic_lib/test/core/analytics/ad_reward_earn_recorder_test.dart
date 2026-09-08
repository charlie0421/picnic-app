import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/analytics/ad_reward_earn_recorder.dart';
import 'package:picnic_lib/core/analytics/analytics_send_markers.dart';
import 'package:picnic_lib/core/analytics/earn_analytics_store.dart';
import 'package:picnic_lib/data/models/ad/ad_reward_status.dart';
import 'package:picnic_lib/data/models/wallet/wallet_amount.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/free_charge_analytics.dart';

class _RecordedEarn {
  const _RecordedEarn({
    required this.reference,
    required this.virtualCurrencyName,
    required this.rewardAmount,
    required this.earnMethod,
    required this.sectionName,
    required this.adCategory,
  });

  final String reference;
  final String? virtualCurrencyName;
  final num? rewardAmount;
  final String? earnMethod;
  final String? sectionName;
  final String? adCategory;
}

class _SpyEarnStore implements EarnAnalyticsStore {
  final calls = <_RecordedEarn>[];
  bool stored = true;
  Object? failure;

  @override
  Future<bool> enqueueEarn({
    required String reference,
    required String? virtualCurrencyName,
    required num? rewardAmount,
    required String? earnMethod,
    required String? sectionName,
    required String? adCategory,
    Duration sendTimeout = const Duration(seconds: 5),
  }) async {
    calls.add(
      _RecordedEarn(
        reference: reference,
        virtualCurrencyName: virtualCurrencyName,
        rewardAmount: rewardAmount,
        earnMethod: earnMethod,
        sectionName: sectionName,
        adCategory: adCategory,
      ),
    );
    final error = failure;
    if (error != null) throw error;
    return stored;
  }

  @override
  Future<AnalyticsSendReservation?> reserve(String key) =>
      throw UnimplementedError();
}

const _reference = AdRewardReference(
  type: AdRewardReferenceType.internalImpression,
  id: '00000000-0000-4000-8000-000000000001',
);

WalletSummaryModel _wallet() => WalletSummaryModel(
  contractVersion: 'wallet.v1',
  star: BigInt.zero,
  bonus: BigInt.zero,
  cotton: BigInt.zero,
  cottonExpiringAmount: BigInt.zero,
  cottonNextExpiresAt: null,
  snapshotAt: DateTime.utc(2026),
);

AdRewardStatusModel _status(
  AdRewardState state, {
  AdRewardGrantModel? grant,
  AdRewardReference reference = _reference,
}) => AdRewardStatusModel(
  reference: reference,
  state: state,
  grant: grant,
  wallet: _wallet(),
  snapshotAt: DateTime.utc(2026),
);

AdRewardGrantModel _grant(BigInt amount, [WalletCurrency? currency]) =>
    AdRewardGrantModel(
      id: 'grant-1',
      currency: currency ?? WalletCurrency.cottonCandy,
      amount: amount,
      grantedAt: DateTime.utc(2026),
      expiresAt: DateTime.utc(2026, 2),
    );

void main() {
  late _SpyEarnStore store;

  setUp(() => store = _SpyEarnStore());

  test(
    'granted grant is stored with the confirmed amount and currency',
    () async {
      final recorded = await recordAdRewardEarn(
        status: _status(AdRewardState.granted, grant: _grant(BigInt.from(7))),
        store: store,
      );

      expect(recorded, isTrue);
      expect(store.calls, hasLength(1));
      final call = store.calls.single;
      expect(call.rewardAmount, 7);
      expect(
        call.virtualCurrencyName,
        FreeChargeGa4.currencyName(WalletCurrency.cottonCandy),
      );
      expect(call.earnMethod, FreeChargeGa4.earnMethodRewardedAd);
      expect(call.sectionName, FreeChargeGa4.sectionAds);
      expect(
        call.adCategory,
        FreeChargeGa4.adCategoryForReference(
          AdRewardReferenceType.internalImpression,
        ),
      );
    },
  );

  test(
    'reference key matches the internal shortform direct-display key',
    () async {
      await recordAdRewardEarn(
        status: _status(AdRewardState.granted, grant: _grant(BigInt.one)),
        store: store,
      );

      // 내부 숏폼 직접 표시 경로(enqueueLegacyShortformEarnAnalytics)가 쓰는
      // idempotency key 와 같은 문자열이어야 durable outbox 가 중복을 막는다.
      expect(
        store.calls.single.reference,
        'INTERNAL_IMPRESSION:00000000-0000-4000-8000-000000000001',
      );
    },
  );

  test('non-granted terminal states are never recorded as an earn', () async {
    for (final state in [
      AdRewardState.denied,
      AdRewardState.expired,
      AdRewardState.abandoned,
      AdRewardState.pending,
    ]) {
      final recorded = await recordAdRewardEarn(
        status: _status(state, grant: _grant(BigInt.from(5))),
        store: store,
      );
      expect(recorded, isFalse, reason: '$state 는 적립이 아니다');
    }
    expect(store.calls, isEmpty);
  });

  test('granted without a grant body is not recorded', () async {
    final recorded = await recordAdRewardEarn(
      status: _status(AdRewardState.granted),
      store: store,
    );

    expect(recorded, isFalse);
    expect(store.calls, isEmpty);
  });

  test('granted with a non-positive amount is not recorded', () async {
    final recorded = await recordAdRewardEarn(
      status: _status(AdRewardState.granted, grant: _grant(BigInt.zero)),
      store: store,
    );

    expect(recorded, isFalse);
    expect(store.calls, isEmpty);
  });

  test('a failed outbox write reports failure instead of throwing', () async {
    store.stored = false;

    final recorded = await recordAdRewardEarn(
      status: _status(AdRewardState.granted, grant: _grant(BigInt.one)),
      store: store,
    );

    expect(recorded, isFalse);
  });

  test('a throwing outbox write reports failure instead of throwing', () async {
    store.failure = StateError('outbox down');

    final recorded = await recordAdRewardEarn(
      status: _status(AdRewardState.granted, grant: _grant(BigInt.one)),
      store: store,
    );

    expect(recorded, isFalse);
  });
}
