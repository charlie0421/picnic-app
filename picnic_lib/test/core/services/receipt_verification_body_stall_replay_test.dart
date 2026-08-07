import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:picnic_lib/core/services/receipt_verification_service.dart';
import 'package:picnic_lib/core/utils/retry_http_client.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 본문 스톨 → 상위 replay 경로의 통합 고정.
///
/// RetryHttpClient 의 본문 inactivity 타임아웃이 도입되면서 명확해진 사실:
/// verify-receipt-v2 POST 의 본문이 헤더 이후 멈추면 NetworkError 가
/// FunctionsClient 의 본문 소비에서 던져지고, 이는 RetryHttpClient *내부*
/// 루프(비멱등 → attemptsAllowed 1)는 재진입하지 않지만
/// ReceiptVerificationService 의 catch-all 백오프에는 잡혀 같은 POST 가
/// 재전송된다(replay).
///
/// 이 replay 는 inactivity 타임아웃이 새로 만든 동작이 아니다. 도입 이전에도
/// 서비스는 invoke(...).timeout(prod 30s / sandbox 60s) 으로 본문 소비까지
/// 감싸고 있었으므로, 스톨은 TimeoutException 으로 표면화되어 같은 catch-all
/// 에서 재전송됐다 (receipt_verification_service.dart 의
/// `.timeout(timeoutDuration)` 및 purchase_constants.dart 참조). 달라진 것은
/// 예외 타입(NetworkError)과, sandbox 에서 더 일찍 실패할 수 있다는 점뿐이다.
///
/// replay 가 안전한 근거는 서비스 설계 자체에 있다:
///  - 같은 requestBody 가 바이트 단위로 동일하게 재전송된다 (이 테스트가 고정)
///  - 서버가 이미 정산한 경우 응답은 replayed: true 로 돌아오고, 클라이언트는
///    sentRequests.count > 0 이면 replayCausedByRetry 로 표시해 "응답만
///    유실된 자기 요청" 으로 처리한다 (이 테스트가 고정)
///  - 409 중복은 duplicateConfirmsGrant 로 지급 확정 여부를 판정한다
///
/// 실제 프로덕션 배선과 동일하게 SupabaseClient(httpClient: RetryHttpClient)
/// 를 사용한다. SupabaseClient 는 내부에서 AuthHttpClient 로 감싸므로 이
/// 테스트는 postgrest/functions → AuthHttpClient → BaseClient._sendUnstreamed
/// → RetryHttpClient.send() 라는 실경로를 그대로 지난다.
Map<String, dynamic> _settlement({required bool replayed}) => {
      'contract_version': 'wallet.v1',
      'operation_id': '00000000-0000-4000-8000-000000000001',
      'replayed': replayed,
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
      'receipt': 'stall-replay-receipt',
      'productId': 'STAR100',
      'userId': 'test-user-id',
      'environment': 'sandbox',
      'clientTraceId': 'trace-00000000-0000-4000-8000-00000000cafe',
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<String> verifyPostBodies;
  late RetryHttpClient retryClient;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    verifyPostBodies = [];

    final streamingMock = MockClient.streaming((request, bodyStream) async {
      final body = await bodyStream.bytesToString();
      if (!request.url.path.contains('/functions/v1/verify-receipt-v2')) {
        return http.StreamedResponse(
          Stream.value(utf8.encode('{}')),
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }

      verifyPostBodies.add(body);
      if (verifyPostBodies.length == 1) {
        // 1차 시도: 헤더 200 + 부분 JSON 뒤 본문이 영원히 멈춘다.
        final stalled = StreamController<List<int>>();
        stalled.add(utf8.encode('{"contract_version":'));
        return http.StreamedResponse(
          stalled.stream,
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }
      // 2차 시도: 서버는 1차에서 이미 정산했다고 가정 → replayed: true.
      final bytes = utf8.encode(jsonEncode(_settlement(replayed: true)));
      return http.StreamedResponse(
        Stream.value(bytes),
        200,
        contentLength: bytes.length,
        headers: {'content-type': 'application/json'},
        request: request,
      );
    });

    retryClient = RetryHttpClient(
      streamingMock,
      bodyInactivityTimeout: const Duration(milliseconds: 200),
    );
    testSupabaseClient = SupabaseClient(
      'http://localhost:54321',
      'test-anon-key-for-testing-purposes-only',
      httpClient: retryClient,
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
  });

  tearDown(() {
    testSupabaseClient = null;
    retryClient.close();
  });

  test(
      '본문 스톨은 서비스 백오프로 동일 POST 를 재전송하고, replay 응답은 '
      'replayCausedByRetry 로 안전하게 흡수된다', () async {
    final settlement = await ReceiptVerificationService()
        .callVerificationFunction(
      _requestBody(),
      'stall-replay',
      SentVerificationRequests(),
    );

    expect(verifyPostBodies.length, 2,
        reason: '스톨된 1차 POST 의 NetworkError 는 RetryHttpClient 내부에서는 '
            '재시도되지 않지만(비멱등), ReceiptVerificationService 의 '
            'catch-all 백오프가 재전송한다 — 이것이 실제 전역 동작이다');
    expect(verifyPostBodies[1], verifyPostBodies[0],
        reason: 'replay 는 동일 receipt·clientTraceId 를 바이트 단위로 '
            '동일하게 재전송해야 서버 멱등성이 성립한다');
    expect(settlement.replayed, isTrue);
    expect(settlement.replayCausedByRetry, isTrue,
        reason: 'sentRequests.count > 0 이므로 이 replay 는 "앞선 요청이 '
            '정산되고 응답만 유실된" 자기 요청으로 판정되어야 한다');
  });

  test('스톨 없이 첫 응답이 완결되면 재전송도 replay 표시도 없다', () async {
    // 위 테스트의 대조군: 2차 응답 픽스처를 1차부터 쓰도록 스톨 카운터를
    // 소진시킬 수 없으므로, 같은 배선을 새로 만들어 정상 응답만 준다.
    final bodies = <String>[];
    final healthyMock = MockClient.streaming((request, bodyStream) async {
      final body = await bodyStream.bytesToString();
      if (request.url.path.contains('/functions/v1/verify-receipt-v2')) {
        bodies.add(body);
      }
      final bytes = utf8.encode(jsonEncode(_settlement(replayed: false)));
      return http.StreamedResponse(
        Stream.value(bytes),
        200,
        contentLength: bytes.length,
        headers: {'content-type': 'application/json'},
        request: request,
      );
    });
    final healthyRetry = RetryHttpClient(
      healthyMock,
      bodyInactivityTimeout: const Duration(milliseconds: 200),
    );
    testSupabaseClient = SupabaseClient(
      'http://localhost:54321',
      'test-anon-key-for-testing-purposes-only',
      httpClient: healthyRetry,
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );

    final settlement = await ReceiptVerificationService()
        .callVerificationFunction(
      _requestBody(),
      'healthy',
      SentVerificationRequests(),
    );

    expect(bodies.length, 1);
    expect(settlement.replayed, isFalse);
    expect(settlement.replayCausedByRetry, isFalse);
    healthyRetry.close();
  });
}
