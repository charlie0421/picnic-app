import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/services/receipt_verification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 클라이언트 영수증 큐의 재전송을 멈출지 판정하는 분류기.
///
/// 스토어 트랜잭션 파괴에는 쓰이지 않는다(그 판정은 존재하지 않는다 -
/// 미확정 구매는 종류 불문 보존). 잘못 true가 되면 큐 항목이 사라져
/// 클라이언트 재전송이 멈추지만 스토어측 재전달·reconcile 경로는 남고,
/// 잘못 false가 되면 결코 성공할 수 없는 영수증이 큐를 영원히 돈다.
void main() {
  FunctionException status(int code) =>
      FunctionException(status: code, details: null, reasonPhrase: 'test');

  test('only the explicit non-retryable verdict stops the client queue', () {
    expect(isPermanentSettlementRejection(status(422)), isTrue,
        reason: '422는 워커의 명시적 비재시도 판정에서만 나온다');
  });

  test('recoverable or ambiguous failures keep the transaction', () {
    for (final code in [400, 401, 403, 408, 409, 429, 500, 502, 503, 504]) {
      expect(isPermanentSettlementRejection(status(code)), isFalse,
          reason: 'HTTP $code - 400은 핸들러 catch-all이라 일시 오류가 섞이고, '
              '403은 레거시 서버가 IP 차단에도 반환하며, '
              '409는 grantConfirmed가 따로 판정하고, 나머지는 재시도 대상');
    }
  });

  test('non-HTTP failures keep the transaction', () {
    expect(isPermanentSettlementRejection(null), isFalse);
    expect(isPermanentSettlementRejection(Exception('network down')), isFalse);
    expect(
      isPermanentSettlementRejection(
        ReceiptResponseContractException(message: 'schema mismatch'),
      ),
      isFalse,
      reason: '계약 예외는 서버가 이미 정산한 상태 - 재전달 replay는 멱등이라 '
          '안전하고, 파서가 고쳐진 클라이언트가 나중에 소화할 수 있다',
    );
  });
}
