import 'package:flutter/material.dart';

/// 앱 전역에서 공유하는 [RouteObserver].
///
/// 화면 전환 시점을 감지하여 각 페이지가 포그라운드로 복귀할 때 등의
/// 이벤트를 처리할 수 있도록 단일 인스턴스를 제공합니다.
///
/// 최상단 [PageRoute] 도 함께 추적한다([currentPageRoute]).
/// [RouteAwareStateMixin] 이 `ModalRoute.of` 대신 이 값으로 구독하므로,
/// 페이지가 라우트 상태(isCurrent 등)에 대한 InheritedWidget 의존을 갖지 않는다.
/// 그 의존이 있으면 다이얼로그 하나만 떠도 스택의 모든 페이지에
/// `didChangeDependencies` 가 돌아 내비게이션 상태가 뒤섞인다(PICNIC-777).
class AppRouteObserver extends RouteObserver<PageRoute<dynamic>> {
  final List<PageRoute<dynamic>> _pageRoutes = [];

  /// 현재 최상단 [PageRoute]. 다이얼로그·바텀시트 같은 [PopupRoute] 는 세지 않는다.
  PageRoute<dynamic>? get currentPageRoute =>
      _pageRoutes.isEmpty ? null : _pageRoutes.last;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute<dynamic>) _pageRoutes.add(route);
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute<dynamic>) _pageRoutes.remove(route);
    super.didPop(route, previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute<dynamic>) _pageRoutes.remove(route);
    super.didRemove(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final index = oldRoute is PageRoute<dynamic>
        ? _pageRoutes.indexOf(oldRoute)
        : -1;
    if (index >= 0) {
      if (newRoute is PageRoute<dynamic>) {
        _pageRoutes[index] = newRoute;
      } else {
        _pageRoutes.removeAt(index);
      }
    } else if (newRoute is PageRoute<dynamic>) {
      _pageRoutes.add(newRoute);
    }
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}

final AppRouteObserver appRouteObserver = AppRouteObserver();
