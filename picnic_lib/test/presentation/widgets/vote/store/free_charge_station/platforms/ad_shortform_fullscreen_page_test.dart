import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/platforms/ad_shortform_fullscreen_page.dart';
import 'package:picnic_lib/data/models/ad/ad_reward_status.dart';
import 'package:picnic_lib/data/models/wallet/candy_reward_receipt.dart';
import 'package:picnic_lib/data/models/wallet/wallet_amount.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';
import 'package:picnic_lib/data/repositories/wallet_repository.dart';
import 'package:picnic_lib/presentation/providers/wallet_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../../helpers/test_app.dart';

/// Coverage-focused tests for AdShortformFullscreenPage.
///
/// The widget depends on VideoPlayerController and SystemChrome for actual
/// video playback and immersive mode, which are not available in headless
/// widget tests. We test constructor parameters and basic initialization.
void main() {
  setUpAll(initTestEnvironment);

  group('AdShortformFullscreenPage constructor', () {
    test('accepts all parameters', () {
      final widget = AdShortformFullscreenPage(
        videoUrl: 'https://test.com/video.mp4',
        ctaUrl: 'https://test.com/cta',
        onViewComplete: legacyViewResponse,
        onMore: () async {},
        loadAd: () async => (
          videoUrl: 'https://test.com/ad.mp4',
          ctaUrl: 'https://cta.com',
          blocked: false,
        ),
      );

      expect(widget.videoUrl, 'https://test.com/video.mp4');
      expect(widget.ctaUrl, 'https://test.com/cta');
      expect(widget.onViewComplete, isNotNull);
      expect(widget.onMore, isNotNull);
      expect(widget.loadAd, isNotNull);
    });

    test('accepts minimal parameters', () {
      final widget = AdShortformFullscreenPage(
        videoUrl: 'https://test.com/video.mp4',
        onViewComplete: legacyViewResponse,
        onMore: () async {},
      );

      expect(widget.videoUrl, 'https://test.com/video.mp4');
      expect(widget.ctaUrl, isNull);
      expect(widget.loadAd, isNull);
    });

    test('ctaUrl defaults to null', () {
      final widget = AdShortformFullscreenPage(
        videoUrl: '',
        onViewComplete: legacyViewResponse,
        onMore: () async {},
      );
      expect(widget.ctaUrl, isNull);
    });

    test('loadAd defaults to null', () {
      final widget = AdShortformFullscreenPage(
        videoUrl: '',
        onViewComplete: legacyViewResponse,
        onMore: () async {},
      );
      expect(widget.loadAd, isNull);
    });

    test('accepts empty video URL', () {
      final widget = AdShortformFullscreenPage(
        videoUrl: '',
        onViewComplete: legacyViewResponse,
        onMore: () async {},
      );
      expect(widget.videoUrl, '');
    });

    test('with custom key', () {
      final widget = AdShortformFullscreenPage(
        key: const ValueKey('ad-page'),
        videoUrl: 'https://test.com/video.mp4',
        onViewComplete: legacyViewResponse,
        onMore: () async {},
      );
      expect(widget.key, const ValueKey('ad-page'));
    });
  });

  group('AdShortformFullscreenPage callback types', () {
    test('onViewComplete returns the typed reward response', () async {
      var called = false;
      final widget = AdShortformFullscreenPage(
        videoUrl: '',
        onViewComplete: () async {
          called = true;
          return legacyViewResponse();
        },
        onMore: () async {},
      );
      await widget.onViewComplete();
      expect(called, isTrue);
    });

    test('onMore is Future<void> Function()', () async {
      var called = false;
      final widget = AdShortformFullscreenPage(
        videoUrl: '',
        onViewComplete: legacyViewResponse,
        onMore: () async {
          called = true;
        },
      );
      await widget.onMore();
      expect(called, isTrue);
    });

    test('loadAd returns record with videoUrl and ctaUrl', () async {
      final widget = AdShortformFullscreenPage(
        videoUrl: '',
        onViewComplete: legacyViewResponse,
        onMore: () async {},
        loadAd: () async => (
          videoUrl: 'https://ad.com/v.mp4',
          ctaUrl: 'https://ad.com/cta',
          blocked: false,
        ),
      );

      final result = await widget.loadAd!();
      expect(result.videoUrl, 'https://ad.com/v.mp4');
      expect(result.ctaUrl, 'https://ad.com/cta');
    });

    test('loadAd can return null ctaUrl', () async {
      final widget = AdShortformFullscreenPage(
        videoUrl: '',
        onViewComplete: legacyViewResponse,
        onMore: () async {},
        loadAd: () async =>
            (videoUrl: 'https://ad.com/v.mp4', ctaUrl: null, blocked: false),
      );

      final result = await widget.loadAd!();
      expect(result.videoUrl, 'https://ad.com/v.mp4');
      expect(result.ctaUrl, isNull);
    });
  });

  group('reward presentation', () {
    test('granted wallet-aware response presents its receipt immediately', () {
      final reward = AdRewardStatusModel.fromJson(
        jsonDecode(
              File(
                'test/fixtures/wallet_contracts/ad_reward_granted_v1.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>,
      );
      final response = const InternalShortformViewResponse(
        ok: true,
        rewardAdded: 3,
        impressionId: '00000000-0000-4000-8000-000000000402',
        newBonus: null,
      ).copyWith(reward: reward);
      expect(
        AdShortformLogic.shouldPresentWalletRewardImmediately(response),
        isTrue,
      );
      expect(AdShortformLogic.shouldUseLegacyBonusUx(response), isFalse);
      expect(
        AdShortformLogic.walletSummaryToApply(response),
        same(reward.wallet),
      );
      expect(AdShortformLogic.shouldRefreshLegacyProfile(response), isFalse);
    });

    test('legacy positive reward presents the shared candy receipt', () async {
      // The success feedback reuses the purchase settlement's receipt dialog
      // (CandyRewardReceiptDialog) instead of the old "적립되었습니다 (N)"
      // toast that leaked the raw new_bonus value in parentheses.
      final response = await legacyViewResponse();
      expect(
        AdShortformLogic.shouldPresentWalletRewardImmediately(response),
        isFalse,
      );
      expect(AdShortformLogic.shouldUseLegacyBonusUx(response), isTrue);
      final receipt = receiptFromInternalShortformView(response)!;
      final item = receipt.items.single;
      expect(item.currency, WalletCurrency.bonusStarCandy);
      expect(item.grantedAmount, BigInt.one);
      expect(item.balanceAfter, BigInt.one);
    });
  });

  group('AdShortformLogic.applyRewardOutcome', () {
    test(
      'legacy response re-reads the wallet summary (pouch refresh)',
      () async {
        final repository = _FakeWalletRepository(
          summaries: [_walletSummary(bonus: 53), _walletSummary(bonus: 54)],
        );
        final container = ProviderContainer(
          overrides: [walletRepositoryProvider.overrideWithValue(repository)],
        );
        addTearDown(container.dispose);
        await container.read(walletSummaryProvider.future);
        expect(repository.summaryCalls, 1);

        await AdShortformLogic.applyRewardOutcome(
          container: container,
          response: await legacyViewResponse(),
        );

        // The legacy contract has no wallet snapshot, so the summary must be
        // re-read; refreshing the user profile alone leaves the pouch stale.
        expect(repository.summaryCalls, 2);
        expect(
          container.read(walletSummaryProvider).value!.bonus,
          BigInt.from(54),
        );
      },
    );

    test('wallet-aware response applies the settled snapshot as-is', () async {
      final repository = _FakeWalletRepository(
        summaries: [_walletSummary(bonus: 53)],
      );
      final container = ProviderContainer(
        overrides: [walletRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      await container.read(walletSummaryProvider.future);

      final settled = _walletSummary(
        bonus: 53,
        cotton: 10,
        snapshotAt: DateTime.utc(2026, 7, 25),
      );
      await AdShortformLogic.applyRewardOutcome(
        container: container,
        response: _walletAwareResponse(settled),
      );

      // The response already carries the settled balance; no re-read.
      expect(repository.summaryCalls, 1);
      expect(container.read(walletSummaryProvider).value, same(settled));
    });

    test('a failed legacy response leaves the wallet untouched', () async {
      final repository = _FakeWalletRepository(
        summaries: [_walletSummary(bonus: 53)],
      );
      final container = ProviderContainer(
        overrides: [walletRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      await container.read(walletSummaryProvider.future);

      await AdShortformLogic.applyRewardOutcome(
        container: container,
        response: const InternalShortformViewResponse(
          ok: false,
          rewardAdded: 0,
          impressionId: '00000000-0000-4000-8000-000000000402',
          newBonus: null,
        ),
      );

      expect(repository.summaryCalls, 1);
      expect(
        container.read(walletSummaryProvider).value!.bonus,
        BigInt.from(53),
      );
    });
  });
}

class _UnusedSupabaseClient extends Fake implements SupabaseClient {}

class _FakeWalletRepository extends WalletRepository {
  _FakeWalletRepository({required this.summaries})
    : super(_UnusedSupabaseClient());

  final List<WalletSummaryModel> summaries;
  int summaryCalls = 0;

  @override
  Future<WalletSummaryModel> getSummary() async => summaries[summaryCalls++];
}

WalletSummaryModel _walletSummary({
  required int bonus,
  int cotton = 0,
  DateTime? snapshotAt,
}) => WalletSummaryModel(
  contractVersion: 'wallet.v1',
  star: BigInt.zero,
  bonus: BigInt.from(bonus),
  cotton: BigInt.from(cotton),
  cottonExpiringAmount: BigInt.zero,
  cottonNextExpiresAt: null,
  snapshotAt: snapshotAt ?? DateTime.utc(2026, 7, 24),
);

InternalShortformViewResponse _walletAwareResponse(WalletSummaryModel wallet) =>
    InternalShortformViewResponse(
      ok: true,
      rewardAdded: 3,
      impressionId: '00000000-0000-4000-8000-000000000402',
      newBonus: null,
      reward: AdRewardStatusModel(
        reference: const AdRewardReference(
          type: AdRewardReferenceType.internalImpression,
          id: '00000000-0000-4000-8000-000000000402',
        ),
        state: AdRewardState.granted,
        grant: AdRewardGrantModel(
          id: 'grant-1',
          currency: WalletCurrency.cottonCandy,
          amount: BigInt.from(3),
          grantedAt: DateTime.utc(2026, 7, 25),
          expiresAt: DateTime.utc(2026, 8, 25),
        ),
        wallet: wallet,
        snapshotAt: wallet.snapshotAt,
      ),
    );

Future<InternalShortformViewResponse> legacyViewResponse() async =>
    const InternalShortformViewResponse(
      ok: true,
      rewardAdded: 1,
      impressionId: '00000000-0000-4000-8000-000000000402',
      newBonus: 1,
    );
