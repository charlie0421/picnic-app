import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/route_manager.dart';

void main() {
  group('RouteManager.resolveDeepLink', () {
    test('picnic 스키마가 아니면 null 반환', () {
      expect(
        RouteManager.resolveDeepLink(Uri.parse('https://example.com')),
        isNull,
      );
    });

    test('http 스키마이면 null 반환', () {
      expect(
        RouteManager.resolveDeepLink(Uri.parse('http://profile/123')),
        isNull,
      );
    });

    test('profile 딥링크 - ID 포함', () {
      final route = RouteManager.resolveDeepLink(
        Uri.parse('picnic://profile/user123'),
      );
      expect(route, equals('/profile/user123'));
    });

    test('profile 딥링크 - ID 없음', () {
      final route = RouteManager.resolveDeepLink(
        Uri.parse('picnic://profile'),
      );
      expect(route, equals('/profile/'));
    });

    test('post 딥링크 - ID 포함', () {
      final route = RouteManager.resolveDeepLink(
        Uri.parse('picnic://post/456'),
      );
      expect(route, equals('/post/456'));
    });

    test('post 딥링크 - ID 없음', () {
      final route = RouteManager.resolveDeepLink(
        Uri.parse('picnic://post'),
      );
      expect(route, equals('/post/'));
    });

    test('terms 딥링크', () {
      final route = RouteManager.resolveDeepLink(
        Uri.parse('picnic://terms'),
      );
      expect(route, isNotNull);
    });

    test('privacy 딥링크', () {
      final route = RouteManager.resolveDeepLink(
        Uri.parse('picnic://privacy'),
      );
      expect(route, isNotNull);
    });

    test('지원하지 않는 host는 null 반환', () {
      expect(
        RouteManager.resolveDeepLink(Uri.parse('picnic://settings')),
        isNull,
      );
      expect(
        RouteManager.resolveDeepLink(Uri.parse('picnic://unknown')),
        isNull,
      );
    });
  });

  group('RouteManager.getCommonRoutes', () {
    test('공통 라우트 맵이 비어있지 않음', () {
      final routes = RouteManager.getCommonRoutes();
      expect(routes, isNotEmpty);
    });

    test('/pic-camera 라우트 포함', () {
      final routes = RouteManager.getCommonRoutes();
      expect(routes.containsKey('/pic-camera'), isTrue);
    });
  });

  group('RouteManager.mergeRoutes', () {
    test('빈 맵 병합 시 공통 라우트만 반환', () {
      final merged = RouteManager.mergeRoutes({});
      final common = RouteManager.getCommonRoutes();
      expect(merged.length, equals(common.length));
    });

    test('앱별 라우트가 공통 라우트에 추가됨', () {
      final common = RouteManager.getCommonRoutes();
      final appRoutes = <String, WidgetBuilder>{
        '/custom': (_) => const SizedBox(),
      };
      final merged = RouteManager.mergeRoutes(appRoutes);
      expect(merged.length, equals(common.length + 1));
      expect(merged.containsKey('/custom'), isTrue);
    });

    test('동일 경로에 대해 앱별 라우트가 우선', () {
      final merged = RouteManager.mergeRoutes(<String, WidgetBuilder>{
        '/pic-camera': (_) => const SizedBox(),
      });
      // 앱별 라우트로 덮어씌워짐
      expect(merged.containsKey('/pic-camera'), isTrue);
    });
  });
}
