import 'package:flutter/material.dart';

import 'app_route_observer.dart';

/// [RouteObserver]와 함께 사용할 수 있는 재사용 가능한 믹스인.
///
/// 라우트 구독/해지를 공통 처리하여 각 페이지에서 포그라운드 복귀 등을
/// 쉽게 감지할 수 있도록 합니다. 필요한 경우 각 콜백을 오버라이드해서 사용하세요.
mixin RouteAwareStateMixin<T extends StatefulWidget> on State<T>
    implements RouteAware {
  RouteObserver<PageRoute<dynamic>> get routeObserver => appRouteObserver;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final route = ModalRoute.of(context);
    if (route is PageRoute<dynamic>) {
      routeObserver.subscribe(this, route);
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


