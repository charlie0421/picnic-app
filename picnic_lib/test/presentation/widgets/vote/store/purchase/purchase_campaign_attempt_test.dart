import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picnic_lib/core/services/purchase_service.dart';
import 'package:picnic_lib/data/models/promotion/promotion_campaign.dart';
import 'package:picnic_lib/data/models/purchase/purchase_settlement_result.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_campaign_attempt.dart';

void main() {
  PurchaseCampaignAttempt attempt(String id, String product) =>
      PurchaseCampaignAttempt(
        attemptId: id,
        productId: product,
        displayedCampaign: null,
      );

  test('same product is locked while different product proceeds', () {
    final registry = PurchaseCampaignAttemptRegistry();
    expect(registry.begin(attempt('a', 'STAR100')), isTrue);
    expect(registry.begin(attempt('b', 'STAR100')), isFalse);
    expect(registry.begin(attempt('c', 'STAR500')), isTrue);
  });

  test('stale terminal callback cannot clear a newer identity', () {
    final registry = PurchaseCampaignAttemptRegistry();
    registry.begin(attempt('old', 'STAR100'));
    expect(registry.removeIfMatches('STAR100', 'old'), isTrue);
    registry.begin(attempt('new', 'STAR100'));
    expect(registry.removeIfMatches('STAR100', 'old'), isFalse);
    expect(registry['STAR100']!.attemptId, 'new');
  });

  test(
    'non-terminal path retains identity until matching terminal removal',
    () {
      final registry = PurchaseCampaignAttemptRegistry();
      registry.begin(attempt('pending', 'STAR100'));
      expect(registry['STAR100']!.attemptId, 'pending');
      expect(registry.removeIfMatches('STAR100', 'other'), isFalse);
      expect(registry.contains('STAR100'), isTrue);
      expect(registry.removeIfMatches('STAR100', 'pending'), isTrue);
    },
  );

  test('launch result removes cancel/failure but retains launched attempt', () {
    final registry = PurchaseCampaignAttemptRegistry();
    registry.begin(attempt('cancel', 'STAR100'));
    expect(
      registry.applyLaunchResult('STAR100', 'cancel', {
        'success': false,
        'wasCancelled': true,
      }),
      isTrue,
    );
    registry.begin(attempt('failure', 'STAR100'));
    expect(
      registry.applyLaunchResult('STAR100', 'failure', {
        'success': false,
        'wasCancelled': false,
      }),
      isTrue,
    );
    registry.begin(attempt('launched', 'STAR100'));
    expect(
      registry.applyLaunchResult('STAR100', 'launched', {
        'success': true,
        'wasCancelled': false,
      }),
      isFalse,
    );
    expect(registry['STAR100']!.attemptId, 'launched');
  });

  PurchaseDetails transaction(
    String product,
    String? transactionId,
    PurchaseStatus status,
  ) => PurchaseDetails(
    productID: product,
    purchaseID: transactionId,
    transactionDate: DateTime.utc(2027).millisecondsSinceEpoch.toString(),
    status: status,
    verificationData: PurchaseVerificationData(
      localVerificationData: 'local',
      serverVerificationData: 'server',
      source: 'test',
    ),
  );

  test(
    'real transaction events bind once and completed ids are tombstoned',
    () {
      final registry = PurchaseCampaignAttemptRegistry();
      registry.begin(attempt('a', 'STAR100'));
      registry.applyLaunchResult('STAR100', 'a', {
        'success': true,
        'wasCancelled': false,
      });

      final purchased = transaction(
        'STAR100',
        'txn-a',
        PurchaseStatus.purchased,
      );
      expect(registry.bind(purchased)?.attemptId, 'a');
      expect(registry.bind(purchased)?.attemptId, 'a');
      expect(registry.finish(purchased, 'a'), isTrue);

      registry.begin(attempt('b', 'STAR100'));
      registry.applyLaunchResult('STAR100', 'b', {
        'success': true,
        'wasCancelled': false,
      });
      expect(
        registry.bind(purchased),
        isNull,
        reason: 'late duplicate A must never bind to B',
      );
      expect(registry['STAR100']?.attemptId, 'b');
    },
  );

  test(
    'two products bind independently while restore and orphan are rejected',
    () {
      final registry = PurchaseCampaignAttemptRegistry();
      for (final entry in [('a', 'STAR100'), ('b', 'STAR500')]) {
        registry.begin(attempt(entry.$1, entry.$2));
        registry.applyLaunchResult(entry.$2, entry.$1, {
          'success': true,
          'wasCancelled': false,
        });
      }
      expect(
        registry
            .bind(transaction('STAR500', 'txn-500', PurchaseStatus.purchased))
            ?.attemptId,
        'b',
      );
      expect(
        registry
            .bind(transaction('STAR100', 'txn-100', PurchaseStatus.purchased))
            ?.attemptId,
        'a',
      );
      expect(
        registry.bind(
          transaction('STAR100', 'restore', PurchaseStatus.restored),
        ),
        isNull,
      );
      expect(
        registry.bind(
          transaction('ORPHAN', 'orphan', PurchaseStatus.purchased),
        ),
        isNull,
      );
      expect(
        registry.bind(transaction('STAR100', null, PurchaseStatus.purchased)),
        isNull,
      );
    },
  );

  test(
    'verified result reaches dialog with identity and launch campaign',
    () async {
      final campaign = ActivePromotionCampaignModel.fromJson({
        'campaign_id': 'campaign',
        'campaign_version_id': 'version-at-launch',
        'code': 'BOOST',
        'display_name': {'ko': '캔디 부스트'},
        'extra_bonus_bps': 10000,
        'window_starts_at': '2026-07-01T00:00:00Z',
        'window_ends_at': '2026-08-01T00:00:00Z',
        'show_in_store': true,
        'show_home_banner': false,
        'home_creative': null,
      });
      final launchAttempt = PurchaseCampaignAttempt(
        attemptId: 'attempt',
        productId: 'STAR100',
        displayedCampaign: campaign,
      );
      final verified = PurchaseSettlementResultModel(
        contractVersion: 'wallet.v1',
        operationId: 'operation',
        replayed: false,
        baseStarAmount: BigInt.from(100),
        baseBonusAmount: BigInt.zero,
        promotion: null,
        wallet: WalletSummaryModel(
          contractVersion: 'wallet.v1',
          star: BigInt.from(100),
          bonus: BigInt.zero,
          cotton: BigInt.zero,
          cottonExpiringAmount: BigInt.zero,
          cottonNextExpiresAt: null,
          snapshotAt: DateTime.utc(2026),
        ),
      );
      PurchaseSettlementResultModel? dialogResult;
      ActivePromotionCampaignModel? dialogCampaign;

      await deliverVerifiedPurchaseResult(verified, (serviceResult) {
        return const PurchaseSettlementPresentation().present(
          result: serviceResult,
          attempt: launchAttempt,
          isLate: false,
          showSuccess: (result, displayedCampaign) async {
            dialogResult = result;
            dialogCampaign = displayedCampaign;
          },
          showLateSuccess: (result, displayedCampaign) async {},
        );
      });

      expect(identical(dialogResult, verified), isTrue);
      expect(identical(dialogCampaign, campaign), isTrue);
      expect(dialogCampaign!.campaignVersionId, 'version-at-launch');
    },
  );

  for (final isLate in [false, true]) {
    test(
      '${isLate ? 'late' : 'normal'} settlement awaits and invokes exactly one presentation',
      () async {
        final verified = PurchaseSettlementResultModel(
          contractVersion: 'wallet.v1',
          operationId: 'operation-${isLate ? 'late' : 'normal'}',
          replayed: false,
          baseStarAmount: BigInt.from(100),
          baseBonusAmount: BigInt.zero,
          promotion: null,
          wallet: WalletSummaryModel(
            contractVersion: 'wallet.v1',
            star: BigInt.from(100),
            bonus: BigInt.zero,
            cotton: BigInt.zero,
            cottonExpiringAmount: BigInt.zero,
            cottonNextExpiresAt: null,
            snapshotAt: DateTime.utc(2026),
          ),
        );
        final launchAttempt = attempt('attempt', 'STAR100');
        final dialogCompleter = Completer<void>();
        var normalCalls = 0;
        var lateCalls = 0;

        final presentation = const PurchaseSettlementPresentation().present(
          result: verified,
          attempt: launchAttempt,
          isLate: isLate,
          showSuccess: (result, displayedCampaign) {
            expect(identical(result, verified), isTrue);
            normalCalls++;
            return dialogCompleter.future;
          },
          showLateSuccess: (result, displayedCampaign) {
            expect(identical(result, verified), isTrue);
            lateCalls++;
            return dialogCompleter.future;
          },
        );
        var completed = false;
        presentation.then((_) => completed = true);

        await Future<void>.delayed(Duration.zero);
        expect(completed, isFalse);
        expect(normalCalls, isLate ? 0 : 1);
        expect(lateCalls, isLate ? 1 : 0);

        dialogCompleter.complete();
        await presentation;
        expect(completed, isTrue);
      },
    );
  }

  test('unseen historical transaction cannot borrow a new launch campaign', () {
    final launchedAt = DateTime.utc(2026, 7, 23);
    final registry = PurchaseCampaignAttemptRegistry(now: () => launchedAt);
    registry.begin(attempt('new', 'STAR100'));
    registry.applyLaunchResult('STAR100', 'new', {
      'success': true,
      'wasCancelled': false,
    });
    final historical = PurchaseDetails(
      productID: 'STAR100',
      purchaseID: 'never-seen-old-id',
      transactionDate: launchedAt
          .subtract(const Duration(days: 1))
          .millisecondsSinceEpoch
          .toString(),
      status: PurchaseStatus.purchased,
      verificationData: PurchaseVerificationData(
        localVerificationData: 'local',
        serverVerificationData: 'server',
        source: 'test',
      ),
    );
    expect(registry.bind(historical), isNull);
    expect(registry['STAR100']?.attemptId, 'new');
    expect(PurchaseCampaignAttemptRegistry().bind(historical), isNull);
  });
}
