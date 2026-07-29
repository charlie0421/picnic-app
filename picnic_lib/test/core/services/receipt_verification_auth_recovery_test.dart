import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/services/auth/edge_auth_retry.dart';
import 'package:picnic_lib/core/services/receipt_verification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/mock_supabase.dart';

/// 실측 재현(스테이징 2026-07-28 04:24 UTC): 결제 시트에 머무는 동안 액세스
/// 토큰이 만료되면 verify_receipt 가 게이트웨이에서 401 로 거부되는데, 기존
/// 루프는 **같은 토큰으로 8회 재시도**만 반복했다 — 사용자는 스토어 성공
/// 팝업 뒤 무한 로딩을 봤다.
///
/// 이 파일이 고정하는 두 가지:
/// 1. 401 → 세션 갱신 → 재시도로 검증이 **성공**한다 (투표 경로와 동일 계약)
/// 2. 갱신 후에도 401 이면 백오프 루프에 붙잡지 않고 **즉시 실패**한다
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
    .where((u) => u.path.contains('/functions/v1/verify_receipt'))
    .length;

int _refreshCalls() => capturedMockRequests
    .where((u) =>
        u.path.contains('/auth/') &&
        u.queryParameters['grant_type'] == 'refresh_token')
    .length;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await setupMockSupabaseWithAuth({
      'functions:verify_receipt': _settlement(),
    }, userId: 'test-user-id');
    // 로그인/초기화 트래픽은 집계에서 제외한다.
    capturedMockRequests.clear();
  });

  tearDown(tearDownMockSupabase);

  group('receipt verification auth recovery', () {
    test('만료 토큰(401)이면 세션을 갱신해 재시도하고 성공한다', () async {
      functionStatusQueues['functions:verify_receipt'] = [401];

      final result = await ReceiptVerificationService().callVerificationFunction(
        _requestBody(),
        'test',
        SentVerificationRequests(),
      );

      expect(result.wallet.star, BigInt.from(100),
          reason: '갱신 후 재시도가 정산 결과를 돌려줘야 한다');
      expect(_verifyCalls(), 2,
          reason: '401 1회 + 갱신 후 재시도 1회 = 정확히 2회 전송');
      expect(_refreshCalls(), greaterThanOrEqualTo(1),
          reason: '401 을 받으면 refresh_token 갱신이 일어나야 한다');
    });

    test('갱신 후에도 401 이면 백오프 루프 없이 즉시 실패한다', () async {
      functionStatusQueues['functions:verify_receipt'] = [401, 401];

      await expectLater(
        ReceiptVerificationService().callVerificationFunction(
          _requestBody(),
          'test',
          SentVerificationRequests(),
        ),
        throwsA(isA<EdgeAuthRecoveryException>()),
      );

      // 기존 결함: 같은 토큰으로 sandbox 재시도 횟수만큼(8회+) 전송하며
      // 사용자를 백오프 루프에 붙잡아 뒀다. 이제 정확히 2회(401 + 갱신 후
      // 401)에서 끝나야 한다.
      expect(_verifyCalls(), 2,
          reason: '복구 불가 401 은 재시도 루프를 즉시 중단해야 한다');
    });

    test('401 이 아닌 실패는 auth 복구 없이 기존 재시도 규칙을 따른다', () async {
      // 500 은 갱신 대상이 아니다 — refresh_token 호출이 없어야 한다.
      functionStatusQueues['functions:verify_receipt'] = [500];

      final result = await ReceiptVerificationService().callVerificationFunction(
        _requestBody(),
        'test',
        SentVerificationRequests(),
      );

      expect(result.wallet.star, BigInt.from(100),
          reason: '500 후 기존 백오프 재시도로 성공해야 한다');
      expect(_refreshCalls(), 0,
          reason: '비-401 실패에 세션 갱신이 끼어들면 안 된다');
    });
  });
}
