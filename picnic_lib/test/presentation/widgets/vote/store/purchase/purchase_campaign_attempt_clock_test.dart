import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_campaign_attempt.dart';

/// `bind()`가 이벤트의 transactionDate(스토어 서버 시계)를 launchedAt(기기
/// 시계)과 비교할 때의 시계 규칙.
///
/// iOS의 transactionDate는 Apple 서버 시계이거나 아예 null이라, 오차 허용
/// 없이 `transactionAt < launchedAt → 거부`로 판정하면 기기 시계가 조금만
/// 빨라도 방금 결제한 모든 iOS 구매가 orphan으로 폐기된다 — 실제로 전
/// iOS 구매가 무한 로딩 + verify 0회가 됐다 (2026-07-28). 허용 오차(10분)
/// 를 넘어서는 명백한 과거만 stale이고, null은 시간으로 판정하지 않는다.
void main() {
  final launchClock = DateTime.utc(2026, 7, 28, 12, 0, 0);

  PurchaseCampaignAttempt attempt(String id, String product) =>
      PurchaseCampaignAttempt(
        attemptId: id,
        productId: product,
        displayedCampaign: null,
      );

  PurchaseDetails event(
    String product, {
    String? transactionId = 'tx-1',
    DateTime? transactionAt,
    PurchaseStatus status = PurchaseStatus.purchased,
  }) => PurchaseDetails(
    productID: product,
    purchaseID: transactionId,
    transactionDate: transactionAt?.millisecondsSinceEpoch.toString(),
    status: status,
    verificationData: PurchaseVerificationData(
      localVerificationData: 'local',
      serverVerificationData: 'server',
      source: 'test',
    ),
  );

  PurchaseCampaignAttemptRegistry launchedRegistry() {
    final registry = PurchaseCampaignAttemptRegistry(now: () => launchClock);
    registry.begin(attempt('a', 'STAR100'));
    registry.applyLaunchResult('STAR100', 'a', {
      'success': true,
      'wasCancelled': false,
    });
    return registry;
  }

  test('event without a transactionDate binds to the launched attempt', () {
    final registry = launchedRegistry();
    expect(
      registry.bind(event('STAR100', transactionAt: null))?.attemptId,
      'a',
    );
  });

  test('event a few seconds before launch (clock skew) still binds', () {
    final registry = launchedRegistry();
    final skewed = launchClock.subtract(const Duration(seconds: 30));
    expect(
      registry.bind(event('STAR100', transactionAt: skewed))?.attemptId,
      'a',
    );
  });

  test('event clearly before launch (beyond tolerance) stays rejected', () {
    final registry = launchedRegistry();
    final historical = launchClock.subtract(const Duration(hours: 1));
    expect(registry.bind(event('STAR100', transactionAt: historical)), isNull);
  });

  test('purchased event arriving before the launch result still binds within '
      'the grace window', () async {
    // 재인증 직후의 Apple 샌드박스는 purchased 이벤트를 initiatePurchase의
    // 런치 결과보다 먼저 보낼 수 있다. 유예 없이는 launched 게이트에 걸려
    // orphan(다이얼로그 없는 정산)으로 빠진다 (iOS 실기기, 2026-07-28).
    final registry = PurchaseCampaignAttemptRegistry(now: () => launchClock);
    registry.begin(attempt('a', 'STAR100'));

    final binding = registry.bindWithLaunchGrace(
      event('STAR100', transactionAt: launchClock),
      delay: const Duration(milliseconds: 1),
    );
    await Future.delayed(const Duration(milliseconds: 5));
    registry.applyLaunchResult('STAR100', 'a', {
      'success': true,
      'wasCancelled': false,
    });

    expect((await binding)?.attemptId, 'a');
  });

  test('grace binding gives up once the attempt is gone (launch failed)', () async {
    final registry = PurchaseCampaignAttemptRegistry(now: () => launchClock);
    registry.begin(attempt('a', 'STAR100'));

    final binding = registry.bindWithLaunchGrace(
      event('STAR100', transactionAt: launchClock),
      delay: const Duration(milliseconds: 1),
    );
    await Future.delayed(const Duration(milliseconds: 5));
    registry.applyLaunchResult('STAR100', 'a', {
      'success': false,
      'wasCancelled': true,
    });

    expect(await binding, isNull);
  });

  test('terminal event without id or transactionDate matches the launched '
      'attempt', () {
    final registry = launchedRegistry();
    final canceled = event(
      'STAR100',
      transactionId: null,
      transactionAt: null,
      status: PurchaseStatus.canceled,
    );
    expect(registry.currentTerminalWithoutId(canceled)?.attemptId, 'a');
  });
}
