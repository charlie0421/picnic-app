import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mockito/mockito.dart';
import 'package:picnic_lib/core/services/in_app_purchase_service.dart';
import 'package:picnic_lib/core/services/purchase_service.dart';
import 'package:picnic_lib/core/services/receipt_verification_service.dart';
import 'package:picnic_lib/data/models/purchase/purchase_settlement_result.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/analytics_service.dart';
import 'package:picnic_lib/services/duplicate_prevention_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../helpers/mock_supabase.dart';

/// 미확정(unconfirmed) 구매의 트랜잭션 생명주기.
///
/// completePurchase/finalizeSettledPurchase는 영수증의 마지막 재시도 경로를
/// 끊는 행위다. 검증이 일시 실패한 구매에 호출되면 과금된 영수증이
/// 소멸하고(과금-미적립), 영구 거부된 구매에 호출되지 않으면 결코 성공할
/// 수 없는 영수증이 재전달 루프를 영원히 돈다. 분류기 숫자만이 아니라
/// 실제 finally 게이팅이 그 정책대로 움직이는지를 고정한다.
void main() {
  const productId = 'STAR100';
  const userId = 'user-1';

  late _CountingPlugin plugin;
  late _ThrowingVerification verification;
  late PurchaseService service;
  late ProviderContainer container;

  PurchaseDetails transaction() {
    final details = PurchaseDetails(
      purchaseID: 'tx-1',
      productID: productId,
      verificationData: PurchaseVerificationData(
        localVerificationData: 'local',
        serverVerificationData: 'server-receipt',
        source: 'test',
      ),
      transactionDate: '1785228000000',
      status: PurchaseStatus.purchased,
    );
    details.pendingCompletePurchase = true;
    return details;
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await setupMockSupabaseWithAuth(const {}, userId: userId);
  });

  tearDown(tearDownMockSupabase);

  Future<void> run(WidgetTester tester, Object failure) async {
    late WidgetRef capturedRef;
    await tester.pumpWidget(
      ProviderScope(
        child: Consumer(
          builder: (context, ref, _) {
            capturedRef = ref;
            container = ProviderScope.containerOf(context, listen: false);
            return const SizedBox();
          },
        ),
      ),
    );

    verification = _ThrowingVerification(failure);
    plugin = _CountingPlugin();
    service = PurchaseService(
      container: container,
      inAppPurchaseService: plugin,
      receiptVerificationService: verification,
      analyticsService: AnalyticsService(),
      duplicatePreventionService: DuplicatePreventionService(capturedRef),
      onPurchaseUpdate: (_) {},
    );
    await service.handleOptimizedPurchase(
      transaction(),
      (_) async {},
      (_) {},
      isActualPurchase: true,
    );
  }

  testWidgets('retryable failure keeps the transaction for redelivery',
      (tester) async {
    await run(
      tester,
      FunctionException(status: 503, details: null, reasonPhrase: 'test'),
    );
    expect(plugin.finalized, 0,
        reason: '일시 실패에 정리하면 과금된 영수증이 소멸한다');
    expect(plugin.completed, 0,
        reason: 'finish/consume 없이 남겨야 재전달/큐가 재시도할 수 있다');
  });

  testWidgets(
      'even a permanent rejection (422) never destroys the store transaction',
      (tester) async {
    await run(
      tester,
      FunctionException(status: 422, details: null, reasonPhrase: 'test'),
    );
    expect(plugin.finalized, 0,
        reason: '오판 시 과금 영수증이 소멸하고, Android는 미승인 구매의 '
            '3일 자동 환불 구제책까지 차단된다 - 422는 클라이언트 큐 '
            '재전송 중단에만 쓰인다');
    expect(plugin.completed, 0);
  });

  testWidgets('a duplicate whose grant is confirmed finalizes the transaction',
      (tester) async {
    await run(
      tester,
      ReusedPurchaseException(message: 'duplicate', grantConfirmed: true),
    );
    expect(plugin.finalized, 1,
        reason: '지급 확정 중복(멱등 캐시 히트 포함)은 finalize해야 정산 '
            '성공 후 finish만 실패한 트랜잭션이 림보에 갇히지 않는다');
  });

  testWidgets('a duplicate whose grant is unconfirmed keeps the transaction',
      (tester) async {
    await run(
      tester,
      ReusedPurchaseException(message: 'duplicate', grantConfirmed: false),
    );
    expect(plugin.finalized, 0);
    expect(plugin.completed, 0,
        reason: '지급 미확정 중복은 남겨야 큐/reconcile이 재시도한다');
  });
}

/// 검증이 지정된 실패를 던지거나 (ReusedPurchaseException은 실제 서비스와
/// 같은 경로로) 전달하는 스텁.
class _ThrowingVerification extends ReceiptVerificationService {
  _ThrowingVerification(this.failure);

  final Object failure;

  @override
  Future<String> getEnvironment() async => 'sandbox';

  @override
  Future<PurchaseSettlementResultModel> verifyReceipt(
    String receipt,
    String productId,
    String userId,
    String environment,
  ) async {
    throw failure;
  }
}

class _CountingPlugin extends Mock implements InAppPurchaseService {
  int completed = 0;
  int finalized = 0;

  @override
  void initialize(Function(List<PurchaseDetails>) onPurchaseUpdate) {}

  @override
  Future<void> clearPendingPurchasesOnStartup() async {}

  @override
  Future<void> completePurchase(PurchaseDetails purchaseDetails) async {
    completed++;
  }

  @override
  Future<void> finalizeSettledPurchase(PurchaseDetails purchaseDetails) async {
    finalized++;
  }
}
