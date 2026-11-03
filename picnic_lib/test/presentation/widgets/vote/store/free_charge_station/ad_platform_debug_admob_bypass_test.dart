import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/ad_platform.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 큐에 든 응답을 순서대로 반환하는 가짜 `check-ads-count` 서버.
///
/// 실제 [SupabaseClient] + [FunctionsClient] 배선을 그대로 타므로(목은
/// http 전송 계층에만 있다) 요청 URL/쿼리 파라미터를 그대로 검증할 수 있다
/// (vote_item_request_repository_test.dart 의 `_edgeFnClient` 패턴을 따름).
class _QueuedResponse {
  const _QueuedResponse({this.status = 200, this.body});

  final int status;
  final Map<String, dynamic>? body;
}

SupabaseClient _queueingClient(
  List<_QueuedResponse> queue,
  List<http.Request> capturedRequests,
) {
  var callIndex = 0;
  final mock = MockClient((req) async {
    capturedRequests.add(req);
    if (callIndex >= queue.length) {
      throw StateError('예상보다 많은 요청 (#${callIndex + 1}): ${req.url}');
    }
    final queued = queue[callIndex];
    callIndex++;
    return http.Response(
      jsonEncode(queued.body ?? const {}),
      queued.status,
      headers: {'content-type': 'application/json'},
    );
  });
  return SupabaseClient(
    'http://localhost:54321',
    'test-anon-key',
    httpClient: mock,
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  );
}

