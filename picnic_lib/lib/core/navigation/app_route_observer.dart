import 'package:flutter/material.dart';

/// 앱 전역에서 공유하는 [RouteObserver].
///
/// 화면 전환 시점을 감지하여 각 페이지가 포그라운드로 복귀할 때 등의
/// 이벤트를 처리할 수 있도록 단일 인스턴스를 제공합니다.
final RouteObserver<PageRoute<dynamic>> appRouteObserver =
    RouteObserver<PageRoute<dynamic>>();


