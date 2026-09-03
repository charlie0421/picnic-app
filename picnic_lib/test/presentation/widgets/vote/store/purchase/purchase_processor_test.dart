import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mockito/mockito.dart';
import 'package:picnic_lib/core/constants/purchase_constants.dart';
import 'package:picnic_lib/core/services/in_app_purchase_service.dart';
import 'package:picnic_lib/presentation/widgets/ui/loading_overlay_widgets.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/handlers/purchase_safety_manager.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_campaign_attempt.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_processor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PurchaseProcessor.completeFailedTransaction pending guard', () {
    late _RecordingPurchaseService service;

    setUp(() {
      service = _RecordingPurchaseService();
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
    });

    test(
      'Android pending is never completed through the failure path',
      () async {
        final purchase = _pendingPurchase();

        await PurchaseProcessor.completeFailedTransaction(
          purchaseDetails: purchase,
          inAppPurchaseService: service,
        );

        expect(service.completed, isEmpty);
      },
    );

    test('iOS behavior remains unchanged', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final purchase = _pendingPurchase();

      await PurchaseProcessor.completeFailedTransaction(
        purchaseDetails: purchase,
        inAppPurchaseService: service,
      );

      expect(service.completed, [same(purchase)]);
    });
  });

  group('PurchaseProcessor.releaseAndroidPendingSurfaceAttempt', () {
    late PurchaseSafetyManager safetyManager;
    late PurchaseCampaignAttemptRegistry attempts;

    setUp(() {
      safetyManager = PurchaseSafetyManager(
        loadingKey: GlobalKey<LoadingOverlayWithIconState>(),
        resetPurchaseState: () {},
      );
      attempts = PurchaseCampaignAttemptRegistry();
      addTearDown(safetyManager.disposeSafetyTimer);
    });

    test(
      'releases the attempt, announces once, and leaves purchased orphan',
      () {
        const attempt = PurchaseCampaignAttempt(
          attemptId: 'attempt-1',
          productId: 'STAR100',
          displayedCampaign: null,
        );
        expect(attempts.begin(attempt), isTrue);
        attempts.applyLaunchResult('STAR100', 'attempt-1', const {
          'success': true,
          'wasCancelled': false,
        });

        final first = PurchaseProcessor.releaseAndroidPendingSurfaceAttempt(
          productId: 'star100',
          attempts: attempts,
          safetyManager: safetyManager,
        );

        expect(first.attemptReleased, isTrue);
        expect(first.shouldAnnounce, isTrue);
        expect(attempts.contains('STAR100'), isFalse);
        expect(safetyManager.isSettlementPending('STAR100'), isTrue);

        final duplicate = PurchaseProcessor.releaseAndroidPendingSurfaceAttempt(
          productId: 'STAR100',
          attempts: attempts,
          safetyManager: safetyManager,
        );
        expect(duplicate.attemptReleased, isFalse);
        expect(duplicate.shouldAnnounce, isFalse);

        expect(attempts.bind(_purchasedPurchase()), isNull);
      },
    );
  });

  /// The guarantee `PurchaseSettlementStep` settles against.
  ///
  /// `cleanupAllTimersOnSuccess` tears down three independent timer owners -
  /// `PurchaseSafetyManager`, `RestorePurchaseHandler` and
  /// `InAppPurchaseService` - after the charge has gone through but before the
  /// wallet is credited and the receipt is shown. The step takes it as a plain
  /// `void` seam and has no catch of its own, so anything escaping this cleanup
  /// would abort a settlement whose money has already moved.
  ///
  /// Driving the three real collaborators would mean constructing a live
  /// `PurchaseService` (StoreKit/Play init, receipt queue, Supabase), so the
  /// guard itself is what is pinned here.
  group('PurchaseProcessor.runTimerCleanupGuarded', () {
    test('swallows a throwing timer owner', () {
      expect(
        () => PurchaseProcessor.runTimerCleanupGuarded(
          () => throw StateError('timer owner already disposed'),
        ),
        returnsNormally,
      );
    });

    test('runs the cleanup it is given', () {
      var ran = 0;
      PurchaseProcessor.runTimerCleanupGuarded(() => ran++);
      expect(ran, 1);
    });
  });

  group('PurchaseProcessor.classifyError', () {
    test('returns showPendingMessage for errPrevTransactionPending', () {
      expect(
        PurchaseProcessor.classifyError(
          PurchaseConstants.errPrevTransactionPending,
        ),
        PurchaseErrorAction.showPendingMessage,
      );
    });

    test('returns showCooldownMessage for errCooldownActive', () {
      expect(
        PurchaseProcessor.classifyError(PurchaseConstants.errCooldownActive),
        PurchaseErrorAction.showCooldownMessage,
      );
    });

    group('returns duplicateWithCooldown for duplicate error strings', () {
      test('containing "StoreKit 캐시 문제"', () {
        expect(
          PurchaseProcessor.classifyError('StoreKit 캐시 문제가 발생했습니다'),
          PurchaseErrorAction.duplicateWithCooldown,
        );
      });

      test('containing "중복 영수증"', () {
        expect(
          PurchaseProcessor.classifyError('중복 영수증 감지됨'),
          PurchaseErrorAction.duplicateWithCooldown,
        );
      });

      test('containing "이미 처리된 구매"', () {
        expect(
          PurchaseProcessor.classifyError('이미 처리된 구매입니다'),
          PurchaseErrorAction.duplicateWithCooldown,
        );
      });

      test('containing "Duplicate"', () {
        expect(
          PurchaseProcessor.classifyError('Duplicate transaction detected'),
          PurchaseErrorAction.duplicateWithCooldown,
        );
      });

      test('containing "reused" (case-insensitive)', () {
        expect(
          PurchaseProcessor.classifyError('Receipt was reused'),
          PurchaseErrorAction.duplicateWithCooldown,
        );
      });

      test('containing "Reused" (uppercase)', () {
        expect(
          PurchaseProcessor.classifyError('Reused receipt'),
          PurchaseErrorAction.duplicateWithCooldown,
        );
      });
    });

    test('returns showMappedError for unknown error strings', () {
      expect(
        PurchaseProcessor.classifyError('SOME_UNKNOWN_ERROR'),
        PurchaseErrorAction.showMappedError,
      );
    });

    test('returns showMappedError for empty string', () {
      expect(
        PurchaseProcessor.classifyError(''),
        PurchaseErrorAction.showMappedError,
      );
    });
  });

  /// C-1: "결제는 접수됐지만 정산 결과를 아직 모른다" 를 종결 실패와 구분한다.
  ///
  /// 클라이언트 예산은 30초 타임아웃 + 2·4초 백오프인데 서버 워커의 리스는
  /// 60초이고 실패한 오퍼레이션은 cron 재시도를 탄다. 그래서 이 구분이
  /// 없으면 **정산이 진행 중인 결제**가 종결 실패로 안내되고, 사용자는 그
  /// 안내를 따라 같은 소비형 상품을 한 번 더 결제한다.
  group('PurchaseProcessor 정산 미확정 분류', () {
    test('PROCESSING 은 processing 타입으로 매핑된다', () {
      expect(
        PurchaseProcessor.mapErrorToType(PurchaseConstants.errProcessing),
        PurchaseErrorType.processing,
      );
    });

    test('processing 은 종결 실패가 아니다', () {
      expect(
        PurchaseProcessor.isTerminalMappedError(PurchaseErrorType.processing),
        isFalse,
        reason:
            '종결로 다루면 어템프트와 안전망이 함께 철거되고, 사용자는 '
            '적립 직전의 결제를 실패로 안내받는다',
      );
    });

    test('processing 과 timeout 만 "접수됨" 안내를 받는다', () {
      final pending = PurchaseErrorType.values
          .where(PurchaseProcessor.isSettlementPending)
          .toSet();
      expect(pending, {
        PurchaseErrorType.processing,
        PurchaseErrorType.timeout,
      });
    });

    test('networkError 는 접수 안내 대상이 아니다', () {
      // 런치 단계(아직 과금 없음)에서도 나오는 코드라 "네트워크를
      // 확인하세요"가 맞다. 정산 단계의 소켓/타임아웃 실패는 타입 분류에서
      // processing 으로 들어온다.
      expect(
        PurchaseProcessor.isSettlementPending(PurchaseErrorType.networkError),
        isFalse,
      );
    });

    test('종결 실패는 접수 안내를 절대 받지 않는다', () {
      for (final type in [
        PurchaseErrorType.receiptVerificationFailed,
        PurchaseErrorType.userNotAuthenticated,
        PurchaseErrorType.productNotFound,
        PurchaseErrorType.purchaseFailed,
        PurchaseErrorType.serverError,
        PurchaseErrorType.purchaseCancelled,
      ]) {
        expect(
          PurchaseProcessor.isSettlementPending(type),
          isFalse,
          reason: '$type',
        );
        expect(
          PurchaseProcessor.isTerminalMappedError(type),
          isTrue,
          reason: '$type - 종결 실패의 기존 동작은 그대로여야 한다',
        );
      }
    });

    test('ERR_PAYMENT_INVALID 는 종결 실패로 매핑된다', () {
      expect(
        PurchaseProcessor.mapErrorToType(PurchaseConstants.errPaymentInvalid),
        PurchaseErrorType.purchaseFailed,
      );
    });
  });

  group('PurchaseProcessor.mapErrorToType', () {
    group('returns previousTransactionPending for pending/duplicate codes', () {
      test('errPrevTransactionPending', () {
        expect(
          PurchaseProcessor.mapErrorToType(
            PurchaseConstants.errPrevTransactionPending,
          ),
          PurchaseErrorType.previousTransactionPending,
        );
      });

      test('errCooldownActive', () {
        expect(
          PurchaseProcessor.mapErrorToType(PurchaseConstants.errCooldownActive),
          PurchaseErrorType.previousTransactionPending,
        );
      });

      test('errTooSoon', () {
        expect(
          PurchaseProcessor.mapErrorToType(PurchaseConstants.errTooSoon),
          PurchaseErrorType.previousTransactionPending,
        );
      });

      test('errRecentPurchase', () {
        expect(
          PurchaseProcessor.mapErrorToType(PurchaseConstants.errRecentPurchase),
          PurchaseErrorType.previousTransactionPending,
        );
      });

      test('errRequestDuplicate', () {
        expect(
          PurchaseProcessor.mapErrorToType(
            PurchaseConstants.errRequestDuplicate,
          ),
          PurchaseErrorType.previousTransactionPending,
        );
      });
    });

    test(
      'returns receiptVerificationFailed for RECEIPT_VERIFICATION_FAILED',
      () {
        expect(
          PurchaseProcessor.mapErrorToType('RECEIPT_VERIFICATION_FAILED'),
          PurchaseErrorType.receiptVerificationFailed,
        );
      },
    );

    test('returns userNotAuthenticated for USER_NOT_AUTHENTICATED', () {
      expect(
        PurchaseProcessor.mapErrorToType('USER_NOT_AUTHENTICATED'),
        PurchaseErrorType.userNotAuthenticated,
      );
    });

    test('returns productNotFound for PRODUCT_NOT_FOUND', () {
      expect(
        PurchaseProcessor.mapErrorToType('PRODUCT_NOT_FOUND'),
        PurchaseErrorType.productNotFound,
      );
    });

    test('returns timeout for errTimeout', () {
      expect(
        PurchaseProcessor.mapErrorToType(PurchaseConstants.errTimeout),
        PurchaseErrorType.timeout,
      );
    });

    test('returns purchaseFailed for errAuthTimeout', () {
      expect(
        PurchaseProcessor.mapErrorToType(PurchaseConstants.errAuthTimeout),
        PurchaseErrorType.purchaseFailed,
      );
    });

    test('returns networkError for errNetwork', () {
      expect(
        PurchaseProcessor.mapErrorToType(PurchaseConstants.errNetwork),
        PurchaseErrorType.networkError,
      );
    });

    test('returns serverError for errServer', () {
      expect(
        PurchaseProcessor.mapErrorToType(PurchaseConstants.errServer),
        PurchaseErrorType.serverError,
      );
    });

    test('returns purchaseCancelled for errPurchaseCanceled', () {
      expect(
        PurchaseProcessor.mapErrorToType(PurchaseConstants.errPurchaseCanceled),
        PurchaseErrorType.purchaseCancelled,
      );
    });

    group('returns purchaseInProgress for in-progress codes', () {
      test('errInProgress', () {
        expect(
          PurchaseProcessor.mapErrorToType(PurchaseConstants.errInProgress),
          PurchaseErrorType.purchaseInProgress,
        );
      });

      test('errConcurrent', () {
        expect(
          PurchaseProcessor.mapErrorToType(PurchaseConstants.errConcurrent),
          PurchaseErrorType.purchaseInProgress,
        );
      });
    });

    test('returns purchaseFailed for unknown error code', () {
      expect(
        PurchaseProcessor.mapErrorToType('UNKNOWN_ERROR'),
        PurchaseErrorType.purchaseFailed,
      );
    });

    test('returns purchaseFailed for empty string', () {
      expect(
        PurchaseProcessor.mapErrorToType(''),
        PurchaseErrorType.purchaseFailed,
      );
    });
  });

  group('PurchaseProcessor.isTerminalMappedError', () {
    // 종결 여부는 `_processActivePurchase`의 showMappedError 분기가 어템프트와
    // 90초 안전망 타이머를 함께 내릴지 결정한다. 종결인데 살려 두면 에러
    // 다이얼로그 뒤에 "구매 처리 지연" 팝업이 또 뜨고(1.3.0 베타), 비종결인데
    // 내리면 늦게 도착한 정산이 바인딩할 어템프트를 잃는다.
    test('timeout and network failures keep the attempt alive', () {
      expect(
        PurchaseProcessor.isTerminalMappedError(PurchaseErrorType.timeout),
        isFalse,
      );
      expect(
        PurchaseProcessor.isTerminalMappedError(PurchaseErrorType.networkError),
        isFalse,
      );
    });

    test('every other mapped error ends the attempt', () {
      const terminal = [
        PurchaseErrorType.previousTransactionPending,
        PurchaseErrorType.receiptVerificationFailed,
        PurchaseErrorType.userNotAuthenticated,
        PurchaseErrorType.productNotFound,
        PurchaseErrorType.purchaseFailed,
        PurchaseErrorType.serverError,
        PurchaseErrorType.purchaseCancelled,
        PurchaseErrorType.purchaseInProgress,
      ];
      for (final type in terminal) {
        expect(
          PurchaseProcessor.isTerminalMappedError(type),
          isTrue,
          reason: '$type must tear the attempt and its safety timer down',
        );
      }
    });
  });
}

PurchaseDetails _pendingPurchase() {
  final purchase = PurchaseDetails(
    purchaseID: '',
    productID: 'STAR100',
    verificationData: PurchaseVerificationData(
      localVerificationData: 'local',
      serverVerificationData: 'pending-token',
      source: 'test',
    ),
    transactionDate: '1785228000000',
    status: PurchaseStatus.pending,
  );
  purchase.pendingCompletePurchase = true;
  return purchase;
}

PurchaseDetails _purchasedPurchase() {
  final purchase = PurchaseDetails(
    purchaseID: 'order-id',
    productID: 'STAR100',
    verificationData: PurchaseVerificationData(
      localVerificationData: 'local',
      serverVerificationData: 'pending-token',
      source: 'test',
    ),
    transactionDate: '1785228000000',
    status: PurchaseStatus.purchased,
  );
  purchase.pendingCompletePurchase = true;
  return purchase;
}

class _RecordingPurchaseService extends Mock implements InAppPurchaseService {
  final List<PurchaseDetails> completed = [];

  @override
  Future<void> completePurchase(PurchaseDetails purchaseDetails) async {
    completed.add(purchaseDetails);
  }
}