/// [AdPlatform.shouldBypassDisabledForDebugAdmob] 는 G3 준비 작업으로 추가된
/// "kDebugMode + admob 한정으로 서버 disabled 플래그를 우회" predicate 다.
///
/// 실제 `checkAdsLimit()` 는 BuildContext/Supabase 의존성 때문에 여기서 직접
/// 호출할 수 없으므로, 게이팅 조건만 순수 함수로 분리해 실제 구현을 그대로
/// 검증한다 (PICNIC-2377: 로직을 복제한 mirror 테스트는 구현이 바뀌어도 계속
/// 통과하므로 반드시 실제 구현을 호출해야 한다 — ad_platform_logic_test.dart 참고).
void main() {
  group('AdPlatform.shouldBypassDisabledForDebugAdmob', () {
    test('kDebugMode 이고 platform 이 admob 이면 true', () {
      expect(
        AdPlatform.shouldBypassDisabledForDebugAdmob(
          isDebugMode: true,
          platform: 'admob',
        ),
        isTrue,
      );
    });

    test('kDebugMode 이지만 platform 이 admob 이 아니면 false (다른 플랫폼은 보호됨)', () {
      for (final platform in [
        'pangle',
        'tapjoy',
        'pincrux',
        'internal-shortform',
      ]) {
        expect(
          AdPlatform.shouldBypassDisabledForDebugAdmob(
            isDebugMode: true,
            platform: platform,
          ),
          isFalse,
          reason: '$platform 은 우회 대상이 아니다',
        );
      }
    });

    test('platform 이 admob 이어도 kDebugMode 가 아니면 false (release 안전장치)', () {
      expect(
        AdPlatform.shouldBypassDisabledForDebugAdmob(
          isDebugMode: false,
          platform: 'admob',
        ),
        isFalse,
      );
    });

    test('대소문자가 다른 "AdMob" 은 매치하지 않는다 (플랫폼 id 는 항상 소문자 admob)', () {
      expect(
        AdPlatform.shouldBypassDisabledForDebugAdmob(
          isDebugMode: true,
          platform: 'AdMob',
        ),
        isFalse,
      );
    });

    test('둘 다 아니면 false', () {
      expect(
        AdPlatform.shouldBypassDisabledForDebugAdmob(
          isDebugMode: false,
          platform: 'pangle',
        ),
        isFalse,
      );
    });
  });

  /// [AdPlatform.resolveAdsCountData] 는 실제 `check-ads-count` 요청/응답
  /// 시퀀스를 결정하는 seam 이다 (PICNIC-2377 리뷰 지적: predicate 만 테스트하면
  /// "disabled 를 건너뛰어도 1차 응답의 allowed:false 때문에 여전히 막힌다"는
  /// 실제 버그를 잡지 못한다). BuildContext 없이 순수 네트워크 계층만 다루므로
  /// testSupabaseClient 로 실제 request/response 왕복을 검증한다.
  group('AdPlatform.resolveAdsCountData', () {
    tearDown(() {
      testSupabaseClient = null;
    });

    test('debug+admob 이고 1차(os 포함) 응답이 disabled:true 면, '
        'os 없이 정확히 1회 재요청하고 2차 응답을 그대로 반환한다', () async {
      final requests = <http.Request>[];
      testSupabaseClient = _queueingClient([
        const _QueuedResponse(body: {'allowed': false, 'disabled': true}),
        const _QueuedResponse(
          body: {'allowed': true, 'source': 'second-response'},
        ),
      ], requests);

      final result = await AdPlatform.resolveAdsCountData(
        platform: 'admob',
        os: 'android',
        isDebugMode: true,
      );

      expect(requests, hasLength(2), reason: '정확히 2회(1차 + 재요청 1회)만 요청해야 한다');
      expect(requests[0].url.queryParameters['platform'], 'admob');
      expect(
        requests[0].url.queryParameters['os'],
        'android',
        reason: '1차 요청은 os 파라미터를 포함해야 한다',
      );
      expect(
        requests[1].url.queryParameters['platform'],
        'admob',
        reason: '재요청도 같은 platform 이어야 한다',
      );
      expect(
        requests[1].url.queryParameters.containsKey('os'),
        isFalse,
        reason: '재요청은 os 파라미터를 포함하면 안 된다',
      );

      // 최종 반환값이 1차(allowed:false) 가 아니라 2차 응답 그대로여야 한다.
      expect(result['allowed'], isTrue);
      expect(result['source'], 'second-response');
      expect(
        result.containsKey('disabled'),
        isFalse,
        reason: '2차 응답에 없던 필드(1차의 disabled)가 섞여 들어오면 안 된다',
      );
    });

    test('2차 응답도 disabled:true 이면 그 데이터를 그대로 반환하고 '
        '재귀적으로 3번째 요청을 보내지 않는다 ("정확히 한 번" 재요청)', () async {
      final requests = <http.Request>[];
      testSupabaseClient = _queueingClient([
        const _QueuedResponse(body: {'allowed': false, 'disabled': true}),
        const _QueuedResponse(body: {'allowed': false, 'disabled': true}),
      ], requests);

      final result = await AdPlatform.resolveAdsCountData(
        platform: 'admob',
        os: 'ios',
        isDebugMode: true,
      );

      expect(requests, hasLength(2), reason: '3번째 요청이 발생하면 안 된다');
      expect(result['disabled'], isTrue);
      expect(result['allowed'], isFalse);
    });

    test('2차 응답이 allowed:false + limits/nextAvailableTime 이면 '
        '그 값을 그대로 반환한다 (rate limit 정보가 정상 전달)', () async {
      final requests = <http.Request>[];
      testSupabaseClient = _queueingClient([
        const _QueuedResponse(body: {'allowed': false, 'disabled': true}),
        const _QueuedResponse(
          body: {
            'allowed': false,
            'disabled': false,
            'limits': {
              'admob': {'hourly': 3, 'daily': 9},
            },
            'nextAvailableTime': '2026-08-25T00:00:00.000Z',
          },
        ),
      ], requests);

      final result = await AdPlatform.resolveAdsCountData(
        platform: 'admob',
        os: 'android',
        isDebugMode: true,
      );

      expect(requests, hasLength(2));
      expect(result['allowed'], isFalse);
      expect(result['disabled'], isFalse);
      expect((result['limits'] as Map)['admob'], {'hourly': 3, 'daily': 9});
      expect(result['nextAvailableTime'], '2026-08-25T00:00:00.000Z');
    });

    test('1차 응답이 disabled:true 가 아니면(정상 응답) 재요청 없이 '
        '1차 데이터를 그대로 반환한다 (기존 동작 유지)', () async {
      final requests = <http.Request>[];
      testSupabaseClient = _queueingClient([
        const _QueuedResponse(body: {'allowed': true, 'disabled': false}),
      ], requests);

      final result = await AdPlatform.resolveAdsCountData(
        platform: 'admob',
        os: 'android',
        isDebugMode: true,
      );

      expect(requests, hasLength(1), reason: '비활성화가 아니면 재요청하면 안 된다');
      expect(result['allowed'], isTrue);
    });

    test('release(kDebugMode:false) 에서는 admob 이 disabled:true 여도 '
        '재요청하지 않는다 (release 안전장치)', () async {
      final requests = <http.Request>[];
      testSupabaseClient = _queueingClient([
        const _QueuedResponse(body: {'allowed': false, 'disabled': true}),
      ], requests);

      final result = await AdPlatform.resolveAdsCountData(
        platform: 'admob',
        os: 'android',
        isDebugMode: false,
      );

      expect(requests, hasLength(1));
      expect(result['disabled'], isTrue);
      expect(result['allowed'], isFalse);
    });

    test('admob 이 아닌 platform 은 kDebugMode:true 여도 disabled:true 면 '
        '재요청하지 않는다 (다른 플랫폼은 보호됨)', () async {
      final requests = <http.Request>[];
      testSupabaseClient = _queueingClient([
        const _QueuedResponse(body: {'allowed': false, 'disabled': true}),
      ], requests);

      final result = await AdPlatform.resolveAdsCountData(
        platform: 'pangle',
        os: 'android',
        isDebugMode: true,
      );

      expect(requests, hasLength(1));
      expect(requests[0].url.queryParameters['platform'], 'pangle');
      expect(result['disabled'], isTrue);
    });

    test('재요청(2차) 이 네트워크/서버 오류를 반환하면 그대로 전파한다 '
        '(에러 응답도 정상 케이스와 동일하게 상위 catch 로 흐른다)', () async {
      final requests = <http.Request>[];
      testSupabaseClient = _queueingClient([
        const _QueuedResponse(body: {'allowed': false, 'disabled': true}),
        const _QueuedResponse(status: 500, body: {'error': 'boom'}),
      ], requests);

      await expectLater(
        AdPlatform.resolveAdsCountData(
          platform: 'admob',
          os: 'android',
          isDebugMode: true,
        ),
        throwsA(isA<FunctionException>()),
      );

      expect(
        requests,
        hasLength(2),
        reason: '2차 요청은 실제로 시도되어야 한다(그 응답이 에러일 뿐)',
      );
    });
  });
}
