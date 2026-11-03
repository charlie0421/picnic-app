import 'package:flutter/material.dart';

import 'app_route_observer.dart';

/// [RouteObserver]와 함께 사용할 수 있는 재사용 가능한 믹스인.
///
/// 라우트 구독/해지를 공통 처리하여 각 페이지에서 포그라운드 복귀 등을
/// 쉽게 감지할 수 있도록 합니다. 필요한 경우 각 콜백을 오버라이드해서 사용하세요.
mixin RouteAwareStateMixin<T extends StatefulWidget> on State<T>
    implements RouteAware {
  RouteObserver<PageRoute<dynamic>> get routeObserver => appRouteObserver;

  PageRoute<dynamic>? _subscribedRoute;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_subscribedRoute != null) return;

    // 구독 대상 라우트는 옵저버가 추적하는 최상단 PageRoute 로 정한다.
    // `ModalRoute.of(context)` 를 쓰면 이 State 가 라우트 상태(isCurrent 등)에
    // 영구 의존하게 되어, 다이얼로그가 열리고 닫힐 때마다 스택의 모든
    // 페이지에 didChangeDependencies 가 돌고 각 페이지가 settingNavigation 을
    // 다시 호출해 마지막 호출이 이기는 경합이 생긴다(PICNIC-777).
    final observer = routeObserver;
    PageRoute<dynamic>? route = observer is AppRouteObserver
        ? observer.currentPageRoute
        : null;
    if (route == null) {
      // 옵저버가 Navigator 에 붙지 않은 하네스(대부분의 위젯 테스트)용 폴백.
      final modalRoute = ModalRoute.of(context);
      if (modalRoute is PageRoute<dynamic>) route = modalRoute;
    }
    if (route != null) {
      _subscribedRoute = route;
      observer.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  /// 현재 라우트가 push 되었을 때 호출됩니다.
  @mustCallSuper
  void onRoutePushed() {}

  /// 현재 라우트가 pop 되었을 때 호출됩니다.
  @mustCallSuper
  void onRoutePopped() {}

  /// 다른 라우트가 push 되면서 현재 라우트가 가려질 때 호출됩니다.
  @mustCallSuper
  void onRoutePushNext() {}

  /// 가려졌던 라우트가 pop 되면서 현재 라우트가 다시 보일 때 호출됩니다.
  @mustCallSuper
  void onRoutePopNext() {}

  @override
  void didPush() {
    onRoutePushed();
  }

  @override
  void didPop() {
    onRoutePopped();
  }

  @override
  void didPushNext() {
    onRoutePushNext();
  }

  @override
  void didPopNext() {
    onRoutePopNext();
  }
}
