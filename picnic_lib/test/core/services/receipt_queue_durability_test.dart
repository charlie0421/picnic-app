import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:picnic_lib/core/constants/purchase_constants.dart';
import 'package:picnic_lib/core/services/receipt_queue_service.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 영수증 큐의 durability 계약을 고정한다.
///
/// 공유 하네스(mock_supabase.dart)는 요청 **본문**을 기록하지 않고 응답을
/// 붙잡아 둘 수도 없어서, 이 파일은 verify-receipt-v2 호출을 직접 게이팅하는
/// MockClient 를 쓴다. 그래야 다음 두 결함을 회귀 테스트로 못 박을 수 있다:
///
/// - **C-2 lost update**: 과거 `flushPending` 은 큐 전체를 스냅샷한 뒤
///   invoke 를 기다리고, 끝나면 스냅샷을 통째로 되썼다. 그 사이 적재된
///   항목(=이미 과금된 구매의 유일한 durable 기록)은 조용히 소멸했다.
/// - **C-3 iOS durability**: iOS 검증은 큐 항목을 만들지 않아서, 검증이
///   중단되면 클라이언트에 아무 기록도 남지 않았다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const spKey = 'receipt_queue_v1';

  late ReceiptQueueService service;
  late List<Map<String, dynamic>> sentBodies;
  late Future<http.Response> Function() nextResponse;

  http.Response jsonResponse(Object body, int status) => http.Response(
    jsonEncode(body),
    status,
    headers: const {'content-type': 'application/json'},
  );

  http.Response legacySuccess() => jsonResponse({'success': true}, 200);

  /// 실제 계약을 만족하는 정산 응답.
  ///
  /// 큐는 이제 200 wallet.v1 응답을 파싱해 analytics 로 넘긴 뒤에만 항목을
  /// 제거하므로, 파싱되지 않는 축약 스텁으로는 "정상 성공" 경로를 표현할 수
  /// 없다. (파싱 실패 자체의 동작은 receipt_queue_revenue_handoff_test 가
  /// 따로 고정한다.)
  http.Response walletSettlement() => jsonResponse({
    'contract_version': 'wallet.v1',
    'operation_id': '00000000-0000-4000-8000-000000000001',
    'replayed': false,
    'base_star_amount': '100',
    'base_bonus_amount': '0',
    'promotion': <String, dynamic>{
      'resolution_id': '00000000-0000-4000-8000-000000000611',
      'state': 'ELIGIBLE',
      'campaign_version_id': null,
      'promo_bonus_amount': '0',
      'domain_code': null,
    },
    'wallet': <String, dynamic>{
      'contract_version': 'wallet.v1',
      'star': '100',
      'bonus': '0',
      'cotton': '0',
      'cotton_expiring_amount': '0',
      'cotton_next_expires_at': null,
      'snapshot_at': '2026-08-24T00:00:00.000Z',
    },
  }, 200);

  /// StoreKit2 JWS 모양의 가짜 영수증(서명 검증은 서버 몫이므로 형식만 맞춘다).
  String storeKit2Jws({required String transactionId}) {
    String segment(Map<String, dynamic> value) =>
        base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
    return '${segment({'alg': 'ES256', 'typ': 'JWT'})}'
        '.${segment({
          'transactionId': transactionId,
          'productId': 'STAR100',
          'signedDate': 1700000000000,
        })}'
        '.${segment({'sig': 'not-verified-here'})}';
  }

  Future<List<Map<String, dynamic>>> queue() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(spKey);
    if (raw == null || raw.isEmpty) return <Map<String, dynamic>>[];
    return (json.decode(raw) as List).cast<Map<String, dynamic>>();
  }

  Future<void> writeQueue(List<Map<String, dynamic>> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(spKey, json.encode(items));
  }

  /// 백오프로 미래로 밀린 `nextAt` 을 되돌려 다음 플러시가 즉시 전송하게 한다.
  Future<void> clearBackoff() async {
    final items = await queue();
    for (final item in items) {
      item['nextAt'] = 0;
    }
    await writeQueue(items);
  }

  Future<void> pumpUntil(
    bool Function() condition, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (!condition()) {
      if (DateTime.now().isAfter(deadline)) {
        fail('조건이 ${timeout.inMilliseconds}ms 안에 만족되지 않았다');
      }
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
  }

  Future<String> enqueueAndroidItem({String receipt = 'android-receipt'}) =>
      service.enqueue(
        platform: ReceiptQueueService.platformAndroid,
        receipt: receipt,
        productId: 'STAR100',
        userId: 'test-user',
        environment: 'sandbox',
      );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    sentBodies = <Map<String, dynamic>>[];
    nextResponse = () async => legacySuccess();

    final client = MockClient((request) async {
      if (request.url.path.contains('/functions/v1/')) {
        sentBodies.add(json.decode(request.body) as Map<String, dynamic>);
        return nextResponse();
      }
      return jsonResponse(const <String, dynamic>{}, 200);
    });
    testSupabaseClient = SupabaseClient(
      'http://localhost:54321',
      'test-anon-key-for-testing-purposes-only',
      httpClient: client,
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );

    service = ReceiptQueueService();
    // 싱글턴이라 테스트 간 상태가 새지 않게 프로덕션 기본값으로 되돌린다.
    service.flushInvokeTimeout = PurchaseConstants.verificationTimeout;
    // 이 파일은 큐의 durability 기계 자체를 본다. 매출 인계는 항상 성공한
    // 것으로 두어야 "정상 성공 뒤 큐가 비는가" 를 그대로 관찰할 수 있다.
    service.onSettlementRecovered =
        (
          settlement, {
          required String storeProductId,
          required String? clientObservedCurrency,
        }) async => true;
  });

  tearDown(() {
    service.onSettlementRecovered = null;
    testSupabaseClient = null;
  });

  group('C-2 플러시 중 적재 (lost update)', () {
    test('invoke 를 기다리는 동안 적재된 항목이 살아남는다', () async {
      final gate = Completer<http.Response>();
      nextResponse = () => gate.future;

      final firstTrace = await enqueueAndroidItem(receipt: 'receipt-1');

      final flush = service.flushPending();
      await pumpUntil(() => sentBodies.isNotEmpty);

      // 여기서 새 구매가 결제되고 검증 직전에 큐로 들어온다.
      final lateTrace = await service.enqueue(
        platform: ReceiptQueueService.platformAndroid,
        receipt: 'receipt-2',
        productId: 'STAR200',
        userId: 'test-user',
        environment: 'sandbox',
      );

      gate.complete(walletSettlement());
      await flush;

      final remaining = await queue();
      expect(
        remaining.map((e) => e['client_trace_id']),
        [lateTrace],
        reason: '성공한 항목만 사라지고, 대기 중 적재된 항목은 남아야 한다',
      );
      expect(remaining.single['productId'], 'STAR200');
      expect(remaining.single['attempt'], 0, reason: '이번 플러시 대상이 아니었다');
      expect(firstTrace, isNot(lateTrace));
    });

    test('동시 플러시는 single-flight 로 합쳐져 한 번만 전송한다', () async {
      final gate = Completer<http.Response>();
      nextResponse = () => gate.future;

      await enqueueAndroidItem();

      final first = service.flushPending();
      final second = service.flushPending();
      await pumpUntil(() => sentBodies.isNotEmpty);

      gate.complete(walletSettlement());
      await Future.wait<void>([first, second]);

      expect(
        sentBodies.length,
        1,
        reason: '두 플러시가 교차하면 같은 영수증을 중복 전송하고 서로의 스냅샷을 덮어쓴다',
      );
      expect(await queue(), isEmpty);
    });

    test('플러시가 끝나면 게이트가 풀려 다음 플러시가 다시 돈다', () async {
      await enqueueAndroidItem();

      await service.flushPending();
      expect(await queue(), isEmpty);

      await enqueueAndroidItem(receipt: 'receipt-2');
      await service.flushPending();

      expect(sentBodies.length, 2);
      expect(await queue(), isEmpty);
    });
  });

  group('C-2 invoke 타임아웃', () {
    test('응답이 오지 않으면 타임아웃되고 항목은 백오프로 유지된다', () async {
      service.flushInvokeTimeout = const Duration(milliseconds: 80);
      // 영원히 응답하지 않는 서버.
      nextResponse = () => Completer<http.Response>().future;

      await enqueueAndroidItem();

      // 타임아웃이 없으면 이 await 는 영원히 돌아오지 않는다.
      await service.flushPending().timeout(
        const Duration(seconds: 5),
        onTimeout: () => fail('flushPending 이 타임아웃 없이 매달렸다'),
      );

      final items = await queue();
      expect(items.length, 1, reason: '타임아웃은 영구 거부가 아니다 - 유지');
      expect(items.single['attempt'], 1);
      expect(
        items.single['nextAt'],
        greaterThan(DateTime.now().millisecondsSinceEpoch),
      );
    });

    test('타임아웃 이후에도 다음 플러시가 정상 동작한다', () async {
      service.flushInvokeTimeout = const Duration(milliseconds: 80);
      nextResponse = () => Completer<http.Response>().future;

      await enqueueAndroidItem();
      await service.flushPending().timeout(const Duration(seconds: 5));

      // single-flight 게이트가 매달린 future 에 고정되면 큐는 영구 정지한다.
      nextResponse = () async => walletSettlement();
      await clearBackoff();
      await service.flushPending().timeout(const Duration(seconds: 5));

      expect(await queue(), isEmpty);
    });
  });

  group('C-2 제거 조건 (422 만 영구 거부)', () {
    Future<void> flushWith(int status, Map<String, dynamic> body) async {
      nextResponse = () async => jsonResponse(body, status);
      await enqueueAndroidItem();
      await service.flushPending();
    }

    test('422 는 항목을 제거한다 (서버의 명시적 비재시도 판정)', () async {
      await flushWith(422, {
        'error': 'PURCHASE_PROOF_REJECTED',
        'retryable': false,
        'operation_id': '00000000-0000-4000-8000-000000000001',
      });

      expect(await queue(), isEmpty);
    });

    test('503 은 항목을 유지한다 (전송 재시도 가능)', () async {
      await flushWith(503, {
        'error': 'PURCHASE_RESULT_UNAVAILABLE',
        'retryable': true,
      });

      final items = await queue();
      expect(items.length, 1);
      expect(items.single['attempt'], 1);
      expect(
        items.single['nextAt'],
        greaterThan(DateTime.now().millisecondsSinceEpoch),
      );
    });

    // 아래 두 응답 모양은 verify-receipt-v2 가 반환하지 않는다(엔진 grep 0건).
    // 죽은 "제거" 분기를 지웠으므로 이제 정체 불명의 실패 = 유지 + 백오프다.
    test('409 DUPLICATE_RECEIPT 는 제거 신호가 아니다', () async {
      await flushWith(409, {
        'success': false,
        'code': 'DUPLICATE_RECEIPT',
        'message': '이미 처리된 구매입니다.',
        'grant_confirmed': true,
      });

      final items = await queue();
      expect(items.length, 1, reason: '지급 확정 문구여도 큐에서 지우지 않는다');
      expect(items.single['attempt'], 1);
    });

    test('400 PURCHASE_CANCELED 는 제거 신호가 아니다', () async {
      await flushWith(400, {
        'success': false,
        'code': 'PURCHASE_CANCELED',
        'message': '취소된 구매입니다.',
      });

      final items = await queue();
      expect(items.length, 1);
      expect(items.single['attempt'], 1);
    });
  });

  group('C-3 iOS durable 큐 항목', () {
    test('iOS 항목은 transactionId 키로 적재되고 iOS 본문으로 재전송된다', () async {
      nextResponse = () async => walletSettlement();
      final receipt = storeKit2Jws(transactionId: '2000000123456789');

      final traceId = await service.enqueue(
        platform: ReceiptQueueService.platformIOS,
        receipt: receipt,
        productId: 'STAR100',
        userId: 'test-user',
        environment: 'production',
      );

      expect(traceId, 'ios-2000000123456789');
      final queued = await queue();
      expect(queued.single['platform'], 'ios');
      expect(queued.single['format'], 'storekit2_jwt');

      await service.flushPending();

      final body = sentBodies.single;
      expect(body['platform'], 'ios');
      expect(
        body['format'],
        'storekit2_jwt',
        reason: '과거 플러시는 iOS 항목에도 google_play 를 붙였다',
      );
      expect(body['format'], isNot('google_play'));
      expect(body['receipt'], receipt);
      expect(body['productId'], 'STAR100');
      expect(body['user_id'], 'test-user');
      expect(body['environment'], 'production');
      expect(body['client_trace_id'], traceId);
      expect(await queue(), isEmpty, reason: '정산 성공 시 제거');
    });

    test('같은 transactionId 를 다시 적재해도 큐가 늘지 않는다', () async {
      final receipt = storeKit2Jws(transactionId: '2000000999');

      final first = await service.enqueue(
        platform: ReceiptQueueService.platformIOS,
        receipt: receipt,
        productId: 'STAR100',
        userId: 'test-user',
        environment: 'production',
      );
      final second = await service.enqueue(
        platform: ReceiptQueueService.platformIOS,
        receipt: receipt,
        productId: 'STAR100',
        userId: 'test-user',
        environment: 'production',
      );

      expect(second, first);
      expect(
        (await queue()).length,
        1,
        reason: '미완료 StoreKit 트랜잭션은 앱 실행마다 재전달된다',
      );
    });

    test('JWS 를 파싱할 수 없으면 난수 iOS 키로 폴백한다', () async {
      final traceId = await service.enqueue(
        platform: ReceiptQueueService.platformIOS,
        receipt: 'not-a-jws',
        productId: 'STAR100',
        userId: 'test-user',
        environment: 'production',
      );

      expect(traceId, startsWith('ios-'));
      expect(ReceiptQueueService.iosClientTraceId('not-a-jws'), isNull);
      expect((await queue()).single['format'], 'legacy');
    });

    test('Android 항목은 google_play format 을 유지한다', () async {
      nextResponse = () async => walletSettlement();
      await enqueueAndroidItem();

      await service.flushPending();

      expect(sentBodies.single['platform'], 'android');
      expect(sentBodies.single['format'], 'google_play');
    });

    test('platform/format 이 없는 옛 항목은 android 로 해석된다', () async {
      nextResponse = () async => walletSettlement();
      await writeQueue([
        {
          'client_trace_id': 'android-legacy-entry',
          'receipt': 'legacy-receipt',
          'productId': 'STAR100',
          'user_id': 'test-user',
          'environment': 'sandbox',
          'attempt': 0,
          'nextAt': 0,
        },
      ]);

      await service.flushPending();

      expect(sentBodies.single['platform'], 'android');
      expect(sentBodies.single['format'], 'google_play');
      expect(await queue(), isEmpty);
    });

    test('buildQueuedRequestBody 는 저장된 format 을 그대로 쓴다', () {
      final body = ReceiptQueueService.buildQueuedRequestBody({
        'client_trace_id': 'ios-1',
        'receipt': 'eyJ.payload.sig',
        'productId': 'STAR100',
        'user_id': 'u',
        'environment': 'production',
        'platform': 'ios',
        'format': 'legacy',
      });

      expect(body['platform'], 'ios');
      expect(body['format'], 'legacy');
    });
  });
}
