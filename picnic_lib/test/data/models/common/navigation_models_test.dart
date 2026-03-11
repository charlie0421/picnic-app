import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/common/navigation.dart';
import 'package:picnic_lib/enums.dart';

void main() {
  group('TopRightType', () {
    test('has all expected values', () {
      expect(TopRightType.values.length, 5);
      expect(TopRightType.values, contains(TopRightType.none));
      expect(TopRightType.values, contains(TopRightType.common));
      expect(TopRightType.values, contains(TopRightType.board));
      expect(TopRightType.values, contains(TopRightType.postView));
      expect(TopRightType.values, contains(TopRightType.community));
    });
  });

  group('Navigation', () {
    test('default values', () {
      const nav = Navigation();
      expect(nav.portalType, PortalType.vote);
      expect(nav.picBottomNavigationIndex, 0);
      expect(nav.voteBottomNavigationIndex, 0);
      expect(nav.communityBottomNavigationIndex, 0);
      expect(nav.novelBottomNavigationIndex, 0);
      expect(nav.currentScreen, isNull);
      expect(nav.showPortal, isTrue);
      expect(nav.showTopMenu, isTrue);
      expect(nav.showMyPoint, isTrue);
      expect(nav.topRightMenu, TopRightType.common);
      expect(nav.showBottomNavigation, isTrue);
      expect(nav.pageTitle, '');
      expect(nav.myPageTitle, '');
    });

    test('copyWith updates portalType', () {
      const nav = Navigation();
      final updated = nav.copyWith(portalType: PortalType.pic);
      expect(updated.portalType, PortalType.pic);
      expect(updated.showPortal, isTrue);
    });

    test('copyWith updates visibility flags', () {
      const nav = Navigation();
      final updated = nav.copyWith(
        showPortal: false,
        showTopMenu: false,
        showBottomNavigation: false,
        showMyPoint: false,
      );
      expect(updated.showPortal, isFalse);
      expect(updated.showTopMenu, isFalse);
      expect(updated.showBottomNavigation, isFalse);
      expect(updated.showMyPoint, isFalse);
    });

    test('copyWith updates navigation indices', () {
      const nav = Navigation();
      final updated = nav.copyWith(
        voteBottomNavigationIndex: 2,
        picBottomNavigationIndex: 1,
        communityBottomNavigationIndex: 3,
      );
      expect(updated.voteBottomNavigationIndex, 2);
      expect(updated.picBottomNavigationIndex, 1);
      expect(updated.communityBottomNavigationIndex, 3);
    });

    test('copyWith updates titles', () {
      const nav = Navigation();
      final updated = nav.copyWith(
        pageTitle: 'Test Page',
        myPageTitle: 'My Page',
        topRightMenu: TopRightType.board,
      );
      expect(updated.pageTitle, 'Test Page');
      expect(updated.myPageTitle, 'My Page');
      expect(updated.topRightMenu, TopRightType.board);
    });

    test('copyWith preserves unchanged fields', () {
      const nav = Navigation(
        portalType: PortalType.community,
        voteBottomNavigationIndex: 2,
        showPortal: false,
        pageTitle: 'Original',
      );
      final updated = nav.copyWith(showTopMenu: false);
      expect(updated.portalType, PortalType.community);
      expect(updated.voteBottomNavigationIndex, 2);
      expect(updated.showPortal, isFalse);
      expect(updated.pageTitle, 'Original');
    });

    group('getBottomNavigationIndex', () {
      test('returns voteBottomNavigationIndex for vote portal', () {
        const nav = Navigation(
          portalType: PortalType.vote,
          voteBottomNavigationIndex: 2,
        );
        expect(nav.getBottomNavigationIndex(), 2);
      });

      test('returns picBottomNavigationIndex for pic portal', () {
        const nav = Navigation(
          portalType: PortalType.pic,
          picBottomNavigationIndex: 1,
        );
        expect(nav.getBottomNavigationIndex(), 1);
      });

      test('returns communityBottomNavigationIndex for community portal', () {
        const nav = Navigation(
          portalType: PortalType.community,
          communityBottomNavigationIndex: 3,
        );
        expect(nav.getBottomNavigationIndex(), 3);
      });

      test('returns communityBottomNavigationIndex for goongHap portal', () {
        const nav = Navigation(
          portalType: PortalType.goongHap,
          communityBottomNavigationIndex: 1,
        );
        expect(nav.getBottomNavigationIndex(), 1);
      });

      test('returns novelBottomNavigationIndex for novel portal', () {
        const nav = Navigation(
          portalType: PortalType.novel,
          novelBottomNavigationIndex: 2,
        );
        expect(nav.getBottomNavigationIndex(), 2);
      });

      test('returns 0 for mypage portal', () {
        const nav = Navigation(portalType: PortalType.mypage);
        expect(nav.getBottomNavigationIndex(), 0);
      });
    });
  });
}
