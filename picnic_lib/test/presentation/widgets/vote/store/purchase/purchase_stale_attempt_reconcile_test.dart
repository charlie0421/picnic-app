import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_campaign_attempt.dart';

/// 실기기 재현 (2026-08-07): 상품 A 의 구매창을 띄웠다가 취소하고 이어서
/// 상품 B 를 사면, A 의 버튼이 90초 안전망이 울릴 때까지 로딩 스피너로
/// 남는다.
///
/// 원인은 취소 이벤트가 아니라 정리 범위였다. iOS 는 취소/실패 트랜잭션에
/// transactionIdentifier 를 거의 붙이지 않고 Android Play Billing
/// responseCode 3 은 productID 까지 없으므로, 그런 이벤트는 어떤 시도에도
/// 귀속시킬 수 없어 레지스트리를 건드리지 못한다 (Codex Frontier 리뷰,
/// PR #137 - 깨면 안 되는 불변식). 대신 "스토어 큐를 다시 조회해 보니 애초에
/// 비어 있었다"는 실측으로만 정리하는 경로가 있었는데, 그 정리가 **사용자가
/// 방금 누른 그 상품**에만 걸려 있어서 A 는 아무도 쳐다보지 않았다.
///
/// 버튼 로딩 판정은 `_purchaseAttempts.contains(productId)` 하나뿐이므로,
/// 레지스트리에서 A 가 빠지는 것이 곧 A 의 스피너가 내려가는 것이다.
void main() {
  PurchaseCampaignAttempt attempt(String productId, String attemptId) =>
      PurchaseCampaignAttempt(
        attemptId: attemptId,
        productId: productId,
        displayedCampaign: null,
      );

  group('reconcileStaleAttemptsIfQueueEmpty', () {
    test(
      'clears a different product\'s stale attempt - the cancelled product '
      'must not keep spinning just because the user went on to buy another '
      'one',
      () async {
        final attempts = PurchaseCampaignAttemptRegistry();
        expect(attempts.begin(attempt('STAR100', 'a-1')), isTrue);

        // 사용자가 STAR200 을 누른 시점. 예전 구현은 STAR200 의 시도만
        // 찾아봤고 없으니 그대로 돌아가, STAR100 이 계속 남았다.
        final cleared = await reconcileStaleAttemptsIfQueueEmpty(
          attempts: attempts,
          verifyStoreQueueEmpty: () async => true,
        );

        expect(cleared.map((a) => a.productId), ['STAR100']);
        expect(
          attempts.contains('STAR100'),
          isFalse,
          reason: 'contains() is the button spinner - it has to go down',
        );
      },
    );

    test('clears every stale product in one verified sweep', () async {
      final attempts = PurchaseCampaignAttemptRegistry();
      attempts.begin(attempt('STAR100', 'a-1'));
      attempts.begin(attempt('STAR200', 'b-1'));

      var scans = 0;
      final cleared = await reconcileStaleAttemptsIfQueueEmpty(
        attempts: attempts,
        verifyStoreQueueEmpty: () async {
          scans++;
          return true;
        },
      );

      expect(cleared.length, 2);
      expect(attempts.isEmpty, isTrue);
      expect(scans, 1, reason: 'one store round trip, not one per product');
    });

    test(
      'keeps every attempt when the queue could not be verified empty - a '
      'sweep that just settled a real payment is not "nothing happened"',
      () async {
        final attempts = PurchaseCampaignAttemptRegistry();
        attempts.begin(attempt('STAR100', 'a-1'));

        final cleared = await reconcileStaleAttemptsIfQueueEmpty(
          attempts: attempts,
          // verifiedEmpty == false: 조회 실패, 남은 트랜잭션, 또는 방금
          // 정산한 실결제. 어느 쪽이든 지우면 안 된다.
          verifyStoreQueueEmpty: () async => false,
        );

        expect(cleared, isEmpty);
        expect(attempts.contains('STAR100'), isTrue);
      },
    );

    test(
      'never clears an attempt that started while the store scan was in '
      'flight - the snapshot is taken before the await',
      () async {
        final attempts = PurchaseCampaignAttemptRegistry();
        attempts.begin(attempt('STAR100', 'stale'));

        final scanStarted = Completer<void>();
        final releaseScan = Completer<void>();

        final pending = reconcileStaleAttemptsIfQueueEmpty(
          attempts: attempts,
          verifyStoreQueueEmpty: () async {
            scanStarted.complete();
            await releaseScan.future;
            return true;
          },
        );

        await scanStarted.future;
        // 조회가 도는 동안 사용자가 새 상품을 사기 시작했다.
        attempts.begin(attempt('STAR200', 'live'));
        releaseScan.complete();

        final cleared = await pending;

        expect(cleared.map((a) => a.productId), ['STAR100']);
        expect(
          attempts.contains('STAR200'),
          isTrue,
          reason: 'a purchase launched during the scan is not stale state',
        );
      },
    );

    test(
      'never clears a same-product retry that replaced the stale attempt '
      'mid-scan',
      () async {
        final attempts = PurchaseCampaignAttemptRegistry();
        attempts.begin(attempt('STAR100', 'stale'));

        final scanStarted = Completer<void>();
        final releaseScan = Completer<void>();

        final pending = reconcileStaleAttemptsIfQueueEmpty(
          attempts: attempts,
          verifyStoreQueueEmpty: () async {
            scanStarted.complete();
            await releaseScan.future;
            return true;
          },
        );

        await scanStarted.future;
        attempts.removeIfMatches('STAR100', 'stale');
        attempts.begin(attempt('STAR100', 'retry'));
        releaseScan.complete();

        expect(await pending, isEmpty);
        expect(
          attempts['STAR100']?.attemptId,
          'retry',
          reason: 'removeIfMatches must protect the newer attempt id',
        );
      },
    );

    test('does not touch the store when there is nothing to reconcile',
        () async {
      final attempts = PurchaseCampaignAttemptRegistry();
      var scans = 0;

      final cleared = await reconcileStaleAttemptsIfQueueEmpty(
        attempts: attempts,
        verifyStoreQueueEmpty: () async {
          scans++;
          return true;
        },
      );

      expect(cleared, isEmpty);
      expect(scans, 0);
    });

    test('clears nothing once the screen is gone', () async {
      final attempts = PurchaseCampaignAttemptRegistry();
      attempts.begin(attempt('STAR100', 'a-1'));

      final cleared = await reconcileStaleAttemptsIfQueueEmpty(
        attempts: attempts,
        verifyStoreQueueEmpty: () async => true,
        isStillLive: () => false,
      );

      expect(cleared, isEmpty);
      expect(attempts.contains('STAR100'), isTrue);
    });
  });

  group('PurchaseCampaignAttemptRegistry snapshot accessors', () {
    test('activeAttempts is a snapshot, safe to mutate the registry from',
        () async {
      final attempts = PurchaseCampaignAttemptRegistry();
      attempts.begin(attempt('STAR100', 'a-1'));
      attempts.begin(attempt('star200', 'b-1'));

      final snapshot = attempts.activeAttempts;
      for (final a in snapshot) {
        attempts.removeIfMatches(a.productId, a.attemptId);
      }

      expect(snapshot.length, 2);
      expect(attempts.isEmpty, isTrue);
    });
  });
}
