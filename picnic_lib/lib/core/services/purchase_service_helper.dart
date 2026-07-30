import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picnic_lib/core/constants/purchase_constants.dart';
import 'package:picnic_lib/core/config/payment_product_id_policy.dart';
import 'package:picnic_lib/core/services/purchase_failure_classifier.dart';
import 'package:picnic_lib/core/services/receipt_verification_service.dart'
    show ReceiptResponseContractException;

/// Pure logic methods extracted from PurchaseService for testability.
///
/// These methods contain no side effects, no Supabase/plugin dependencies,
/// and can be tested without mocking platform channels.
class PurchaseServiceHelper {
  const PurchaseServiceHelper();

  /// 에러 메시지 생성 (IAPError code -> error code)
  ///
  /// 반환값은 **에러 코드**다. 사용자에게 보일 문장은 UI 계층이 arb 로
  /// 만든다 — 여기서 한국어 문장을 만들면 App Review 리뷰어를 포함한
  /// 비한국어 사용자가 한국어 오류를 본다.
  String getErrorMessage(IAPError? error) {
    if (error == null) return 'GENERIC';

    switch (error.code) {
      case 'payment_invalid':
        return PurchaseConstants.errPaymentInvalid;
      case 'payment_canceled':
        return PurchaseConstants.errPurchaseCanceled;
      case 'store_problem':
        return PurchaseConstants.errServer;
      default:
        return 'GENERIC';
    }
  }

  /// 상세 에러 메시지 생성 (exception -> error code)
  ///
  /// **타입과 상태 코드가 먼저다.** 문자열 매칭이 먼저였던 동안
  /// `TimeoutException`("TimeoutException after ...": 소문자 'timeout' 이
  /// 없다)과 `FunctionException`(매칭할 단어가 아예 없다)이 GENERIC 으로
  /// 떨어져, 정산이 진행 중인 결제가 종결 실패로 안내됐다 —
  /// [PurchaseFailureClassifier] 참고. 남은 문자열 휴리스틱은 스토어
  /// 플러그인이 문장으로만 주는 신호(Touch ID/Face ID 등)를 위한
  /// 폴백이며, 타입 분류가 unknown 일 때만 본다.
  String getDetailedErrorMessage(dynamic error) {
    switch (PurchaseFailureClassifier.classify(error)) {
      case PurchaseFailureClass.processing:
        return PurchaseConstants.errProcessing;
      case PurchaseFailureClass.permanentRejection:
        // 서버가 이 영수증을 판정했다 — 재전송으로 뒤집히지 않는다.
        return 'RECEIPT_VERIFICATION_FAILED';
      case PurchaseFailureClass.unknown:
        break;
    }

    // 응답은 도착했고 정산은 서버에서 끝났지만 본문을 해석하지 못한 경우.
    // 재전송은 중복 요청만 만들고, 적립은 이미 됐거나 곧 된다 → 미확정.
    if (error is ReceiptResponseContractException) {
      return PurchaseConstants.errProcessing;
    }

    final errorString = error.toString();
    final lower = errorString.toLowerCase();

    if (errorString.contains('Receipt verification failed')) {
      return 'RECEIPT_VERIFICATION_FAILED';
    } else if (lower.contains('timeout') || errorString.contains('타임아웃')) {
      // 대소문자를 가리던 자리. 'timeout' 만 보던 탓에 TimeoutException 이
      // 여기 걸리지 못했다.
      return PurchaseConstants.errProcessing;
    } else if (errorString.contains('Touch ID') ||
        errorString.contains('Face ID')) {
      return PurchaseConstants.errAuthTimeout;
    } else if (errorString.contains('USER_NOT_AUTHENTICATED')) {
      return 'USER_NOT_AUTHENTICATED';
    } else if (errorString.contains('PRODUCT_NOT_FOUND')) {
      return 'PRODUCT_NOT_FOUND';
    } else if (lower.contains('network')) {
      return PurchaseConstants.errNetwork;
    } else if (lower.contains('server')) {
      return PurchaseConstants.errServer;
    }

    return 'GENERIC';
  }

