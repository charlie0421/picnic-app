import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picnic_lib/core/services/purchase_service.dart';
import 'package:picnic_lib/data/models/promotion/promotion_campaign.dart';
import 'package:picnic_lib/data/models/purchase/purchase_settlement_result.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_campaign_attempt.dart';

import 'recording_receipt_dialogs.dart';

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
    'lowercase Play event binds to the uppercase catalog attempt',
    () {
      // Android: Supabase 카탈로그 ID는 STAR200, Play 이벤트 productID는 star200.
      final registry = PurchaseCampaignAttemptRegistry();
      registry.begin(attempt('a', 'STAR200'));
      expect(registry.contains('star200'), isTrue);
      registry.applyLaunchResult('STAR200', 'a', {
        'success': true,
        'wasCancelled': false,
      });

      final playEvent = transaction(
        'star200',
        'GPA.1234-5678',
        PurchaseStatus.purchased,
      );
      expect(registry.bind(playEvent)?.attemptId, 'a');
      expect(registry.finish(playEvent, 'a'), isTrue);
      expect(registry.contains('STAR200'), isFalse);
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
      final dialogs = RecordingReceiptDialogs();

      await deliverVerifiedPurchaseResult(verified, (serviceResult) {
        return const PurchaseSettlementPresentation().present(
          result: serviceResult,
          attempt: launchAttempt,
          isLate: false,
          dialogs: dialogs,
        );
      });

      expect(dialogs.plainReceipts, 1);
      expect(identical(dialogs.results.single, verified), isTrue);
      expect(identical(dialogs.campaigns.single, campaign), isTrue);
      expect(dialogs.campaigns.single!.campaignVersionId, 'version-at-launch');
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
        final dialogs = RecordingReceiptDialogs(
          whilePresenting: () => dialogCompleter.future,
        );

        final presentation = const PurchaseSettlementPresentation().present(
          result: verified,
          attempt: launchAttempt,
          isLate: isLate,
          dialogs: dialogs,
        );
        var completed = false;
        presentation.then((_) => completed = true);

        await Future<void>.delayed(Duration.zero);
        expect(completed, isFalse);
        expect(identical(dialogs.results.single, verified), isTrue);
        expect(dialogs.plainReceipts, isLate ? 0 : 1);
        expect(dialogs.lateReceipts, isLate ? 1 : 0);

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

  // ===========================================================================
  // Android Play Billing 에러/취소는 productID·purchaseID 없이 도착할 수 있다
  // (실기기 재현, 2026-08-05: responseCode 3, 결제창을 뒤로가기로 닫음).
  // 상품ID로 못 붙이면 orphan으로 폐기되는데, 그 경로엔 로딩 오버레이를 내리는
  // 코드가 없어 스피너가 영원히 남는다. 활성 시도가 정확히 하나뿐이면 그 시도로
  // 본다 - 둘 이상이면 여전히 판별할 수 없으므로 폐기한다.
  // ===========================================================================
  group('식별자 없는 에러/취소 이벤트', () {
    PurchaseDetails identityless(
      PurchaseStatus status, {
      String purchaseID = '',
    }) => PurchaseDetails(
      productID: '',
      purchaseID: purchaseID,
      transactionDate: null,
      status: status,
      verificationData: PurchaseVerificationData(
        localVerificationData: 'local',
        serverVerificationData: 'server',
        source: 'test',
      ),
    );

    test(
      'binds to the sole active launched attempt when the error carries no identity',
      () async {
        final registry = PurchaseCampaignAttemptRegistry();
        registry.begin(attempt('a', 'STAR100'));
        registry.applyLaunchResult('STAR100', 'a', {
          'success': true,
          'wasCancelled': false,
        });

        final bound = await registry.bindWithLaunchGrace(
          identityless(PurchaseStatus.error),
        );

        expect(bound?.attemptId, 'a');
      },
    );

    test(
      'binds a cancel with no identity the same way as an error',
      () async {
        final registry = PurchaseCampaignAttemptRegistry();
        registry.begin(attempt('a', 'STAR100'));
        registry.applyLaunchResult('STAR100', 'a', {
          'success': true,
          'wasCancelled': false,
        });

        final bound = await registry.bindWithLaunchGrace(
          identityless(PurchaseStatus.canceled),
        );

        expect(bound?.attemptId, 'a');
      },
    );

    test(
      'stays unresolved when two products are active and neither can be picked',
      () async {
        final registry = PurchaseCampaignAttemptRegistry();
        for (final entry in [('a', 'STAR100'), ('b', 'STAR500')]) {
          registry.begin(attempt(entry.$1, entry.$2));
          registry.applyLaunchResult(entry.$2, entry.$1, {
            'success': true,
            'wasCancelled': false,
          });
        }

        final bound = await registry.bindWithLaunchGrace(
          identityless(PurchaseStatus.error),
        );

        expect(bound, isNull);
      },
    );

    // Codex Frontier 리뷰 지적 (PR #137): A가 90초 안전망으로 제거된 뒤 B가
    // 시작되고, 그 후 A의 지연된 식별자 없는 이벤트가 도착하면 "유일한 활성
    // 시도" 규칙이 B에 잘못 결합한다 - B의 시도·로딩·안전망이 지워지고, B가
    // 나중에 실제로 성공하면 orphan 처리되어 캠페인 연결과 영수증 다이얼로그를
    // 잃는다. 최근(120초 내) 서로 다른 상품이 활동했다면 폴백을 거부해야 한다.
    test(
      'refuses the sole-active fallback when a different product was active recently',
      () async {
        var now = DateTime.utc(2026, 8, 5, 12, 0, 0);
        final registry = PurchaseCampaignAttemptRegistry(now: () => now);

        registry.begin(attempt('a', 'STAR100'));
        registry.applyLaunchResult('STAR100', 'a', {
          'success': true,
          'wasCancelled': false,
        });
        // A가 90초 안전망으로 제거된다.
        registry.removeIfMatches('STAR100', 'a');

        // 1초 뒤 완전히 다른 상품 B가 시작되고 즉시 launched 된다 - 지금 이
        // 레지스트리엔 B 하나뿐이다.
        now = now.add(const Duration(seconds: 1));
        registry.begin(attempt('b', 'STAR500'));
        registry.applyLaunchResult('STAR500', 'b', {
          'success': true,
          'wasCancelled': false,
        });

        // A의 지연된 취소가 뒤늦게 도착한다. B가 유일한 활성 시도라는 것만으로
        // 이 이벤트를 B에 결합해선 안 된다 - A(STAR100)가 최근에 있었다.
        final bound = await registry.bindWithLaunchGrace(
          identityless(PurchaseStatus.canceled),
        );

        expect(bound, isNull);
        expect(
          registry.contains('STAR500'),
          isTrue,
          reason: 'B의 시도는 이 모호한 이벤트로 지워지면 안 된다',
        );
      },
    );

    test(
      'still resolves the sole-active fallback when no other product has been active recently',
      () async {
        var now = DateTime.utc(2026, 8, 5, 12, 0, 0);
        final registry = PurchaseCampaignAttemptRegistry(now: () => now);

        registry.begin(attempt('a', 'STAR100'));
        registry.applyLaunchResult('STAR100', 'a', {
          'success': true,
          'wasCancelled': false,
        });
        now = now.add(const Duration(seconds: 1));

        final bound = await registry.bindWithLaunchGrace(
          identityless(PurchaseStatus.canceled),
        );

        expect(bound?.attemptId, 'a');
      },
    );

    test(
      'trusts the fallback again once the other product activity has aged out',
      () async {
        var now = DateTime.utc(2026, 8, 5, 12, 0, 0);
        final registry = PurchaseCampaignAttemptRegistry(now: () => now);

        registry.begin(attempt('a', 'STAR100'));
        registry.applyLaunchResult('STAR100', 'a', {
          'success': true,
          'wasCancelled': false,
        });
        registry.removeIfMatches('STAR100', 'a');

        // 3분(120초 관찰 창을 넘김) 뒤 B가 시작된다 - A의 활동은 더 이상
        // "최근"이 아니다.
        now = now.add(const Duration(minutes: 3));
        registry.begin(attempt('b', 'STAR500'));
        registry.applyLaunchResult('STAR500', 'b', {
          'success': true,
          'wasCancelled': false,
        });

        final bound = await registry.bindWithLaunchGrace(
          identityless(PurchaseStatus.canceled),
        );

        expect(bound?.attemptId, 'b');
      },
    );

    test(
      'stays unresolved when the sole context has not launched yet',
      () async {
        final registry = PurchaseCampaignAttemptRegistry();
        registry.begin(attempt('a', 'STAR100'));
        // applyLaunchResult 를 부르지 않았다 - launched 는 여전히 false.

        final bound = await registry.bindWithLaunchGrace(
          identityless(PurchaseStatus.error),
        );

        expect(bound, isNull);
      },
    );
  });

  // ===========================================================================
  // `purchased` 이벤트에만 적용되던 런치 유예(위 bindWithLaunchGrace 주석 참고,
  // iOS 실기기 2026-07-28)와 같은 클래스의 레이스가 error/canceled 에도
  // 이론적으로 적용된다: 스토어 스트림이 initiatePurchase()의 launched=true
  // 세팅보다 먼저 에러/취소를 전달하면, productID가 있어도 단 한 번의 bind
  // 시도만으로는 launched 게이트에 걸려 실패한다. 재시도가 없으면 이 레이스를
  // 이긴 이벤트는 orphan으로 영구 폐기되고 로딩 오버레이가 남는다.
  // ===========================================================================
  test(
    'an error event retries through the same launch race a purchased event already gets',
    () async {
      final registry = PurchaseCampaignAttemptRegistry();
      registry.begin(attempt('a', 'STAR100'));
      // launched 는 아직 false - 레이스 윈도우를 흉내낸다.
      Future<void>.delayed(const Duration(milliseconds: 150), () {
        registry.applyLaunchResult('STAR100', 'a', {
          'success': true,
          'wasCancelled': false,
        });
      });

      final errorEvent = PurchaseDetails(
        productID: 'STAR100',
        purchaseID: null,
        transactionDate: null,
        status: PurchaseStatus.error,
        verificationData: PurchaseVerificationData(
          localVerificationData: 'local',
          serverVerificationData: 'server',
          source: 'test',
        ),
      );

      final bound = await registry.bindWithLaunchGrace(
        errorEvent,
        retries: 5,
        delay: const Duration(milliseconds: 100),
      );

      expect(bound?.attemptId, 'a');
    },
  );
}
