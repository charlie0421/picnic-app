import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/free_charge_station.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/store_list_tile.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../helpers/ignore_image_errors.dart';
import '../../../../../helpers/test_app.dart';

/// [shouldShowDebugAdmobItem] 자체는 이미 pure predicate 로 커버되지만, 그것만으로는
/// `_buildAdItems`(private, `_FreeChargeStationState`) 가 실제로 predicate 를
/// 올바른 인자로 호출해 정확히 1개만 추가하는지, onPressed 가 올바른 플랫폼으로
/// 배선되는지는 증명하지 못한다 — 그 통합 지점은 predicate 밖에 있다.
/// `_buildAdItems` 는 Dart 라이브러리 프라이빗이라 직접 호출할 수 없으므로,
/// 공개 위젯 [FreeChargeStation] 을 실제로 pump 해서 렌더된 트리로 검증한다
/// (free_charge_station_test.dart 가 이미 쓰는 buildTestApp/pumpWidgetAndIgnoreErrors
/// 하네스를 그대로 따름 — mirror 재구현이 아니다).
Map<String, dynamic> _envConfig({required bool includeAdmob}) => {
  'storage': {
    'cdn_url': 'https://test-cdn.example.com',
    'aws': {
      'access_key_id': 'test',
      'secret_access_key': 'test',
      'region': 'ap-northeast-2',
      's3_bucket': 'test',
      's3_bucket_url': 'https://test-s3.example.com',
    },
  },
  'logging': {
    'level': 'off',
    'image_load_warning_threshold_seconds': 10,
    'image_load_error_threshold_seconds': 20,
  },
  'app': {
    'web_domain': 'test.example.com',
    'download_link': 'https://test.example.com',
    'app_link_prefix': 'https://test.example.com',
    'inapp_appname_prefix': 'test',
  },
  'supabase': {
    'url': 'https://test.supabase.co',
    'anon_key': 'test-anon-key',
    'storage': {
      'url': 'https://test-storage.supabase.co',
      'anon_key': 'test-storage-anon-key',
    },
  },
  'ads': {
    'tapjoy': {
      'android_sdk_key': 'test-tapjoy-android',
      'ios_sdk_key': 'test-tapjoy-ios',
    },
    'pincrux': {
      'android_app_key': 'test-pincrux-android',
      'ios_app_key': 'test-pincrux-ios',
    },
    if (includeAdmob)
      'admob': {
        'ios_rewarded_video_id': 'test-admob-ios',
        'android_rewarded_video_id': 'test-admob-android',
      },
  },
};

class _QueuedResponse {
  const _QueuedResponse({this.body});

  final Map<String, dynamic>? body;
}

