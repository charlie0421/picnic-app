import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';
import 'package:picnic_lib/core/services/in_app_purchase_service.dart';
import 'package:picnic_lib/presentation/widgets/ui/loading_overlay_widgets.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/handlers/purchase_safety_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _RecordingInAppPurchasePlatform platform;

  setUpAll(() {
    // Create the package singleton without registering a native Android/iOS
    // implementation. Each test installs its recording platform below.
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    InAppPurchasePlatform.instance = _RecordingInAppPurchasePlatform();
    InAppPurchase.instance;
  });

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    platform = _RecordingInAppPurchasePlatform();
    InAppPurchasePlatform.instance = platform;
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  tearDownAll(() {
    debugDefaultTargetPlatformOverride = null;
  });

  group('Android pending store finalization guard', () {
    test('completePurchase never acknowledges a pending purchase', () async {
      final purchase = _purchase(PurchaseStatus.pending);

      await InAppPurchaseService().completePurchase(purchase);

      expect(platform.completed, isEmpty);
    });

    test(
      'finalizeSettledPurchase neither consumes nor acknowledges pending',
      () async {
        final purchase = _purchase(PurchaseStatus.pending);

        final finalized = await InAppPurchaseService().finalizeSettledPurchase(
          purchase,
        );

        expect(finalized, isFalse);
        expect(platform.completed, isEmpty);
      },
    );

    test('non-pending completion still reaches the platform', () async {
      final purchase = _purchase(PurchaseStatus.purchased);

      await InAppPurchaseService().completePurchase(purchase);

      expect(platform.completed, [same(purchase)]);
    });

    test('post-purchase safety cleanup also preserves pending', () async {
      final manager = PurchaseSafetyManager(
        loadingKey: GlobalKey<LoadingOverlayWithIconState>(),
        resetPurchaseState: () {},
      );
      addTearDown(manager.disposeSafetyTimer);
      manager.recordPurchaseAttempt(productId: 'first');
      manager.completePurchaseSession('first');
      manager.recordPurchaseAttempt(productId: 'STAR100');
      manager.completePurchaseSession('STAR100');

      await manager.performPostPurchaseCleanup(
        productId: 'STAR100',
        transactionId: 'pending-token',
        completedPurchase: _purchase(PurchaseStatus.pending),
      );

      expect(platform.completed, isEmpty);
    });
  });

  test('iOS pending completion behavior is unchanged', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final purchase = _purchase(PurchaseStatus.pending);

    await InAppPurchaseService().completePurchase(purchase);

    expect(platform.completed, [same(purchase)]);
  });
}

PurchaseDetails _purchase(PurchaseStatus status) {
  final purchase = PurchaseDetails(
    purchaseID: status == PurchaseStatus.pending ? '' : 'purchase-id',
    productID: 'STAR100',
    verificationData: PurchaseVerificationData(
      localVerificationData: 'local',
      serverVerificationData: 'purchase-token',
      source: 'test',
    ),
    transactionDate: '1785228000000',
    status: status,
  );
  purchase.pendingCompletePurchase = true;
  return purchase;
}

class _RecordingInAppPurchasePlatform extends InAppPurchasePlatform {
  final List<PurchaseDetails> completed = [];

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    completed.add(purchase);
  }
}
