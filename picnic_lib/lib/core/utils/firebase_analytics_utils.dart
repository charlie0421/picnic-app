import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart' as firebase_core;
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'package:picnic_lib/core/analytics/picnic_analytics.dart';
import 'package:picnic_lib/core/navigation/app_route_observer.dart';

/// SentryNavigatorObserver: 라우트 push/pop 을 브레드크럼으로 남기고 현재
/// 라우트를 트랜잭션으로 설정 → ANR/crash 이벤트에 "어느 화면에서 멈췄는지"가
/// 붙는다 (PICNIC-APP-45E 관측성. 심볼화 불가한 all-system ANR 을 화면 단위로
/// 분류하기 위함). Sentry 미초기화 시에도 no-op hub 라 안전.
///
/// **반드시 module-level 싱글턴**으로 둔다: [buildNavigatorObservers] 는 루트
/// App 이 navigationInfoProvider 를 watch 하므로 매 navigation 변경마다
/// 재호출된다. 리스트 리터럴 안에서 매번 새로 생성하면 Navigator 가 관찰자를
/// 교체하며 진행 중인 네비게이션 트랜잭션(_transaction)을 orphan 시킨다. 동일
/// 인스턴스를 재사용하면 관찰자의 navigator 재바인딩만 일어나 상태가 보존된다.
final sentryNavigatorObserver =
    SentryNavigatorObserver(setRouteNameAsTransaction: true);

class AppAnalytics {
  /// Firebase가 초기화된 경우에만 NavigatorObservers를 반환합니다.
  /// 초기화되지 않았다면 빈 리스트를 반환하여 런타임 오류를 방지합니다.
  static List<NavigatorObserver> buildNavigatorObservers() {
    final observers = <NavigatorObserver>[
      appRouteObserver,
      sentryNavigatorObserver,
    ];

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

  /// 사용자/세션 속성 설정 (GA4 택소노미 §1).
  ///
  /// 스펙이 요구하는 속성은 `user_id` / `is_login` / `language` 다.
  /// 기존 `user_role` / `locale` / `is_tester` / `app_env` 는 기존 리포트가
  /// 의존할 수 있어 제거하지 않고 그대로 유지한다.
  ///
  /// [userId] 는 **해시하지 않은** Supabase `auth.users.id` (UUID) 다.
  /// 근거는 [PicnicAnalytics.setUserProperties] 주석 및
  /// docs/analytics/ga4-event-taxonomy.md 참고.
  ///
  /// [language] 를 주지 않으면 [locale] 을 사용한다 — 두 값이 사실상 같은
  /// 언어 코드이고, 기존 호출부가 locale 만 넘기던 경로를 깨지 않기 위함이다.
  static Future<void> setUserAndSessionProperties({
    required String userId,
    String? userRole,
    String? locale,
    bool? isTester,
    String? language,
    bool isLogin = true,
  }) async {
    await PicnicAnalytics.instance.setUserProperties(
      userId: userId,
      isLogin: isLogin,
      language: language ?? locale,
      userRole: userRole,
      locale: locale,
      isTester: isTester,
      appEnv: 'production',
    );
  }

  /// 사용자/세션 속성 해제 (로그아웃 등).
  ///
  /// `is_login` 은 제거하지 않고 `'N'` 으로 갱신한다 (스펙 §1).
  static Future<void> clearUserAndSessionProperties() async {
    await PicnicAnalytics.instance.clearUserProperties();
  }
}
