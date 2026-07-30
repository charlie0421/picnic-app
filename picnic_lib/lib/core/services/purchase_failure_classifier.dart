import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart' show FunctionException;

/// 하나의 구매 실패가 사용자에게 무엇을 의미하는지.
enum PurchaseFailureClass {
  /// 결제는 접수됐고 정산 결과를 아직 모른다 — 실패로 안내해서는 안 된다.
  processing,

  /// 서버가 이 요청에 대해 판정을 내렸다 — 같은 본문을 다시 보내도 같은 답이다.
  permanentRejection,

  /// 위 어느 쪽도 아님. 호출자가 기존 휴리스틱으로 계속 판정한다.
  unknown,
}

/// 구매 실패를 **타입과 상태 코드**로 분류하는 단일 경계.
///
/// 여기가 존재하는 이유는 문자열 매칭이 실제로 사용자에게 이중 과금을
/// 시켰기 때문이다. `PurchaseServiceHelper.getDetailedErrorMessage` 는
/// `errorString.contains('timeout')` 로 타임아웃을 판별했는데
/// `TimeoutException.toString()` 은 대문자 T 의 "TimeoutException after
/// 0:00:30.000000: Future not completed" 다. 소문자 'timeout' 이 없으므로
/// 판정은 GENERIC → `purchaseFailed`(종결 실패)로 떨어졌고, 사용자는
/// "구매 중 오류가 발생했습니다. 나중에 다시 시도해주세요" 를 본다.
/// `FunctionException`(422/503) 에는 애초에 매칭할 단어가 없어서 서버가
/// 의도적으로 구분한 503(재시도 가능)과 422(영구 거부)가 같은 다이얼로그로
/// 붕괴했다.
///
/// 실제 피해는 안내 문구가 아니라 타이밍이다. 클라이언트 예산은 30초
/// 타임아웃 + 2·4초 백오프인데(`PurchaseConstants`) 서버 워커의 리스는
/// 60초이고 정산은 cron 재시도를 거쳐 수 분이 걸릴 수 있다. 즉 **정산이
/// 진행 중인 결제**가 적립 직전에 "실패했으니 다시 시도하라"고 안내되고,
/// 사용자는 그 안내를 따라 소비형 상품을 한 번 더 결제한다.
///
/// 그래서 분류는 문자열이 아니라 타입과 상태 코드로만 한다.
class PurchaseFailureClassifier {
  const PurchaseFailureClassifier._();

  /// 서버가 이 요청에 대해 내린 판정으로 취급하는 상태 코드.
  ///
  /// - 422: 워커의 명시적 비재시도 판정.
  /// - 400: 요청 본문이 계약을 만족하지 못한다.
  /// - 403: 이 요청은 거부됐다.
  ///
  /// 이 판정은 **재시도 루프를 멈추는 데만** 쓴다. 스토어 트랜잭션 파괴와
  /// 클라이언트 큐 제거는 별개의(더 좁은) 판정이다 —
  /// `isPermanentSettlementRejection` 은 422 만 인정한다. 그래서 정말로
  /// 일시 오류였던 400 도 잃지 않는다: 트랜잭션과 큐 항목이 남아 다음
  /// 실행의 재전달·플러시가 다시 시도한다.
  static const Set<int> permanentStatuses = {400, 403, 422};

  static PurchaseFailureClass classify(Object? error) {
    if (error is FunctionException) {
      if (permanentStatuses.contains(error.status)) {
        return PurchaseFailureClass.permanentRejection;
      }
      if (error.status >= 500 || _isRetryableDetails(error.details)) {
        return PurchaseFailureClass.processing;
      }
      return PurchaseFailureClass.unknown;
    }

    // 응답을 받지 못한 실패. 요청이 서버에 도달했는지, 도달했다면 정산까지
    // 끝났는지 클라이언트는 알 수 없다 — 그래서 실패가 아니라 미확정이다.
    if (error is TimeoutException ||
        error is SocketException ||
        error is HttpException ||
        error is http.ClientException) {
      return PurchaseFailureClass.processing;
    }

    return PurchaseFailureClass.unknown;
  }

  /// 결과를 모르는(=실패로 안내하면 안 되는) 실패인지.
  static bool isStillProcessing(Object? error) =>
      classify(error) == PurchaseFailureClass.processing;

  /// 서버 판정으로 재시도를 멈춰야 하는 실패인지.
  static bool isPermanentRejection(Object? error) =>
      classify(error) == PurchaseFailureClass.permanentRejection;

  /// 서버가 응답 본문에 붙인 재시도 힌트.
  ///
  /// wallet.v1 은 오퍼레이션이 큐에 남아 있을 때 `retryable: true` 를
  /// 실어 보낸다. 상태 코드만으로는 5xx 가 아닌 재시도 가능 응답을 놓친다.
  static bool _isRetryableDetails(Object? details) {
    if (_retryableFlag(details)) return true;
    if (details is Map) {
      for (final nested in const ['error', 'data']) {
        if (_retryableFlag(details[nested])) return true;
      }
    }
    return false;
  }

  static bool _retryableFlag(Object? node) =>
      node is Map && node['retryable'] == true;
}
