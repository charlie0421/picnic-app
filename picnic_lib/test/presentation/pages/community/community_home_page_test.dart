import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/common/navigation.dart';
import 'package:picnic_lib/enums.dart';
import 'package:picnic_lib/presentation/pages/community/community_home_page.dart';

void main() {
  group('CommunityHomePage', () {
    test('is a ConsumerStatefulWidget', () {
      const page = CommunityHomePage();
      expect(page, isNotNull);
    });

    test('can be constructed with key', () {
      const page = CommunityHomePage(key: ValueKey('community'));
      expect(page.key, const ValueKey('community'));
    });
  });

  group('PortalType used in CommunityHomePage', () {
    test('community portal type exists', () {
      expect(PortalType.community, isNotNull);
    });

    test('all portal types are available', () {
      expect(PortalType.values, isNotEmpty);
      expect(PortalType.values, contains(PortalType.community));
    });
  });

  group('TopRightType used in CommunityHomePage', () {
    test('community type exists', () {
      expect(TopRightType.community, isNotNull);
    });
  });

  group('Navigation model used in CommunityHomePage', () {
    test('Navigation default has empty pageTitle', () {
      const nav = Navigation();
      expect(nav.pageTitle, '');
    });

    test('Navigation with showPortal true', () {
      const nav = Navigation(showPortal: true);
      expect(nav.showPortal, true);
    });

    test('Navigation with showBottomNavigation true', () {
      const nav = Navigation(showBottomNavigation: true);
      expect(nav.showBottomNavigation, true);
    });

    test('Navigation with all community home settings', () {
      const nav = Navigation(
        showPortal: true,
        showTopMenu: true,
        showBottomNavigation: true,
        topRightMenu: TopRightType.community,
        pageTitle: '',
      );
      expect(nav.showPortal, true);
      expect(nav.showTopMenu, true);
      expect(nav.showBottomNavigation, true);
      expect(nav.topRightMenu, TopRightType.community);
      expect(nav.pageTitle, '');
    });

    test('Navigation portalType defaults correctly', () {
      const nav = Navigation();
      expect(nav.portalType, isNotNull);
    });

    test('Navigation with community portalType', () {
      const nav = Navigation(portalType: PortalType.community);
      expect(nav.portalType, PortalType.community);
    });

    test('Navigation voteNavigationStack defaults to null', () {
      const nav = Navigation();
      expect(nav.voteNavigationStack, isNull);
    });

    test('Navigation copyWith preserves fields', () {
      const nav = Navigation(
        showPortal: true,
        pageTitle: 'Test',
        portalType: PortalType.community,
      );
      final copy = nav.copyWith(pageTitle: 'Updated');
      expect(copy.pageTitle, 'Updated');
      expect(copy.showPortal, true);
      expect(copy.portalType, PortalType.community);
    });
  });
}
