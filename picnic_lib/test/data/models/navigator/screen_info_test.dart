import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/navigator/bottom_navigation_item.dart';
import 'package:picnic_lib/data/models/navigator/screen_info.dart';
import 'package:picnic_lib/enums.dart';

void main() {
  group('ScreenInfo', () {
    test('생성 확인', () {
      const info = ScreenInfo(
        type: PortalType.vote,
        color: Colors.blue,
        pages: [],
      );
      expect(info.type, equals(PortalType.vote));
      expect(info.color, equals(Colors.blue));
      expect(info.pages, isEmpty);
    });

    test('페이지 리스트 포함', () {
      const pages = [
        BottomNavigationItem(
          title: '홈',
          assetPath: 'home.svg',
          index: 0,
          pageWidget: SizedBox(),
          needLogin: false,
        ),
        BottomNavigationItem(
          title: '투표',
          assetPath: 'vote.svg',
          index: 1,
          pageWidget: SizedBox(),
          needLogin: false,
        ),
      ];
      const info = ScreenInfo(
        type: PortalType.vote,
        color: Colors.red,
        pages: pages,
      );
      expect(info.pages.length, equals(2));
      expect(info.pages[0].title, equals('홈'));
      expect(info.pages[1].title, equals('투표'));
    });

    test('다양한 PortalType으로 생성', () {
      for (final type in PortalType.values) {
        final info = ScreenInfo(
          type: type,
          color: Colors.green,
          pages: const [],
        );
        expect(info.type, equals(type));
      }
    });
  });
}
