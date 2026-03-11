import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/navigator/bottom_navigation_item.dart';

void main() {
  group('BottomNavigationItem', () {
    test('생성 확인', () {
      const item = BottomNavigationItem(
        title: '홈',
        assetPath: 'assets/icons/home.svg',
        index: 0,
        pageWidget: SizedBox(),
        needLogin: false,
      );
      expect(item.title, equals('홈'));
      expect(item.assetPath, equals('assets/icons/home.svg'));
      expect(item.index, equals(0));
      expect(item.pageWidget, isA<SizedBox>());
      expect(item.needLogin, isFalse);
    });

    test('로그인 필요 항목', () {
      const item = BottomNavigationItem(
        title: '마이페이지',
        assetPath: 'assets/icons/mypage.svg',
        index: 4,
        pageWidget: SizedBox(),
        needLogin: true,
      );
      expect(item.needLogin, isTrue);
      expect(item.index, equals(4));
    });

    test('const 생성자 지원', () {
      const item = BottomNavigationItem(
        title: 'test',
        assetPath: 'test.svg',
        index: 0,
        pageWidget: SizedBox(),
        needLogin: false,
      );
      expect(item, isA<BottomNavigationItem>());
    });
  });
}
