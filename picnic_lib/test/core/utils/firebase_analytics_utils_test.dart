import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
