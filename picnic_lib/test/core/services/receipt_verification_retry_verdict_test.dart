import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/services/purchase_failure_classifier.dart';
import 'package:picnic_lib/core/services/receipt_verification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../helpers/mock_supabase.dart';

/// 검증 재시도 루프가 **무엇을 재시도하지 않는지**.
///
/// C-1 의 두 번째 절반. 서버는 503(재시도 가능)과 422(명시적 비재시도)를
/// 의도적으로 구분해서 돌려주는데, 클라이언트 루프는 그 구분을 쓰지 않고
/// 두 경우 모두 sandbox 5회 / production 3회를 백오프와 함께 돌렸다.
///
/// 422 를 재시도하는 것은 결과가 바뀌지 않는데도 사용자를 2초+4초 더
/// 붙잡아 두는 것이고, 그 사이 90초 안전망이 먼저 울려 "구매 처리 지연"
/// 팝업과 오류 다이얼로그가 겹친다.
///
/// fail-fast 가 안전한 이유는 이 루프가 아무것도 파괴하지 않기 때문이다:
/// 스토어 트랜잭션은 미확정으로 남고, 큐 항목 제거는 별개의(더 좁은)
/// 판정인 [isPermanentSettlementRejection](422 만)이 결정한다. 정말로 일시
/// 오류였던 400 은 다음 실행의 재전달·큐 플러시가 다시 시도한다.
Map<String, dynamic> _settlement() => {
      'contract_version': 'wallet.v1',
      'operation_id': '00000000-0000-4000-8000-000000000001',
      'replayed': false,
      'base_star_amount': '100',
      'base_bonus_amount': '20',
      'promotion': {
        'resolution_id': '00000000-0000-4000-8000-000000000002',
        'state': 'INELIGIBLE',
        'campaign_version_id': null,
        'promo_bonus_amount': '0',
        'domain_code': null,
      },
      'wallet': {
        'contract_version': 'wallet.v1',
        'star': '100',
        'bonus': '20',
        'cotton': '5',
        'cotton_expiring_amount': '5',
        'cotton_next_expires_at': null,
        'snapshot_at': '2026-07-21T00:00:00.000Z',
      },
    };

Map<String, dynamic> _requestBody() => {
      'platform': 'android',
      'receipt': 'test-receipt',
      'productId': 'STAR100',
      'userId': 'test-user-id',
      'environment': 'sandbox',
    };

int _verifyCalls() => capturedMockRequests
    .where((u) => u.path.contains('/functions/v1/verify-receipt-v2'))
    .length;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await setupMockSupabaseWithAuth({
      'functions:verify-receipt-v2': _settlement(),
    }, userId: 'test-user-id');
    capturedMockRequests.clear();
  });

  tearDown(tearDownMockSupabase);

  Future<Object?> failureFor(List<int> statuses) async {
    functionStatusQueues['functions:verify-receipt-v2'] = statuses;
    try {
      await ReceiptVerificationService().callVerificationFunction(
        _requestBody(),
        'test',
        SentVerificationRequests(),
      );
      return null;
    } catch (e) {
      return e;
    }
  }

  group('서버 판정 실패는 재시도 루프를 즉시 끝낸다', () {
    test('422 는 첫 응답에서 멈춘다', () async {
      final error = await failureFor([422]);

      expect(error, isA<FunctionException>());
      expect((error as FunctionException).status, 422);
      expect(_verifyCalls(), 1,
          reason: '예전에는 sandbox 재시도 횟수만큼(5회) 백오프와 함께 재전송했다 '
              '- 결과는 같고 사용자만 6초 이상 더 기다린다');
    });

    test('400 · 403 도 첫 응답에서 멈춘다', () async {
      for (final status in [400, 403]) {
        capturedMockRequests.clear();
        final error = await failureFor([status]);

        expect(error, isA<FunctionException>(), reason: 'HTTP $status');
        expect(_verifyCalls(), 1, reason: 'HTTP $status - 재시도 없음');
      }
    });

    test('영구 판정 집합이 분류기와 일치한다', () {
      expect(PurchaseFailureClassifier.permanentStatuses, {400, 403, 422});
    });
  });

  group('회복 가능한 실패는 종전대로 재시도한다', () {
    test('503 은 재시도해서 성공까지 간다', () async {
      final error = await failureFor([503]);

      expect(error, isNull, reason: '503 뒤 재시도가 정산을 받아와야 한다');
      expect(_verifyCalls(), 2,
          reason: '503 1회 + 재시도 1회. 503 을 영구 거부로 오판하면 회복 '
              '가능한 실패가 종결 실패가 된다');
    });
  });

  group('큐 제거 판정은 422 만 인정한다 (변경 없음)', () {
    // 재시도 중단 판정(400·403·422)과 큐 제거 판정(422)은 일부러 다르다.
    // 큐에서 잘못 지우면 클라이언트 재전송 경로가 사라지므로, 애매한
    // 400/403 은 큐에 남긴다.
    FunctionException status(int code) =>
        FunctionException(status: code, details: null, reasonPhrase: 'test');

    test('400 · 403 은 큐에서 제거되지 않는다', () {
      for (final code in [400, 403]) {
        expect(PurchaseFailureClassifier.isPermanentRejection(status(code)),
            isTrue,
            reason: 'HTTP $code - 재시도 루프는 멈춘다');
        expect(isPermanentSettlementRejection(status(code)), isFalse,
            reason: 'HTTP $code - 그래도 큐 항목은 남아야 재전송 경로가 유지된다');
      }
    });

    test('422 는 두 판정 모두 참이다', () {
      expect(
        PurchaseFailureClassifier.isPermanentRejection(status(422)),
        isTrue,
      );
      expect(isPermanentSettlementRejection(status(422)), isTrue);
    });

    test('503 은 두 판정 모두 거짓이다', () {
      expect(
        PurchaseFailureClassifier.isPermanentRejection(status(503)),
        isFalse,
      );
      expect(isPermanentSettlementRejection(status(503)), isFalse);
    });
  });
}
