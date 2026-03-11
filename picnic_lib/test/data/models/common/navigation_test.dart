import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/common/navigation.dart';
import 'package:picnic_lib/enums.dart';

void main() {
  group('TopRightType enum', () {
    test('5개의 타입이 정의됨', () {
      expect(TopRightType.values.length, equals(5));
    });

    test('모든 타입 존재 확인', () {
      expect(TopRightType.none, isNotNull);
      expect(TopRightType.common, isNotNull);
      expect(TopRightType.board, isNotNull);
      expect(TopRightType.postView, isNotNull);
      expect(TopRightType.community, isNotNull);
    });
  });

  group('Navigation 기본 생성자', () {
    test('기본값 확인', () {
      const nav = Navigation();
      expect(nav.portalType, equals(PortalType.vote));
      expect(nav.picBottomNavigationIndex, equals(0));
      expect(nav.voteBottomNavigationIndex, equals(0));
      expect(nav.communityBottomNavigationIndex, equals(0));
      expect(nav.novelBottomNavigationIndex, equals(0));
      expect(nav.currentScreen, isNull);
      expect(nav.showPortal, isTrue);
      expect(nav.showTopMenu, isTrue);
      expect(nav.showMyPoint, isTrue);
      expect(nav.topRightMenu, equals(TopRightType.common));
      expect(nav.showBottomNavigation, isTrue);
      expect(nav.pageTitle, isEmpty);
      expect(nav.myPageTitle, isEmpty);
    });
  });

  group('Navigation.copyWith', () {
    test('portalType 변경', () {
      const original = Navigation();
      final copied = original.copyWith(portalType: PortalType.pic);
      expect(copied.portalType, equals(PortalType.pic));
      expect(copied.showPortal, isTrue); // 기존 값 유지
    });

    test('여러 필드 동시 변경', () {
      const original = Navigation();
      final copied = original.copyWith(
        showPortal: false,
        showTopMenu: false,
        showBottomNavigation: false,
        pageTitle: '테스트 페이지',
      );
      expect(copied.showPortal, isFalse);
      expect(copied.showTopMenu, isFalse);
      expect(copied.showBottomNavigation, isFalse);
      expect(copied.pageTitle, equals('테스트 페이지'));
      expect(copied.portalType, equals(PortalType.vote)); // 기존 값 유지
    });

    test('네비게이션 인덱스 변경', () {
      const original = Navigation();
      final copied = original.copyWith(
        voteBottomNavigationIndex: 2,
        picBottomNavigationIndex: 1,
      );
      expect(copied.voteBottomNavigationIndex, equals(2));
      expect(copied.picBottomNavigationIndex, equals(1));
    });
  });

  group('Navigation.getBottomNavigationIndex', () {
    test('vote 포탈이면 voteBottomNavigationIndex 반환', () {
      const nav = Navigation(
        portalType: PortalType.vote,
        voteBottomNavigationIndex: 3,
      );
      expect(nav.getBottomNavigationIndex(), equals(3));
    });

    test('pic 포탈이면 picBottomNavigationIndex 반환', () {
      const nav = Navigation(
        portalType: PortalType.pic,
        picBottomNavigationIndex: 2,
      );
      expect(nav.getBottomNavigationIndex(), equals(2));
    });

    test('community 포탈이면 communityBottomNavigationIndex 반환', () {
      const nav = Navigation(
        portalType: PortalType.community,
        communityBottomNavigationIndex: 1,
      );
      expect(nav.getBottomNavigationIndex(), equals(1));
    });

    test('goongHap 포탈이면 communityBottomNavigationIndex 반환', () {
      const nav = Navigation(
        portalType: PortalType.goongHap,
        communityBottomNavigationIndex: 4,
      );
      expect(nav.getBottomNavigationIndex(), equals(4));
    });

    test('novel 포탈이면 novelBottomNavigationIndex 반환', () {
      const nav = Navigation(
        portalType: PortalType.novel,
        novelBottomNavigationIndex: 1,
      );
      expect(nav.getBottomNavigationIndex(), equals(1));
    });
  });
}
