import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/ui.dart';
import 'package:picnic_lib/presentation/providers/product_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/analytics_service.dart';
import 'package:picnic_lib/core/services/in_app_purchase_service.dart';
import 'package:picnic_lib/core/constants/purchase_constants.dart';
import 'package:picnic_lib/core/services/receipt_verification_service.dart';
import 'package:picnic_lib/core/services/purchase_service_helper.dart';
// 🔥 복잡한 가드 시스템 제거 - 단순 중복 방지만 사용
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/services/duplicate_prevention_service.dart';
import 'package:picnic_lib/core/services/receipt_queue_service.dart';
import 'package:picnic_lib/data/models/purchase/purchase_settlement_result.dart';

typedef PurchaseSuccess =
    Future<void> Function(PurchaseSettlementResultModel result);

Future<void> deliverVerifiedPurchaseResult(
  PurchaseSettlementResultModel result,
  PurchaseSuccess onSuccess,
) => onSuccess(result);

class PurchaseService {
  PurchaseService({
    required this.container,
    required this.inAppPurchaseService,
    required this.receiptVerificationService,
    required this.analyticsService,
    required this.duplicatePreventionService,
    required void Function(List<PurchaseDetails>) onPurchaseUpdate,
  }) {
    inAppPurchaseService.initialize(onPurchaseUpdate);
    inAppPurchaseService.clearPendingPurchasesOnStartup();

    // 🚨 타임아웃 콜백 설정
    inAppPurchaseService.onPurchaseTimeout = handlePurchaseTimeout;

    logger.i('✅ PurchaseService 초기화 완료 - 강화된 중복 방지 시스템 활성화');

    // 앱 시작 시 큐 플러시
    unawaited(ReceiptQueueService().flushPending());

    // 안드로이드: 과거 미처리 구매 점검
    if (Platform.isAndroid) {
      unawaited(_reconcileAndroidPastPurchases());
    }
  }

  /// The Riverpod container, captured while the store was mounted.
  ///
  /// Not a [WidgetRef]: the reads below outlive the store. Receipt verification
  /// takes as long as the network takes, and the user is free to leave the
  /// store while it runs - `ConsumerState.ref` throws the moment `mounted` is
  /// false, so a read reached through the widget turns a purchase the server
  /// has already settled into an exception on the success path. The container
  /// belongs to the app-level `ProviderScope` and outlives the route, so the
  /// same read still lands. Same reason `WalletSummaryApplier` exists for the
  /// wallet write at the end of that path.
  final ProviderContainer container;
  final InAppPurchaseService inAppPurchaseService;
  final ReceiptVerificationService receiptVerificationService;
  final AnalyticsService analyticsService;
  final DuplicatePreventionService duplicatePreventionService;

  /// Helper for pure logic methods (testable without platform dependencies)
  final PurchaseServiceHelper helper = const PurchaseServiceHelper();

  // 🔥 단순화: 복잡한 가드 시스템 제거
  // 기본적인 제품별 구매 진행 상태만 추적 (백업용)
  final Set<String> _processingProducts = {};

  // 🧹 UI 리셋 콜백 (타임아웃 시 UI 상태 정리용)
  void Function()? onTimeoutUIReset;

