import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picnic_lib/core/constants/purchase_constants.dart';
import 'package:picnic_lib/core/config/payment_product_id_policy.dart';

/// Pure logic methods extracted from PurchaseService for testability.
///
/// These methods contain no side effects, no Supabase/plugin dependencies,
/// and can be tested without mocking platform channels.
class PurchaseServiceHelper {
  const PurchaseServiceHelper();

  /// 에러 메시지 생성 (IAPError code -> user-facing message)
  String getErrorMessage(IAPError? error) {
    if (error == null) return 'GENERIC';

    switch (error.code) {
      case 'payment_invalid':
        return '결제 정보가 유효하지 않습니다.';
      case 'payment_canceled':
        return PurchaseConstants.errPurchaseCanceled;
      case 'store_problem':
        return PurchaseConstants.errServer;
      default:
        return 'GENERIC';
    }
  }

  /// 상세 에러 메시지 생성 (exception -> error code)
  String getDetailedErrorMessage(dynamic error) {
    final errorString = error.toString();

    if (errorString.contains('Receipt verification failed')) {
      return 'RECEIPT_VERIFICATION_FAILED';
    } else if (errorString.contains('timeout') ||
        errorString.contains('타임아웃')) {
      return PurchaseConstants.errTimeout;
    } else if (errorString.contains('Touch ID') ||
        errorString.contains('Face ID')) {
      return PurchaseConstants.errAuthTimeout;
    } else if (errorString.contains('USER_NOT_AUTHENTICATED')) {
      return 'USER_NOT_AUTHENTICATED';
    } else if (errorString.contains('PRODUCT_NOT_FOUND')) {
      return 'PRODUCT_NOT_FOUND';
    } else if (errorString.toLowerCase().contains('network')) {
      return PurchaseConstants.errNetwork;
    } else if (errorString.toLowerCase().contains('server')) {
      return PurchaseConstants.errServer;
    }

    return 'GENERIC';
  }

  /// 사용자 친화적 오류 메시지 생성 (initiatePurchase catch block)
  String getUserFriendlyErrorMessage(dynamic error) {
    final errorString = error.toString();
    if (errorString.contains('상품 정보')) {
      return '상품 정보를 찾을 수 없습니다. 잠시 후 다시 시도해주세요.';
    } else if (errorString.contains('네트워크')) {
      return '네트워크 연결을 확인해주세요.';
    }
    return '구매 시작 중 오류가 발생했습니다';
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
