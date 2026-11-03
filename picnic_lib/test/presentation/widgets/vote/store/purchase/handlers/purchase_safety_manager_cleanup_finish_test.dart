import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';
import 'package:picnic_lib/presentation/widgets/ui/loading_overlay_widgets.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/handlers/purchase_safety_manager.dart';

/// PICNIC-2743 C1: the post-purchase cleanup of the first purchase in a store
/// session must only ever touch the transaction that was just settled.
///
/// Until this test existed the iOS/Android cleanup read one `purchaseStream`
/// batch for ~1 s after settlement and finished every same-product
/// `purchased` event in it, without looking at the transaction id or at
/// whether the server had settled it. A transaction StoreKit or Play delivers
/// in that window (an Ask to Buy approval, a purchase on another device, a
/// refund update, a re-delivered unfinished purchase) carries a receipt the
/// server has not credited; finishing it deletes the only retry path for that
/// money. The host never reached the branch (`dart:io` `Platform.isIOS`), so
/// nothing pinned it.
///
/// The second behaviour pinned here: the pinned plugin's StoreKit 2 `finish`
/// never answers for a transaction that is missing from `Transaction.all`
/// (a consumable another path already finished). `finalizeSettledPurchase`
/// bounds that wait at 10 s; the cleanup's own finish must be bounded the
/// same way, or `settle()` never reaches the wallet write and the spinner
/// teardown.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _RecordingPlatform platform;

  setUpAll(() {
    // Create the InAppPurchase singleton while no real platform matches, so
    // the Android/StoreKit implementations are never registered on the host.
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    InAppPurchasePlatform.instance = _RecordingPlatform();
    InAppPurchase.instance;
  });

  setUp(() {
    platform = _RecordingPlatform();
    InAppPurchasePlatform.instance = platform;
  });

  tearDown(() => debugDefaultTargetPlatformOverride = null);

  /// A manager whose next cleanup is the "full" (first purchase of the
  /// session) variant - the only one that ran the platform cleanup.
  PurchaseSafetyManager firstPurchaseOfSession() {
    final manager = PurchaseSafetyManager(
      loadingKey: GlobalKey<LoadingOverlayWithIconState>(),
      resetPurchaseState: () {},
    );
    manager.recordPurchaseAttempt(productId: 'STAR100');
    manager.completePurchaseSession('STAR100');
    return manager;
  }

  PurchaseDetails purchased(String transactionId) {
    final details = PurchaseDetails(
      purchaseID: transactionId,
      productID: 'STAR100',
      verificationData: PurchaseVerificationData(
        localVerificationData: 'local',
        serverVerificationData: 'jws',
        source: 'test',
      ),
      transactionDate: '1785228000000',
      status: PurchaseStatus.purchased,
    );
    details.pendingCompletePurchase = true;
    return details;
  }

  for (final targetPlatform in [TargetPlatform.iOS, TargetPlatform.android]) {
    test('${targetPlatform.name}: a same-product transaction delivered during '
        'the cleanup window is left unfinished', () {
      debugDefaultTargetPlatformOverride = targetPlatform;

      fakeAsync((async) {
        final manager = firstPurchaseOfSession();
        var done = false;
        manager
            .performPostPurchaseCleanup(
              productId: 'STAR100',
              transactionId: 'tx-1',
              completedPurchase: purchased('tx-1'),
            )
            .then((_) => done = true);

        // Past the cleanup's settle-down wait, inside its stream window.
        async.elapse(const Duration(milliseconds: 400));
        platform.emit([purchased('tx-2')]);
        async.elapse(const Duration(seconds: 5));

        expect(done, isTrue);
        expect(
          platform.finished,
          ['tx-1'],
          reason:
              'tx-2 has no server settlement yet; finishing it would '
              'destroy the receipt the sweep needs to credit it later',
        );
      });
    });
  }

  test('a finish that never answers does not hold the settlement open', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    platform.answersFinish = false;

    fakeAsync((async) {
      final manager = firstPurchaseOfSession();
      var done = false;
      manager
          .performPostPurchaseCleanup(
            productId: 'STAR100',
            transactionId: 'tx-1',
            completedPurchase: purchased('tx-1'),
          )
          .then((_) => done = true);

      async.elapse(const Duration(seconds: 9));
      expect(done, isFalse, reason: 'a slow but live finish is still awaited');

      async.elapse(const Duration(seconds: 3));
      expect(
        done,
        isTrue,
        reason:
            'bounded by the same 10 s as finalizeSettledPurchase - the '
            'grant is already confirmed server-side, so the wallet write and '
            'the receipt must not wait on a finish that cannot answer',
      );
      expect(platform.finished, ['tx-1']);
    });
  });
}

class _RecordingPlatform extends InAppPurchasePlatform {
  final _controller = StreamController<List<PurchaseDetails>>.broadcast();
  final List<String> finished = [];
  bool answersFinish = true;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _controller.stream;

  void emit(List<PurchaseDetails> purchases) => _controller.add(purchases);

  @override
  Future<void> completePurchase(PurchaseDetails purchase) {
    finished.add(purchase.purchaseID!);
    return answersFinish ? Future<void>.value() : Completer<void>().future;
  }
}
