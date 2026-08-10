import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/analytics/ga4_sink.dart';
import 'package:picnic_lib/core/analytics/ga4_taxonomy.dart';
import 'package:picnic_lib/core/analytics/picnic_analytics.dart';
import 'package:picnic_lib/core/utils/firebase_analytics_utils.dart';

void main() {
  group('AppAnalytics', () {
    group('buildNavigatorObservers', () {
      test('returns a list of NavigatorObservers', () {
        final observers = AppAnalytics.buildNavigatorObservers();
        expect(observers, isA<List<NavigatorObserver>>());
      });

      test('returns non-empty list (at least appRouteObserver)', () {
        final observers = AppAnalytics.buildNavigatorObservers();
        expect(observers, isNotEmpty);
        // appRouteObserver is always included
        expect(observers.length, greaterThanOrEqualTo(1));
      });

      test('does not include FirebaseAnalyticsObserver when Firebase not initialized', () {
        // In test environment Firebase is not initialized
        final observers = AppAnalytics.buildNavigatorObservers();
        // 개수가 아니라 의도를 단언한다. 기본 관찰자(appRouteObserver,
        // sentryNavigatorObserver)가 늘어도 깨지지 않게 — PR #56 이 Sentry
        // 관찰자를 추가했을 때 length==1 단언이 깨진 채 방치된 전례.
        expect(observers.whereType<FirebaseAnalyticsObserver>(), isEmpty);
      });

      test('can be called multiple times without error', () {
        final observers1 = AppAnalytics.buildNavigatorObservers();
        final observers2 = AppAnalytics.buildNavigatorObservers();
        expect(observers1, isNotEmpty);
        expect(observers2, isNotEmpty);
      });
    });

    group('setUserAndSessionProperties', () {
      test('completes without error when Firebase not initialized', () async {
        // Firebase is not initialized in tests, so this should return early
        await AppAnalytics.setUserAndSessionProperties(
          userId: 'test-user-123',
        );
      });

      test('accepts all optional parameters without error', () async {
        await AppAnalytics.setUserAndSessionProperties(
          userId: 'user-456',
          userRole: 'admin',
          locale: 'ko',
          isTester: true,
        );
      });

      test('accepts empty userId', () async {
        await AppAnalytics.setUserAndSessionProperties(
          userId: '',
        );
      });

      test('accepts null optional parameters', () async {
        await AppAnalytics.setUserAndSessionProperties(
          userId: 'user-789',
          userRole: null,
          locale: null,
          isTester: null,
        );
      });

      test('accepts isTester false', () async {
        await AppAnalytics.setUserAndSessionProperties(
          userId: 'user-test',
          isTester: false,
        );
      });

      test('accepts empty string for userRole and locale', () async {
        await AppAnalytics.setUserAndSessionProperties(
          userId: 'user-test',
          userRole: '',
          locale: '',
        );
      });

      test('accepts the new language / isLogin parameters', () async {
        await AppAnalytics.setUserAndSessionProperties(
          userId: 'user-lang',
          language: 'jp',
          isLogin: true,
        );
      });
    });

    // GA4 택소노미 §1 — AppAnalytics 는 PicnicAnalytics 로 위임하므로,
    // 실제로 어떤 사용자 속성이 어떤 이름/값으로 나가는지는 싱크를 갈아끼워
    // 검증한다.
    group('GA4 사용자 속성 위임', () {
      late RecordingGa4Sink sink;

      setUp(() {
        sink = RecordingGa4Sink();
        PicnicAnalytics.overrideInstance(PicnicAnalytics(sink: sink));
      });

      tearDown(PicnicAnalytics.resetInstance);

      test('user_id 는 해시 없이 원본 UUID 로 전달된다', () async {
        const uuid = '7c9e6679-7425-40de-944b-e07fc1f90ae7';

        await AppAnalytics.setUserAndSessionProperties(
          userId: uuid,
          locale: 'ko',
        );

        expect(sink.userIds, <String?>[uuid]);
      });

      test('is_login=Y 와 language 가 설정된다', () async {
        await AppAnalytics.setUserAndSessionProperties(
          userId: 'u1',
          language: 'en',
        );

        expect(sink.userProperties[Ga4UserProperty.isLogin],
            Ga4Value.loggedIn);
        expect(sink.userProperties[Ga4UserProperty.language], 'en');
      });

      test('language 를 생략하면 locale 이 language 로 쓰인다', () async {
        await AppAnalytics.setUserAndSessionProperties(
          userId: 'u1',
          locale: 'ko',
        );

        expect(sink.userProperties[Ga4UserProperty.language], 'ko');
      });

      test('레거시 속성 user_role / is_tester / app_env 가 유지된다', () async {
        await AppAnalytics.setUserAndSessionProperties(
          userId: 'u1',
          userRole: 'admin',
          locale: 'ko',
          isTester: true,
        );

        expect(sink.userProperties[Ga4UserProperty.userRole], 'admin');
        expect(sink.userProperties[Ga4UserProperty.locale], 'ko');
        expect(sink.userProperties[Ga4UserProperty.isTester], 'true');
        expect(sink.userProperties[Ga4UserProperty.appEnv], 'production');
      });

      test('로그아웃 시 is_login 이 N 으로 갱신된다', () async {
        await AppAnalytics.setUserAndSessionProperties(userId: 'u1');
        await AppAnalytics.clearUserAndSessionProperties();

        expect(sink.userProperties[Ga4UserProperty.isLogin],
            Ga4Value.loggedOut);
        expect(sink.userIds.last, isNull);
      });
    });

    group('clearUserAndSessionProperties', () {
      test('completes without error when Firebase not initialized', () async {
        await AppAnalytics.clearUserAndSessionProperties();
      });

      test('can be called multiple times safely', () async {
        await AppAnalytics.clearUserAndSessionProperties();
        await AppAnalytics.clearUserAndSessionProperties();
        await AppAnalytics.clearUserAndSessionProperties();
      });

      test('can be called after setUserAndSessionProperties', () async {
        await AppAnalytics.setUserAndSessionProperties(
          userId: 'user-to-clear',
          userRole: 'user',
          locale: 'en',
          isTester: false,
        );
        await AppAnalytics.clearUserAndSessionProperties();
      });
    });
  });
}