  /// 구매 시작(런치) 단계 실패의 에러 코드 (initiatePurchase catch block).
  ///
  /// 여기도 사용자 문장이 아니라 코드를 돌려준다. 런치 단계 실패는 아직
  /// 과금이 없으므로 재시도 안내가 맞지만, 문장 자체는 arb 에서 온다.
  String getPurchaseInitiationErrorCode(dynamic error) {
    if (PurchaseFailureClassifier.isStillProcessing(error)) {
      return PurchaseConstants.errProcessing;
    }
    final errorString = error.toString();
    if (errorString.contains('상품 정보') ||
        errorString.contains('상품을 찾을 수 없습니다')) {
      return 'PRODUCT_NOT_FOUND';
    }
    if (errorString.contains('네트워크') ||
        errorString.toLowerCase().contains('network')) {
      return PurchaseConstants.errNetwork;
    }
    return 'GENERIC';
  }

  /// 스토어 카탈로그에 [serverProductId] 에 해당하는 상품이 있는지.
  ///
  /// [findProductDetails] 와 **동일한** ID 정책으로 판정한다. 구매 버튼
  /// 활성 여부가 이 함수를 쓰므로, 정책이 어긋나면 버튼이 항상 죽거나
  /// (서버 ID 는 대문자 STARxxx, Play SKU 는 소문자 강제 — raw 비교는
  /// Android 에서 구조적으로 false) 눌리는데 구매가 실패한다.
  bool storeHasProduct({
    required List<ProductDetails> storeProducts,
    required String serverProductId,
    required bool isAndroid,
    required String inappAppNamePrefix,
    String environment = 'prod',
    String paymentProductNamespace = '',
  }) {
    final expectedId = PaymentProductIdPolicy.effectiveProductId(
      environment: environment,
      isAndroid: isAndroid,
      paymentNamespace: paymentProductNamespace,
      serverProductId: serverProductId,
      iosAppPrefix: inappAppNamePrefix,
    );
    return storeProducts.any(
      (element) =>
          (isAndroid ? element.id.toLowerCase() : element.id) == expectedId,
    );
  }

  /// 상품 세부 정보 찾기 (store products에서 server product ID 매칭)
  ProductDetails findProductDetails({
    required List<ProductDetails> storeProducts,
    required String serverProductId,
    required bool isAndroid,
    required String inappAppNamePrefix,
    String environment = 'prod',
    String paymentProductNamespace = '',
  }) {
    final expectedId = PaymentProductIdPolicy.effectiveProductId(
      environment: environment,
      isAndroid: isAndroid,
      paymentNamespace: paymentProductNamespace,
      serverProductId: serverProductId,
      iosAppPrefix: inappAppNamePrefix,
    );
    return storeProducts.firstWhere(
      (element) =>
          (isAndroid ? element.id.toLowerCase() : element.id) == expectedId,
      orElse: () => throw Exception('스토어에서 상품을 찾을 수 없습니다'),
    );
  }

  /// 구매 결과 Map 생성 - 성공
  Map<String, dynamic> buildSuccessResult() {
    return {'success': true, 'wasCancelled': false, 'errorMessage': null};
  }

  /// 구매 결과 Map 생성 - 취소
  Map<String, dynamic> buildCancelledResult() {
    return {'success': false, 'wasCancelled': true, 'errorMessage': null};
  }

  /// 구매 결과 Map 생성 - 에러
  Map<String, dynamic> buildErrorResult(String errorMessage,
      {String? denyType}) {
    final result = <String, dynamic>{
      'success': false,
      'wasCancelled': false,
      'errorMessage': errorMessage,
    };
    if (denyType != null) {
      result['denyType'] = denyType;
    }
    return result;
  }
}
