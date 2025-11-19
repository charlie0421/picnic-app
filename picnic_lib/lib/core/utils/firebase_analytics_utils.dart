import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart' as firebase_core;
import 'package:firebase_analytics/firebase_analytics.dart';

import 'package:picnic_lib/core/navigation/app_route_observer.dart';

class AppAnalytics {
  /// Firebase가 초기화된 경우에만 NavigatorObservers를 반환합니다.
  /// 초기화되지 않았다면 빈 리스트를 반환하여 런타임 오류를 방지합니다.
  static List<NavigatorObserver> buildNavigatorObservers() {
    final observers = <NavigatorObserver>[appRouteObserver];

    try {
      final isInitialized = firebase_core.Firebase.apps.isNotEmpty;
      if (isInitialized) {
        final analytics = FirebaseAnalytics.instance;
        observers.add(FirebaseAnalyticsObserver(analytics: analytics));
      }
    } catch (_) {
      // 어떤 예외가 발생해도 Firebase Analytics 옵저버 추가를 건너뜁니다.
    }

    return observers;
  }

  /// 사용자/세션 속성 설정
  static Future<void> setUserAndSessionProperties({
    required String userId,
    String? userRole,
    String? locale,
    bool? isTester,
  }) async {
    try {
      final isInitialized = firebase_core.Firebase.apps.isNotEmpty;
      if (!isInitialized) return;

      final analytics = FirebaseAnalytics.instance;
      await analytics.setUserId(id: userId);

      // 사용자 속성
      if (userRole != null && userRole.isNotEmpty) {
        await analytics.setUserProperty(name: 'user_role', value: userRole);
      }
      if (locale != null && locale.isNotEmpty) {
        await analytics.setUserProperty(name: 'locale', value: locale);
      }
      if (isTester != null) {
        await analytics.setUserProperty(
          name: 'is_tester',
          value: isTester ? 'true' : 'false',
        );
      }

      // 세션 관련 예시 속성 (필요 시 확장)
      await analytics.setUserProperty(name: 'app_env', value: 'production');
    } catch (_) {
      // 에러 무시 (로그만 남기지 않음)
    }
  }

  /// 사용자/세션 속성 해제 (로그아웃 등)
  static Future<void> clearUserAndSessionProperties() async {
    try {
      final isInitialized = firebase_core.Firebase.apps.isNotEmpty;
      if (!isInitialized) return;

      final analytics = FirebaseAnalytics.instance;
      await analytics.setUserId(id: null);

      // 등록했던 속성들 초기화 (null로 설정하면 제거)
      await analytics.setUserProperty(name: 'user_role', value: null);
      await analytics.setUserProperty(name: 'locale', value: null);
      await analytics.setUserProperty(name: 'is_tester', value: null);
      await analytics.setUserProperty(name: 'app_env', value: null);
    } catch (_) {}
  }
}
