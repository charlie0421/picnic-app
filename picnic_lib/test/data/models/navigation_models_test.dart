import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/navigator/bottom_navigation_item.dart';
import 'package:picnic_lib/data/models/navigator/screen_info.dart';
import 'package:picnic_lib/enums.dart';

void main() {
  group('BottomNavigationItem', () {
    test('필수 파라미터로 객체를 생성할 수 있다', () {
      final item = BottomNavigationItem(
        title: '홈',
        assetPath: 'assets/icons/home.svg',
        index: 0,
        pageWidget: const SizedBox(),
        needLogin: false,
      );

      expect(item.title, equals('홈'));
      expect(item.assetPath, equals('assets/icons/home.svg'));
      expect(item.index, equals(0));
      expect(item.pageWidget, isA<Widget>());
      expect(item.needLogin, isFalse);
    });

    test('needLogin이 true인 항목을 생성할 수 있다', () {
      final item = BottomNavigationItem(
        title: '마이페이지',
        assetPath: 'assets/icons/mypage.svg',
        index: 3,
        pageWidget: const SizedBox(),
        needLogin: true,
      );

      expect(item.needLogin, isTrue);
      expect(item.index, equals(3));
    });

    test('여러 네비게이션 항목을 리스트로 관리할 수 있다', () {
      final items = [
        BottomNavigationItem(
          title: '투표',
          assetPath: 'assets/icons/vote.svg',
          index: 0,
          pageWidget: const SizedBox(),
          needLogin: false,
        ),
        BottomNavigationItem(
          title: '커뮤니티',
          assetPath: 'assets/icons/community.svg',
          index: 1,
          pageWidget: const SizedBox(),
          needLogin: false,
        ),
        BottomNavigationItem(
          title: '마이페이지',
          assetPath: 'assets/icons/mypage.svg',
          index: 2,
          pageWidget: const SizedBox(),
          needLogin: true,
        ),
      ];

      expect(items.length, equals(3));
      expect(items.where((i) => i.needLogin).length, equals(1));
    });

    test('각 속성이 올바른 타입이다', () {
      final item = BottomNavigationItem(
        title: '테스트',
        assetPath: 'test.svg',
        index: 0,
        pageWidget: const Placeholder(),
        needLogin: false,
      );

      expect(item.title, isA<String>());
      expect(item.assetPath, isA<String>());
      expect(item.index, isA<int>());
      expect(item.pageWidget, isA<Widget>());
      expect(item.needLogin, isA<bool>());
    });
  });

  group('ScreenInfo', () {
    test('필수 파라미터로 객체를 생성할 수 있다', () {
      final screenInfo = ScreenInfo(
        type: PortalType.vote,
        color: Colors.blue,
        pages: [],
      );

      expect(screenInfo.type, equals(PortalType.vote));
      expect(screenInfo.color, equals(Colors.blue));
      expect(screenInfo.pages, isEmpty);
    });

    test('페이지 리스트를 포함하는 ScreenInfo를 생성할 수 있다', () {
      final pages = [
        BottomNavigationItem(
          title: '홈',
          assetPath: 'assets/home.svg',
          index: 0,
          pageWidget: const SizedBox(),
          needLogin: false,
        ),
        BottomNavigationItem(
          title: '설정',
          assetPath: 'assets/settings.svg',
          index: 1,
          pageWidget: const SizedBox(),
          needLogin: true,
        ),
      ];

      final screenInfo = ScreenInfo(
        type: PortalType.community,
        color: Colors.red,
        pages: pages,
      );

      expect(screenInfo.pages.length, equals(2));
      expect(screenInfo.pages[0].title, equals('홈'));
      expect(screenInfo.pages[1].title, equals('설정'));
    });

    test('모든 PortalType으로 ScreenInfo를 생성할 수 있다', () {
      for (final portalType in PortalType.values) {
        final screenInfo = ScreenInfo(
          type: portalType,
          color: Colors.grey,
          pages: [],
        );
        expect(screenInfo.type, equals(portalType));
      }
    });

    test('type 속성은 PortalType이다', () {
      final screenInfo = ScreenInfo(
        type: PortalType.pic,
        color: Colors.green,
        pages: [],
      );
      expect(screenInfo.type, isA<PortalType>());
    });

    test('color 속성은 Color이다', () {
      final screenInfo = ScreenInfo(
        type: PortalType.mypage,
        color: const Color(0xFF123456),
        pages: [],
      );
      expect(screenInfo.color, isA<Color>());
      expect(screenInfo.color, equals(const Color(0xFF123456)));
    });
  });
}