  /// 구매 처리 메인 메서드
  Future<void> handlePurchase(
    PurchaseDetails purchaseDetails,
    VoidCallback onSuccess,
    Function(String) onError,
  ) async {
    try {
      logger.i('=== Purchase Handling Started ===');
      logger.i(
        'Processing: ${purchaseDetails.productID} (${purchaseDetails.status})',
      );

      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          logger.i('Purchase is pending...');
          break;
        case PurchaseStatus.error:
          await _handlePurchaseError(purchaseDetails, onError);
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _handleSuccessfulPurchase(purchaseDetails, onSuccess, onError);
          break;
        case PurchaseStatus.canceled:
          await _handlePurchaseCanceled(purchaseDetails, onError);
          break;
      }

      await _completePurchaseIfNeeded(purchaseDetails);
      logger.i('=== Purchase Handling Completed ===');
    } catch (e, s) {
      logger.e('Error handling purchase: $e', stackTrace: s);
      onError('GENERIC');
    }
  }

  /// 구매 처리 (단순화)
  ///
  /// 스토어 완료 처리(iOS finish / Android acknowledge·consume)는
  /// 영수증의 마지막 재시도 경로를 끊는 행위이므로 서버 정산이 확인된
  /// 경우에만 실행한다. 미확정 실패는 종류를 불문하고 트랜잭션을 남겨
  /// StoreKit 재전달(iOS)·큐/reconcile(Android)이 재시도하게 한다 —
  /// 예전에는 iOS를 무조건 finish해서, 일시적 네트워크 실패만으로도
  /// 과금된 영수증이 소멸(과금-미적립)할 수 있었다.
  ///
  /// [onAlreadySettled] is the success path for a purchase the server reports
  /// as *already* settled - a grant-confirmed duplicate. There is no settlement
  /// object to hand over (the response carries only the duplicate verdict), but
  /// the grant exists server-side, so this is a success and must be reported as
  /// one: the caller releases the product's spinner, re-reads the wallet and
  /// stops holding the purchase open. Reporting it through [onError] instead -
  /// what this did until 1.3.0 - left the store tile spinning until the 90s
  /// safety net fired, showed the user an error for candy they already own, and
  /// armed a duplicate cooldown that blocked the retry.
  Future<void> handleOptimizedPurchase(
    PurchaseDetails purchaseDetails,
    PurchaseSuccess onSuccess,
    Function(String) onError, {
    required bool isActualPurchase,
    Future<void> Function()? onAlreadySettled,
  }) async {
    var settlementConfirmed = false;
    Object? settlementFailure;
    try {
      if (isActualPurchase) {
        logger.i('=== 🚀 신규 구매 처리 ===');
        logger.i('Product: ${purchaseDetails.productID}');

        settlementConfirmed = await _handleActualPurchase(
          purchaseDetails,
          onSuccess,
          onError,
          onAlreadySettled: onAlreadySettled,
        );

        logger.i('=== ✅ 신규 구매 완료 ===');
      } else {
        logger.i('=== 🚫 복원 구매 무시 ===');
        logger.i('Product: ${purchaseDetails.productID}');

        // 🔥 복원 구매는 완전히 무시 - 콜백 실행 안함
        await _handleRestoredPurchase(purchaseDetails, onSuccess, onError);

        logger.i('=== ✅ 복원 구매 무시 완료 ===');
      }
    } catch (e, s) {
      logger.e('❌ 구매 처리 오류: $e', stackTrace: s);
      settlementFailure = e;

      // 🔥 오류 시 진행 상태 정리
      _processingProducts.remove(purchaseDetails.productID);

      // _handleActualPurchase는 rethrow 전에 이미 onError로 실패를 보고했다.
      // 여기서 또 부르면 하나의 정산 실패에 에러 다이얼로그가 두 번 뜨고
      // (타임아웃류 실패에서는 그중 하나가 "구매 처리 지연" 팝업이다 -
      // 1.3.0 베타), 타임아웃·네트워크에서 살려 두기로 한 어템프트까지
      // GENERIC(종결) 매핑이 제거해 버린다. 자체 보고가 없는 복원 경로의
      // 실패만 여기서 보고한다.
      if (!isActualPurchase) {
        onError('GENERIC');
      }
    } finally {
      if (settlementConfirmed) {
        // Android: consume(소비)까지, iOS: finish. 실패는 정산 결과를
        // 뒤집으면 안 되므로 로그만 남긴다(다음 reconcile이 재시도).
        await inAppPurchaseService
            .finalizeSettledPurchase(purchaseDetails)
            .catchError((e) {
          logger.w('정산 확정 구매 완료 처리 실패(다음 reconcile 재시도): $e');
        });
      } else {
        // 미확정 실패는 종류를 불문하고 스토어 트랜잭션을 파괴하지 않는다.
        // - 일시 실패(네트워크·5xx·타임아웃·인증): iOS는 StoreKit 재전달이,
        //   Android는 큐/reconcile이 재시도한다.
        // - 서버 영구 거부(422)조차 여기서 finish/consume하지 않는다:
        //   잘못 정리하면 과금된 영수증이 소멸하고(과금-미적립), Android는
        //   acknowledge/consume이 "미승인 구매 3일 자동 환불"이라는
        //   사용자의 마지막 구제책까지 차단한다. 잘못 보존한 비용은
        //   앱 시작마다의 재검증 노이즈뿐이며, 그 비대칭 때문에 보존이
        //   항상 이긴다. (영구 거부의 클라이언트 큐 재전송 중단은
        //   isPermanentSettlementRejection이 큐 계층에서 따로 처리한다.)
        logger.w(
          '⏸️ 서버 정산 미확인 - 구매 완료 처리 보류: '
          '${purchaseDetails.productID} (재전달/큐가 재시도, '
          '실패: $settlementFailure)',
        );
      }
    }
  }

  /// 구매 시작 (강화된 중복 방지) - 취소와 에러를 구분하여 반환
  ///
  /// **반환하는 결과 맵이 이 단계 실패의 유일한 보고 경로다.** 예전에는
  /// 같은 실패를 `onError(...)` 로도 보고했는데, 스토어 화면은 그 콜백에서
  /// `showErrorDialog` 를 띄우고 반환된 맵도 `PurchaseSafetyManager
  /// .handlePurchaseResult` 를 거쳐 다시 `showErrorDialog` 를 띄운다 —
  /// 하나의 실패에 다이얼로그가 두 장 겹쳐 뜬다. 결과 맵을 유일한 보고
  /// 경로로 남긴 이유는 그것이 취소 여부(`wasCancelled`)와 차단 유형
  /// (`denyType`)까지 함께 나르고, 상태 정리(어템프트 해제·쿨다운·스피너)가
  /// 이미 그 경로에 붙어 있기 때문이다.
  ///
  /// `errorMessage` 는 사용자 문장이 아니라 **에러 코드**다. arb 매핑은
  /// 호출자(UI)가 한다.
  ///
  /// 정산 단계(`handleOptimizedPurchase`)는 별개다 — 그쪽은 `onError` 가
  /// 유일한 보고 경로다.
  Future<Map<String, dynamic>> initiatePurchase(String productId) async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      return {
        'success': false,
        'wasCancelled': false,
        'errorMessage': 'USER_NOT_AUTHENTICATED',
      };
    }

    try {
      // 🛡️ 1. 강화된 중복 방지 검증
      final validation = await duplicatePreventionService
          .validatePurchaseAttempt(productId, currentUser.id);

      if (!validation.allowed) {
        logger.w('🚫 구매 중복 방지 검증 실패: ${validation.reason}');
        return {
          'success': false,
          'wasCancelled': false,
          'errorMessage': validation.reason,
          'denyType': validation.type?.toString(),
        };
      }

      logger.i('💳 구매 프로세스 시작 - Touch ID/Face ID 인증이 요청될 수 있습니다');

      // 🛡️ 2. 구매 시도 등록 (중복 방지 서비스에)
      duplicatePreventionService.registerPurchaseAttempt(
        productId,
        currentUser.id,
      );

      // 3. 제품 정보 확인
      final storeProducts = await container.read(storeProductsProvider.future);
      final serverProduct = container
          .read(serverProductsProvider.notifier)
          .getProductDetailById(productId);

      if (serverProduct == null) {
        duplicatePreventionService.completePurchase(
          productId,
          currentUser.id,
          success: false,
        );
        throw Exception('서버에서 상품 정보를 찾을 수 없습니다');
      }

      // 4. 구매 진행 상태 등록 (백업용)
      _processingProducts.add(productId);
      logger.i('✅ 구매 시작: $productId');

      // 🛡️ 5. Touch ID/Face ID 인증 시작 등록
      duplicatePreventionService.registerAuthenticationStart(
        productId,
        currentUser.id,
      );

      // 6. 실제 구매 시작
      final productDetails = _findProductDetails(storeProducts, serverProduct);
      logger.i('🚀 StoreKit 구매 프로세스 시작 (Touch ID/Face ID 인증 포함)');

      final purchaseResult = await inAppPurchaseService.makePurchase(
        productDetails,
        applicationUserName: currentUser.id,
      );

      if (!purchaseResult) {
        // 🔍 구매 실패 시 취소인지 실제 에러인지 구분
        if (inAppPurchaseService.lastPurchaseWasCancelled) {
          logger.i('🚫 구매 취소: $productId');
          _processingProducts.remove(productId);
          duplicatePreventionService.completePurchase(
            productId,
            currentUser.id,
            success: false,
          );
          // 취소는 에러가 아니므로 onError 호출하지 않음
          return {'success': false, 'wasCancelled': true, 'errorMessage': null};
        } else {
          logger.w('❌ 구매 요청 시작 실패: $productId');
          _processingProducts.remove(productId);
          duplicatePreventionService.completePurchase(
            productId,
            currentUser.id,
            success: false,
          );
          return {
            'success': false,
            'wasCancelled': false,
            // 런치 자체가 실패했다 - 아직 과금이 없으므로 재시도 안내가 맞다.
            'errorMessage': 'GENERIC',
          };
        }
      } else {
        logger.i('✅ StoreKit 구매 프로세스 시작 성공');
      }

      return {'success': true, 'wasCancelled': false, 'errorMessage': null};
    } catch (e, s) {
      logger.e('Error during purchase initiation: $e', stackTrace: s);
      _processingProducts.remove(productId);
      duplicatePreventionService.completePurchase(
        productId,
        currentUser.id,
        success: false,
      );

      return {
        'success': false,
        'wasCancelled': false,
        'errorMessage': helper.getPurchaseInitiationErrorCode(e),
      };
    }
  }

  /// 구매 에러 처리 (개선)
  Future<void> _handlePurchaseError(
    PurchaseDetails purchaseDetails,
    Function(String) onError,
  ) async {
    final error = purchaseDetails.error;
    logger.e('❌ 구매 에러: ${error?.message}, code: ${error?.code}');

    // 🔥 에러 시에도 진행 상태에서 제거
    _processingProducts.remove(purchaseDetails.productID);

    final errorMessage = _getErrorMessage(error);
    onError(errorMessage);

    await analyticsService.logPurchaseErrorEvent(
      productId: purchaseDetails.productID,
      errorCode: error?.code ?? 'unknown',
      errorMessage: error?.message ?? 'No error message',
    );

    logger.i('✅ 구매 에러 처리 완료: ${purchaseDetails.productID}');
  }

  /// 구매 취소 처리 (개선)
  Future<void> _handlePurchaseCanceled(
    PurchaseDetails purchaseDetails,
    Function(String) onError,
  ) async {
    logger.i('🚫 구매 취소: ${purchaseDetails.productID}');

    // 🔥 진행 상태에서 제거 (중요!)
    _processingProducts.remove(purchaseDetails.productID);

    // 🔥 구매 취소 애널리틱스 로깅
    await analyticsService.logPurchaseCancelEvent(purchaseDetails.productID);

    logger.i('✅ 구매 취소 처리 완료: ${purchaseDetails.productID}');

    // 🔥 취소는 오류가 아니므로 onError 호출하지 않음
    // UI에서 별도의 취소 처리 로직이 있음 (_processErrorAndCancel)
  }

  /// 성공적인 구매 처리
  Future<void> _handleSuccessfulPurchase(
    PurchaseDetails purchaseDetails,
    VoidCallback onSuccess,
    Function(String) onError,
  ) async {
    try {
      logger.i('Starting successful purchase handling...');

      _validateUserAuthentication();
      final environment = await receiptVerificationService.getEnvironment();

      await _verifyReceipt(purchaseDetails, environment);
      await _logPurchaseAnalytics(purchaseDetails);

      onSuccess();
      logger.i('Purchase successfully completed: ${purchaseDetails.productID}');
    } on ReusedPurchaseException catch (e) {
      logger.w('🔄 JWT 재사용 감지 (handleSuccessfulPurchase) - ${e.message}');
      final currentUser = supabase.auth.currentUser;
      if (currentUser != null) {
        duplicatePreventionService.completePurchase(
          purchaseDetails.productID,
          currentUser.id,
          // 지급이 확정된 중복은 사용자 입장에서 성공이다 - 영구 저장된
          // 진행 마커까지 정리해야 다음 실행에 유령으로 남지 않는다.
          success: e.grantConfirmed,
        );
      }
      if (e.grantConfirmed) {
        // 서버가 지급까지 확인한 중복은 성공으로 보고한다. 오류로 보고하면
        // 이미 받은 캔디에 대해 실패 안내가 뜬다.
        onSuccess();
        return;
      }
      // 지급 미확정 중복은 실패가 아니라 미확정이다 -
      // [_handleActualPurchase] 의 같은 분기와 이유가 같다.
      onError(PurchaseConstants.errProcessing);
      rethrow;
    } catch (e, s) {
      logger.e('Error in handleSuccessfulPurchase: $e', stackTrace: s);
      onError(_getDetailedErrorMessage(e));
      rethrow;
    }
  }

  /// 실제 구매 처리 (단순화)
  ///
  /// 반환값은 "서버 정산 확정" 여부다: 검증 성공, 또는 지급 완료가 확인된
  /// 중복(409)일 때만 true. 그 외에는 구매를 완료(consume)하면 안 된다.
  Future<bool> _handleActualPurchase(
    PurchaseDetails purchaseDetails,
    PurchaseSuccess onSuccess,
    Function(String) onError, {
    Future<void> Function()? onAlreadySettled,
  }) async {
    final platform = Platform.isIOS ? 'iOS' : 'Android';
    logger.i('🎯 실제 구매 처리 시작 ($platform) - 영수증 검증');
    logger.i('  - Product ID: ${purchaseDetails.productID}');
    logger.i('  - Transaction ID: ${purchaseDetails.purchaseID}');
    logger.i('  - Status: ${purchaseDetails.status}');

    try {
      _validateUserAuthentication();

      final environment = await receiptVerificationService.getEnvironment();
      logger.i('🌍 Environment detected: $environment ($platform)');

      await _validateReceiptData(purchaseDetails);
      logger.i('✅ 영수증 데이터 검증 완료 ($platform)');

      // 🔥 영수증 검증 (서버 검증 단계만 - 타임아웃 있음)
      logger.i('🔍 서버 영수증 검증 시작 ($platform)');
      final result = await _verifyReceipt(purchaseDetails, environment);
      logger.i('✅ 서버 영수증 검증 완료 ($platform)');

      await _logPurchaseAnalytics(purchaseDetails);

      // 🔥 구매 완료 시 진행 상태 제거
      _processingProducts.remove(purchaseDetails.productID);

      // 🛡️ 중복 방지 서비스에 성공 알림
      final currentUser = supabase.auth.currentUser;
      if (currentUser != null) {
        duplicatePreventionService.completePurchase(
          purchaseDetails.productID,
          currentUser.id,
          success: true,
        );
      }

      await _presentSettlementGuarded(
        () => deliverVerifiedPurchaseResult(result, onSuccess),
        purchaseDetails,
      );
      logger.i('✅ 실제 구매 검증 완료 ($platform)');
      return true;
    } on ReusedPurchaseException catch (e) {
      logger.w('🔄 JWT 재사용 감지 ($platform) - StoreKit 캐시 문제: ${e.message}');
      _processingProducts.remove(purchaseDetails.productID);

      final currentUser = supabase.auth.currentUser;
      if (e.grantConfirmed) {
        // 서버가 "이 영수증은 지급까지 끝났다"고 확인한 중복이다. 사용자
        // 입장에서 이것은 성공이며, 실패로 보고하면 (1) 이미 받은 캔디에
        // 대해 오류 안내가 뜨고 (2) 상품 스피너가 90초 안전망까지 내려가지
        // 않고 (3) 중복 쿨다운이 재시도까지 막는다. 1.3.0 베타의 "실패한
        // 구매의 버튼이 영구 로딩" 리포트가 이 경로다 — iOS 멱등 캐시
        // (SharedPreferences)는 앱을 재시작해도 살아 있으므로 재전달마다
        // 같은 예외가 되풀이됐다.
        logger.w('♻️ 서버 지급 확정 중복 - 정산 성공으로 처리 ($platform)');
        if (currentUser != null) {
          // success: true는 진행 상태와 함께 영구 저장된 구매 진행 마커
          // (last_purchase_attempt_/authentication_start_/
          // background_purchase_)까지 정리한다.
          duplicatePreventionService.completePurchase(
            purchaseDetails.productID,
            currentUser.id,
            success: true,
          );
        }
        if (onAlreadySettled != null) {
          await _presentSettlementGuarded(onAlreadySettled, purchaseDetails);
        }
        // 지급이 확인된 중복만 스토어 트랜잭션을 완료(finish/consume)한다.
        return true;
      }

      // 🛡️ 중복 방지 서비스에 실패 알림
      if (currentUser != null) {
        duplicatePreventionService.completePurchase(
          purchaseDetails.productID,
          currentUser.id,
          success: false,
        );
      }

      // 여기까지 왔다는 것은 서버에 다시 물어봐도(ReceiptVerificationService
      // 의 재확인 경로) 정산을 확인해 주지 못했다는 뜻이다: 영수증은 서버가
      // 알고 있는데 지급은 확정되지 않았다. 결제는 접수된 상태이므로 이것은
      // **실패가 아니라 미확정**이다.
      //
      // 예전에는 `ERR_PREV_TX` 를 보고했고, 그 코드는 "이전 결제가 스토어에서
      // 처리 중입니다. 잠시 후 다시 시도해 주세요." 로 표시된다 — 소비형
      // 상품에서 재시도를 권하는 문장이라 되돌릴 수 없는 이중 과금을
      // 유도한다. PROCESSING 은 같은 사실을 "접수됐고 처리되면 자동
      // 적립된다"로 안내하고, 그 상품의 재구매만 정산 쿨다운으로 막는다.
      onError(PurchaseConstants.errProcessing);
      // 지급이 확인되지 않은 중복(영수증만 있고 지급 실패)은 트랜잭션을
      // 남겨 두어 재시도를 보존한다.
      return false;
    } catch (e, s) {
      logger.e('❌ 실제 구매 처리 중 오류 ($platform): $e', stackTrace: s);
      _processingProducts.remove(purchaseDetails.productID);

      // 🛡️ 중복 방지 서비스에 실패 알림
      final currentUser = supabase.auth.currentUser;
      if (currentUser != null) {
        duplicatePreventionService.completePurchase(
          purchaseDetails.productID,
          currentUser.id,
          success: false,
        );
      }

      onError(_getDetailedErrorMessage(e));
      rethrow;
    }
  }

  /// 복원된 구매 처리 (무시)
  Future<void> _handleRestoredPurchase(
    PurchaseDetails purchaseDetails,
    PurchaseSuccess onSuccess,
    Function(String) onError,
  ) async {
    logger.i('🚫 복원된 구매 무시: ${purchaseDetails.productID}');

    // iOS: 조용히 finish만 해서 반복 재전달을 막는다.
    // Android: 복원(restored)으로 온 미소비 구매를 여기서 완료하면 검증 없이
    // 소비되어 복구가 불가능해진다. reconcile(과거 구매 재검증)이 검증 후
    // 소비하므로 여기서는 손대지 않는다.
    if (Platform.isIOS) {
      await _completePurchaseIfNeeded(purchaseDetails);
    }

    // 진행 상태에서 제거 (혹시 있다면)
    _processingProducts.remove(purchaseDetails.productID);

    logger.i('✅ 복원된 구매 무시 완료');
  }

  /// 사용자 인증 검증 (단순화 - 타임아웃 제거)
  void _validateUserAuthentication() {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      throw Exception('USER_NOT_AUTHENTICATED');
    }
    logger.i('✅ 사용자 인증 확인 완료: ${currentUser.id}');
  }

  /// 영수증 데이터 검증
  Future<void> _validateReceiptData(PurchaseDetails purchaseDetails) async {
    final platform = Platform.isIOS ? 'iOS' : 'Android';
    final receiptData = purchaseDetails.verificationData.serverVerificationData;

    logger.i('🔍 영수증 데이터 검증 시작 ($platform)');
    logger.i('  - Receipt length: ${receiptData.length} characters');
    logger.i(
      '  - Receipt preview: ${receiptData.length > 50 ? "${receiptData.substring(0, 50)}..." : receiptData}',
    );

    if (receiptData.isEmpty) {
      logger.e('❌ 영수증 데이터가 비어있음 ($platform)');
      throw Exception('영수증 데이터가 비어있습니다');
    }

    logger.i('✅ 영수증 데이터 검증 완료 ($platform) - 길이: ${receiptData.length}');
  }

  /// 영수증 검증 (단순화 - 서비스에 위임)
  Future<PurchaseSettlementResultModel> _verifyReceipt(
    PurchaseDetails purchaseDetails,
    String environment,
  ) async {
    final receiptData = purchaseDetails.verificationData.serverVerificationData;
    final currentUser = supabase.auth.currentUser!;

    logger.i('🔍 영수증 검증 시작 (서버 검증 단계)');
    logger.i('Environment: $environment');

    // ReceiptVerificationService가 타임아웃 + 재시도 로직을 모두 처리
    final result = await receiptVerificationService.verifyReceipt(
      receiptData,
      purchaseDetails.productID,
      currentUser.id,
      environment,
    );

    logger.i('✅ 영수증 검증 완료');
    return result;
  }

  /// Runs the caller's settlement presentation and swallows whatever it throws.
  ///
  /// Everything downstream of a verified receipt is presentation: the wallet
  /// write, the receipt dialog, the spinner teardown. The grant already exists
  /// server-side, so a failure there says nothing about whether the purchase
  /// settled - but letting it escape makes `_handleActualPurchase` return
  /// through its catch, which reports `settlementConfirmed = false` and so
  /// *preserves* the store transaction. On iOS that transaction is re-delivered
  /// on every launch, and because the iOS idempotency cache has already
  /// recorded the receipt, every re-delivery comes back as a duplicate instead
  /// of a settlement - the permanent limbo behind the stuck buy button.
  ///
  /// Preserving a transaction is the right default for an *unconfirmed*
  /// settlement only. Once the server has confirmed the grant, finishing is
  /// what stops the loop, so a presentation failure must not veto it.
  Future<void> _presentSettlementGuarded(
    Future<void> Function() present,
    PurchaseDetails purchaseDetails,
  ) async {
    try {
      await present();
    } catch (e, s) {
      logger.e(
        '정산 결과 표시 실패 - 서버 정산은 이미 확정: ${purchaseDetails.productID}',
        error: e,
        stackTrace: s,
      );
    }
  }

  /// 구매 애널리틱스 로깅
  ///
  /// Runs between "the receipt verified" and "the caller is told the purchase
  /// succeeded", and therefore must not be able to fail the purchase. By the
  /// time it runs the candy is already granted server-side; letting it throw
  /// hands the settled purchase to the catch in [_handleActualPurchase], which
  /// records `completePurchase(success: false)` for a purchase that succeeded
  /// and calls `onError` instead of `onSuccess` - so the settlement, and with
  /// it the wallet write, never runs.
  ///
  /// [AnalyticsService] already swallows its own failures. What could throw is
  /// the *lookup* this needs to name the product: the provider read, and the
  /// `PRODUCT_NOT_FOUND` below when the store catalogue does not carry an id it
  /// just sold. Neither says anything about whether the user was charged.
  Future<void> _logPurchaseAnalytics(PurchaseDetails purchaseDetails) async {
    try {
      final storeProducts = await container.read(storeProductsProvider.future);
      final productDetails = storeProducts.firstWhere(
        (product) => product.id == purchaseDetails.productID,
        orElse: () => throw Exception('PRODUCT_NOT_FOUND'),
      );

      logger.i('애널리틱스 로깅...');
      await analyticsService.logPurchaseEvent(
        productDetails,
        transactionId: purchaseDetails.purchaseID,
      );
      logger.i('애널리틱스 로깅 완료');
    } catch (e, s) {
      logger.e('애널리틱스 로깅 실패 - 구매 결과에는 영향 없음: $e', stackTrace: s);
    }
  }

  /// 구매 완료 처리
  Future<void> _completePurchaseIfNeeded(
    PurchaseDetails purchaseDetails,
  ) async {
    if (purchaseDetails.pendingCompletePurchase) {
      logger.i('구매 완료 처리 중...');
      await inAppPurchaseService.completePurchase(purchaseDetails);
      logger.i('구매 완료 처리됨');
    }
  }

  /// 상품 세부 정보 찾기
  ProductDetails _findProductDetails(
    List<ProductDetails> storeProducts,
    Map<String, dynamic> serverProduct,
  ) {
    return helper.findProductDetails(
      storeProducts: storeProducts,
      serverProductId: serverProduct['id'] as String,
      isAndroid: isAndroid(),
      inappAppNamePrefix: Environment.inappAppNamePrefix,
      environment: Environment.currentEnvironment,
      // 단일 출처 — 카탈로그 조회·버튼 판정과 반드시 같은 값.
      paymentProductNamespace: Environment.storeQueryNamespace,
    );
  }

  /// 에러 메시지 생성
  String _getErrorMessage(IAPError? error) {
    return helper.getErrorMessage(error);
  }

  /// 상세 에러 메시지 생성
  String _getDetailedErrorMessage(dynamic error) {
    return helper.getDetailedErrorMessage(error);
  }

  /// 서비스 해제 시 모든 진행 상태 정리
  void dispose() {
    logger.i('🧹 PurchaseService 해제: ${_processingProducts.length}개 진행 상태 정리');
    _processingProducts.clear();

    // 🛡️ 중복 방지 서비스 데이터 정리
    duplicatePreventionService.cleanupExpiredData();

    logger.i('✅ PurchaseService 해제 완료');
  }

  /// 현재 진행 중인 구매 수 (디버그용)
  int get activeProcessingCount => _processingProducts.length;

  /// 타임아웃 발생 시 구매 상태 정리 (InAppPurchaseService에서 호출)
  void handlePurchaseTimeout(String productId) {
    logger.w('⏰ 구매 타임아웃으로 인한 상태 정리: $productId');

    final currentUser = supabase.auth.currentUser;
    if (currentUser != null) {
      // 🛡️ 중복 방지 서비스에서 백그라운드 구매로 전환
      duplicatePreventionService.handlePurchaseTimeout(
        productId,
        currentUser.id,
      );
    }

    if (_processingProducts.contains(productId)) {
      _processingProducts.remove(productId);
      logger.i('✅ 타임아웃된 구매 상태 정리 완료: $productId');
    } else {
      logger.i('ℹ️ 타임아웃된 구매가 진행 상태에 없음: $productId');
    }

    // 🧹 UI 상태 리셋 (로딩 해제, 구매 상태 초기화)
    if (onTimeoutUIReset != null) {
      logger.i('🧹 타임아웃으로 인한 UI 상태 리셋 호출');
      onTimeoutUIReset!();
    } else {
      logger.w('⚠️ UI 리셋 콜백이 설정되지 않음 - UI가 로딩 상태로 남을 수 있음');
    }

    // 타임아웃 이후에도 큐 플러시 재시도
    unawaited(ReceiptQueueService().flushPending());
  }

  Future<void> _reconcileAndroidPastPurchases() async {
    try {
      logger.i('🔍 Android 과거 구매 조회 시작');
      final addition = InAppPurchase.instance
          .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
      final resp = await addition.queryPastPurchases();
      if (resp.error != null) {
        // 빈 목록과 조회 실패는 다르다. 실패면 다음 기회에 다시 시도해야
        // 하므로 명시적으로 남긴다.
        logger.w('⚠️ 과거 구매 조회 오류: ${resp.error}');
      }
      if (resp.pastPurchases.isEmpty) {
        logger.i('ℹ️ 과거 구매 없음');
        return;
      }

      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        logger.w('ℹ️ 로그인되지 않아 과거 구매 재검증 생략');
        return;
      }

      final environment = await receiptVerificationService.getEnvironment();

      for (final p in resp.pastPurchases) {
        final receipt = p.verificationData.serverVerificationData;
        if (receipt.isEmpty) continue;

        // 서버는 구매 토큰 기준으로 멱등하므로 직접 재검증한다.
        // (verifyReceipt가 내부에서 큐 적재→성공 시 제거를 수행하므로
        // 실패해도 항목이 큐에 남아 이후 플러시가 재시도한다.)
        // 소비(consume)는 적립이 확인된 뒤에만 한다 — 소비가 먼저면
        // 실패 시 복구 수단이 사라진다.
        try {
          await receiptVerificationService.verifyReceipt(
            receipt,
            p.productID,
            currentUser.id,
            environment,
          );
          await inAppPurchaseService.finalizeSettledPurchase(p).catchError((e) {
            logger.w('과거 구매 소비 실패(다음 reconcile에서 재시도): $e');
          });
          logger.i('♻️ 과거 구매 정산+소비 완료: ${p.productID}');
        } on ReusedPurchaseException catch (e) {
          if (e.grantConfirmed) {
            // 이미 지급까지 끝난 구매 → 소비만 하면 된다.
            await inAppPurchaseService.finalizeSettledPurchase(p).catchError((
              err,
            ) {
              logger.w('과거 구매 소비 실패(다음 reconcile에서 재시도): $err');
            });
            logger.i('♻️ 기지급 과거 구매 소비 완료: ${p.productID}');
          } else {
            logger.w('과거 구매 중복이나 지급 미확인 - 소비 보류: ${p.productID}');
          }
        } catch (e) {
          logger.w('과거 구매 재검증 실패(큐 유지): ${p.productID} ($e)');
        }
      }

      await ReceiptQueueService().flushPending();
      logger.i('✅ Android 과거 구매 재검증 완료');
    } catch (e, s) {
      logger.e('Android 과거 구매 조회/재검증 실패: $e', stackTrace: s);
    }
  }

  /// 모든 진행 중인 구매 상태 강제 정리 (긴급 상황용)
  void clearAllProcessingStates() {
    logger.w('🚨 모든 구매 진행 상태 강제 정리: ${_processingProducts.length}개');
    _processingProducts.clear();
    logger.i('✅ 모든 구매 상태 정리 완료');
  }

  /// 특정 상품의 진행 상태 확인 (디버그용)
  bool isProductProcessing(String productId) {
    return _processingProducts.contains(productId);
  }

  // 🧪 ============ 디버그 기능들 ============

  /// 🧪 디버그 모드 활성화 (타임아웃 시간 3초로 단축)
  void enableDebugMode() {
    inAppPurchaseService.setDebugMode(true);
    logger.w('🧪 구매 디버그 모드 활성화 - 타임아웃 3초로 단축');
  }

  /// 🧪 디버그 모드 비활성화 (타임아웃 시간 30초로 복원)
  void disableDebugMode() {
    inAppPurchaseService.setDebugMode(false);
    logger.i('🧪 구매 디버그 모드 비활성화 - 타임아웃 30초로 복원');
  }

  /// 🧪 타임아웃 모드 설정 (더 세밀한 제어)
  void setTimeoutMode(String mode) {
    inAppPurchaseService.setTimeoutMode(mode);
    logger.w('🧪 타임아웃 모드 설정: $mode');
  }

  /// 🧪 구매 지연 시뮬레이션 활성화
  void enableSlowPurchase() {
    inAppPurchaseService.setSlowPurchaseSimulation(true);
    logger.w('🧪 구매 지연 시뮬레이션 활성화 - 5초 지연');
  }

  /// 🧪 구매 지연 시뮬레이션 비활성화
  void disableSlowPurchase() {
    inAppPurchaseService.setSlowPurchaseSimulation(false);
    logger.i('🧪 구매 지연 시뮬레이션 비활성화');
  }

  /// 🎯 강제 타임아웃 시뮬레이션 활성화 (실제 구매 요청 안함)
  void enableForceTimeout() {
    inAppPurchaseService.setForceTimeoutSimulation(true);
    logger.w('🎯 강제 타임아웃 시뮬레이션 활성화 - 실제 구매 요청 없이 무조건 타임아웃');
  }

  /// 🎯 강제 타임아웃 시뮬레이션 비활성화 (정상 구매 진행)
  void disableForceTimeout() {
    inAppPurchaseService.setForceTimeoutSimulation(false);
    logger.i('🎯 강제 타임아웃 시뮬레이션 비활성화 - 정상 구매 진행');
  }

  /// 🧪 수동 타임아웃 트리거 (테스트용)
  void triggerManualTimeout({String? productId}) {
    logger.w('🧪 수동 타임아웃 트리거 요청: ${productId ?? "현재 구매 중인 상품"}');
    inAppPurchaseService.triggerManualTimeout(productId: productId);
  }

  /// 🧪 현재 디버그 상태와 진행 중인 구매 상태 출력
  void printDebugStatus() {
    logger.i(
      '🧪 === 구매 디버그 상태 ===\n🧪 디버그 모드: ${inAppPurchaseService.debugMode ? "활성화" : "비활성화"}\n🧪 타임아웃 모드: ${inAppPurchaseService.debugTimeoutMode}\n🧪 구매 지연: ${inAppPurchaseService.simulateSlowPurchase ? "활성화" : "비활성화"}\n🎯 강제 타임아웃: ${inAppPurchaseService.forceTimeoutSimulation ? "활성화" : "비활성화"}\n🧪 진행 중인 구매: ${_processingProducts.length}개${_processingProducts.isNotEmpty ? '\n${_processingProducts.map((productId) => '🧪   → $productId').join('\n')}' : ''}\n🧪 ========================',
    );
  }
}