SupabaseClient _queueingClient(
  List<_QueuedResponse> queue,
  List<http.Request> capturedRequests,
) {
  var callIndex = 0;
  final mock = MockClient((req) async {
    capturedRequests.add(req);
    final queued = callIndex < queue.length ? queue[callIndex] : queue.last;
    callIndex++;
    return http.Response(
      jsonEncode(queued.body ?? const {}),
      200,
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

/// [shouldShowDebugAdmobItem] 은 G3 준비 작업으로 kDebugMode 전용으로 복원한
/// AdMob 무료충전소 구좌의 노출 여부를 결정하는 순수 predicate 다.
///
/// 실제 구현을 그대로 호출한다 — 로직을 복제한 mirror 테스트는 구현이 바뀌어도
/// 계속 통과하므로 아무것도 지키지 못한다 (이 파일 다른 로직 테스트에서 이미
/// 겪은 문제).
void main() {
  group('shouldShowDebugAdmobItem', () {
    test('kDebugMode 이고 admob 플랫폼이 사용 가능하면 true', () {
      expect(
        shouldShowDebugAdmobItem(isDebugMode: true, isAdmobAvailable: true),
        isTrue,
      );
    });

    test('kDebugMode 이지만 admob 플랫폼이 사용 불가능하면 false', () {
      expect(
        shouldShowDebugAdmobItem(isDebugMode: true, isAdmobAvailable: false),
        isFalse,
      );
    });

    test('릴리스 모드에서도 admob 플랫폼이 사용 가능하면 true', () {
      expect(
        shouldShowDebugAdmobItem(isDebugMode: false, isAdmobAvailable: true),
        isTrue,
      );
    });

    test('둘 다 아니면 false', () {
      expect(
        shouldShowDebugAdmobItem(isDebugMode: false, isAdmobAvailable: false),
        isFalse,
      );
    });
  });

  group('FreeChargeStation 실제 위젯 트리 — _buildAdItems 조립 검증', () {
    tearDown(() {
      testSupabaseClient = null;
    });

    testWidgets('admob 설정이 있으면(kDebugMode 는 테스트 프로세스에서 항상 true) '
        'AdMob 구좌가 정확히 1개만 추가된다(중복 추가 회귀 방지)', (tester) async {
      Environment.initTestConfig(_envConfig(includeAdmob: true));
      initTestEnvironment();
      final restoreImages = suppressImageErrors();
      addTearDown(restoreImages);

      await pumpWidgetAndIgnoreErrors(
        tester,
        buildTestApp(const FreeChargeStation(), loggedIn: true),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester);

      // 광고 목록의 글로벌 픽 순서: admob(#1) → internal-shortform(#2).
      final admobItem = find.byKey(const ValueKey('free-charge-admob'));
      expect(admobItem, findsOneWidget, reason: 'AdMob 구좌가 정확히 1개 렌더링되어야 한다');
      expect(
        find.descendant(of: admobItem, matching: find.text('글로벌 픽 #1')),
        findsOneWidget,
        reason: 'AdMob 구좌가 첫 번째 글로벌 픽이어야 한다',
      );
      expect(
        find.text('글로벌 픽 #3'),
        findsNothing,
        reason: '중복 추가로 세 번째 글로벌 픽 구좌가 생기면 안 된다',
      );
    });

    testWidgets('admob 설정이 없으면 AdMob 구좌가 렌더링되지 않는다 '
        '(운영 롤아웃 전 노출 사고 방지 — predicate 가 아니라 실제 조립 경로로 검증)', (tester) async {
      Environment.initTestConfig(_envConfig(includeAdmob: false));
      initTestEnvironment();
      final restoreImages = suppressImageErrors();
      addTearDown(restoreImages);

      await pumpWidgetAndIgnoreErrors(
        tester,
        buildTestApp(const FreeChargeStation(), loggedIn: true),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester);

      // AdMob이 없으면 Internal 숏폼만 글로벌 픽 #1을 차지한다.
      expect(find.text('글로벌 픽 #2'), findsNothing);
    });

    testWidgets('AdMob 구좌를 탭하면 onPressed 가 실제로 admob 플랫폼의 checkAdsLimit 로 '
        '이어져 check-ads-count?platform=admob 요청이 나간다 (콜백 배선 회귀 방지)', (
      tester,
    ) async {
      Environment.initTestConfig(_envConfig(includeAdmob: true));
      initTestEnvironment();
      final restoreImages = suppressImageErrors();
      addTearDown(restoreImages);

      final requests = <http.Request>[];
      testSupabaseClient = _queueingClient([
        const _QueuedResponse(body: {'allowed': false, 'disabled': false}),
      ], requests);

      await pumpWidgetAndIgnoreErrors(
        tester,
        buildTestApp(const FreeChargeStation(), loggedIn: true),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester);

      final admobRow = find.descendant(
        of: find.byKey(const ValueKey('free-charge-admob')),
        matching: find.byType(StoreListTile),
      );
      expect(admobRow, findsOneWidget);

      final admobButton = find.descendant(
        of: admobRow,
        matching: find.byType(ElevatedButton),
      );
      expect(admobButton, findsOneWidget);

      await tester.ensureVisible(admobButton);
      await pumpAndIgnoreErrors(tester);
      await tester.tap(admobButton);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 50));
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 50));
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 50));

      expect(
        requests,
        isNotEmpty,
        reason: 'AdMob 구좌 탭이 실제 checkAdsLimit 네트워크 요청까지 이어져야 한다',
      );
      expect(requests.first.url.queryParameters['platform'], 'admob');
    });
  });
}
