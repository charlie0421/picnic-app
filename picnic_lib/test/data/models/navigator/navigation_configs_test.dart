import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/navigator/navigation_configs.dart';
import 'package:picnic_lib/enums.dart';

import '../../../helpers/test_environment.dart';

void main() {
  setUpAll(() => initTestColors());
  group('NavigationConfigs.getScreenInfo', () {
    test('vote 포탈 ScreenInfo 반환', () {
      final info = NavigationConfigs.getScreenInfo(PortalType.vote);
      expect(info, isNotNull);
      expect(info!.type, equals(PortalType.vote));
    });

    test('pic 포탈 ScreenInfo 반환', () {
      final info = NavigationConfigs.getScreenInfo(PortalType.pic);
      expect(info, isNotNull);
      expect(info!.type, equals(PortalType.pic));
    });

    test('community 포탈 ScreenInfo 반환', () {
      final info = NavigationConfigs.getScreenInfo(PortalType.community);
      expect(info, isNotNull);
      expect(info!.type, equals(PortalType.community));
    });

    test('goongHap 포탈 ScreenInfo 반환', () {
      final info = NavigationConfigs.getScreenInfo(PortalType.goongHap);
      expect(info, isNotNull);
      expect(info!.type, equals(PortalType.goongHap));
    });

    test('novel 포탈 ScreenInfo 반환', () {
      final info = NavigationConfigs.getScreenInfo(PortalType.novel);
      expect(info, isNotNull);
    });

    test('mypage 포탈은 null', () {
      final info = NavigationConfigs.getScreenInfo(PortalType.mypage);
      expect(info, isNull);
    });
  });

  group('NavigationConfigs.getPages', () {
    test('vote 포탈은 4개 페이지', () {
      final pages = NavigationConfigs.getPages(PortalType.vote);
      expect(pages.length, equals(4));
      expect(pages[0].title, equals('nav_vote'));
      expect(pages[1].title, equals('nav_community'));
      expect(pages[2].title, equals('nav_media'));
      expect(pages[3].title, equals('nav_store'));
    });

    test('pic 포탈은 3개 페이지', () {
      final pages = NavigationConfigs.getPages(PortalType.pic);
      expect(pages.length, equals(3));
    });

    test('community 포탈은 4개 페이지', () {
      final pages = NavigationConfigs.getPages(PortalType.community);
      expect(pages.length, equals(4));
    });

    test('goongHap 포탈은 1개 페이지', () {
      final pages = NavigationConfigs.getPages(PortalType.goongHap);
      expect(pages.length, equals(1));
    });

    test('존재하지 않는 포탈은 빈 리스트', () {
      final pages = NavigationConfigs.getPages(PortalType.mypage);
      expect(pages, isEmpty);
    });
  });

  group('NavigationConfigs.getPageWidget', () {
    test('유효한 인덱스면 위젯 반환', () {
      final widget = NavigationConfigs.getPageWidget(PortalType.vote, 0);
      expect(widget, isNotNull);
    });

    test('범위 밖 인덱스면 null', () {
      final widget = NavigationConfigs.getPageWidget(PortalType.vote, 99);
      expect(widget, isNull);
    });

    test('음수 인덱스면 null', () {
      final widget = NavigationConfigs.getPageWidget(PortalType.vote, -1);
      expect(widget, isNull);
    });
  });

  group('NavigationConfigs.screenInfoMap', () {
    test('문자열 키로 된 맵 반환', () {
      final map = NavigationConfigs.screenInfoMap;
      expect(map.containsKey('vote'), isTrue);
      expect(map.containsKey('pic'), isTrue);
      expect(map.containsKey('community'), isTrue);
    });

    test('community 페이지 중 needLogin 확인', () {
      final pages = NavigationConfigs.getPages(PortalType.community);
      final loginRequired = pages.where((p) => p.needLogin).toList();
      expect(loginRequired.length, equals(1));
      expect(loginRequired.first.title, equals('nav_my'));
    });
  });
}
