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
  // (실기기 재현, 2026-08-05: responseCode 3, 결제창을 뒤로가기로 닫음). 시간
  // 경계를 증명할 방법이 전혀 없는 이벤트를 "유일한 활성 시도"에 자동으로
  // 묶는 발견적 규칙은 시도해 봤지만(2026-08-05, 120초 활동 창), Codex
  // Frontier 재검토에서 동일 상품 재시도와 창 만료 후 지연 도착 두 경로 모두
  // 뚫린다는 지적을 받고 폐기했다: 이미 안전망으로 정리된 시도의 지연
  // 이벤트가 방금 시작된 무관한(같은 상품이어도) 시도를 잘못 지워 로딩·
  // 안전망을 지우고 성공한 구매를 orphan으로 만들 수 있었다. 식별자 없는
  // 이벤트는 절대 어떤 시도에도 묶이지 않는다 - 로딩 오버레이 자체를 못
  // 내리는 문제는 호출자(`_processPurchaseDetail`)가 시도 상태를 건드리지
  // 않고 전역 로딩만 내리는 것으로 해결한다.
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
      'never binds an identity-less error to any attempt, even the sole active one',
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

        expect(bound, isNull);
        expect(
          registry.contains('STAR100'),
          isTrue,
          reason: '식별자 없는 이벤트가 유일한 활성 시도를 지워서는 안 된다',
        );
      },
    );

    test(
      'never binds an identity-less cancel either',
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

        expect(bound, isNull);
      },
    );

    // Codex Frontier 리뷰가 지적한 정확한 회귀 시나리오 (PR #137): A가 90초
    // 안전망으로 제거된 뒤 같은 상품으로 B가 새로 시작되고, 그 후 A의 지연된
    // 식별자 없는 이벤트가 도착한다. "유일한 활성 시도" 발견적 규칙은
    // 상품이 같으므로 이 경우를 절대 구분할 수 없었다 - 그래서 폐기했다.
    test(
      'a delayed identity-less event cannot cancel a fresh retry of the same product',
      () async {
        final registry = PurchaseCampaignAttemptRegistry();
        registry.begin(attempt('a', 'STAR100'));
        registry.applyLaunchResult('STAR100', 'a', {
          'success': true,
          'wasCancelled': false,
        });
        registry.removeIfMatches('STAR100', 'a'); // 90초 안전망으로 제거.

        registry.begin(attempt('b', 'STAR100')); // 즉시 재시도.
        registry.applyLaunchResult('STAR100', 'b', {
          'success': true,
          'wasCancelled': false,
        });

        final bound = await registry.bindWithLaunchGrace(
          identityless(PurchaseStatus.canceled),
        );

        expect(bound, isNull);
        expect(
          registry.contains('STAR100'),
          isTrue,
          reason: 'B의 재시도는 A의 지연 이벤트로 지워지면 안 된다',
        );
        expect(registry['STAR100']!.attemptId, 'b');
      },
    );

    // Codex Frontier 리뷰 3차 지적 (PR #137): productID는 있고 purchaseID만
    // 없는 종결 이벤트는 여전히 currentTerminalWithoutId()가 상품ID만으로
    // 활성 시도에 결합했다. productID는 거래 식별자가 아니므로, 위와 완전히
    // 같은 재시도 오결합 위험이 남는다 - A의 지연된 종결 이벤트(productID는
    // 있지만 purchaseID 없음)가 A의 안전망 종료 후 시작된 B(같은 상품)에
    // 도착하면 B가 잘못 지워진다.
    test(
      'a delayed event with a real productID but no purchaseID cannot cancel a '
      'fresh retry of the same product either', () async {
        final registry = PurchaseCampaignAttemptRegistry();
        registry.begin(attempt('a', 'STAR100'));
        registry.applyLaunchResult('STAR100', 'a', {
          'success': true,
          'wasCancelled': false,
        });
        registry.removeIfMatches('STAR100', 'a'); // 90초 안전망으로 제거.

        registry.begin(attempt('b', 'STAR100')); // 즉시 재시도.
        registry.applyLaunchResult('STAR100', 'b', {
          'success': true,
          'wasCancelled': false,
        });

        final staleEvent = PurchaseDetails(
          productID: 'STAR100',
          purchaseID: null,
          transactionDate: null,
          status: PurchaseStatus.canceled,
          verificationData: PurchaseVerificationData(
            localVerificationData: 'local',
            serverVerificationData: 'server',
            source: 'test',
          ),
        );

        final bound = await registry.bindWithLaunchGrace(staleEvent);

        expect(bound, isNull);
        expect(registry.contains('STAR100'), isTrue);
        expect(registry['STAR100']!.attemptId, 'b');
      },
    );

    test(
      'stays unresolved when two different products are active',
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
  });

  // ===========================================================================
  // `purchased` 이벤트에만 적용되던 런치 유예(위 bindWithLaunchGrace 주석 참고,
  // iOS 실기기 2026-07-28)와 같은 클래스의 레이스가 error/canceled 에도
  // 적용된다: 스토어 스트림이 initiatePurchase()의 launched=true 세팅보다
  // 먼저 에러/취소를 전달하면, 거래ID(purchaseID)가 있어도 단 한 번의 bind
  // 시도만으로는 launched 게이트에 걸려 실패한다. 재시도가 없으면 이 레이스를
  // 이긴 이벤트는 orphan으로 영구 폐기되고 로딩 오버레이가 남는다. (거래ID가
  // 없는 error/canceled 이벤트는 재시도해도 절대 bind되지 않으므로 이 테스트
  // 대상이 아니다 - 위 '식별자 없는 에러/취소 이벤트' 그룹 참고.)
  // ===========================================================================
  test(
    'an error event with a real transaction id retries through the same '
    'launch race a purchased event already gets', () async {
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
        purchaseID: 'txn-error-1',
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
