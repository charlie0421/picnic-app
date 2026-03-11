import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/common/navigation.dart';
import 'package:picnic_lib/data/models/navigator/navigation_configs.dart';
import 'package:picnic_lib/enums.dart';
import 'package:picnic_lib/extensions/portal_type_extension.dart';
import 'package:picnic_lib/navigation_stack.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';

import '../../helpers/test_environment.dart';

void main() {
  setUpAll(() {
    initTestColors();
  });
  group('NavigationStack', () {
    test('empty stack', () {
      final stack = NavigationStack();
      expect(stack.isEmpty, isTrue);
      expect(stack.length, 0);
    });

    test('push and peek', () {
      final stack = NavigationStack();
      const widget = Text('test');
      stack.push(widget);
      expect(stack.isEmpty, isFalse);
      expect(stack.length, 1);
      expect(stack.peek(), widget);
    });

    test('push multiple and pop', () {
      final stack = NavigationStack();
      const w1 = Text('first');
      const w2 = Text('second');
      stack.push(w1);
      stack.push(w2);
      expect(stack.length, 2);
      expect(stack.pop(), w2);
      expect(stack.pop(), w1);
      expect(stack.isEmpty, isTrue);
    });

    test('pop on empty stack throws StateError', () {
      final stack = NavigationStack();
      expect(() => stack.pop(), throwsStateError);
    });

    test('peek on empty stack throws StateError', () {
      final stack = NavigationStack();
      expect(() => stack.peek(), throwsStateError);
    });

    test('initialPage constructor', () {
      const widget = Text('initial');
      final stack = NavigationStack(initialPage: widget);
      expect(stack.length, 1);
      expect(stack.peek(), widget);
    });

    test('clear', () {
      final stack = NavigationStack();
      stack.push(const Text('a'));
      stack.push(const Text('b'));
      stack.clear();
      expect(stack.isEmpty, isTrue);
      expect(stack.length, 0);
    });

    test('items returns unmodifiable list', () {
      final stack = NavigationStack();
      stack.push(const Text('x'));
      final items = stack.items;
      expect(items.length, 1);
      expect(() => items.add(const Text('y')), throwsUnsupportedError);
    });

    test('toString', () {
      final stack = NavigationStack();
      stack.push(const Text('item'));
      expect(stack.toString(), isNotEmpty);
    });
  });

  group('Navigation', () {
    test('default constructor', () {
      const nav = Navigation();
      expect(nav.portalType, PortalType.vote);
      expect(nav.showPortal, isTrue);
      expect(nav.showTopMenu, isTrue);
      expect(nav.showMyPoint, isTrue);
      expect(nav.showBottomNavigation, isTrue);
      expect(nav.topRightMenu, TopRightType.common);
      expect(nav.pageTitle, '');
      expect(nav.myPageTitle, '');
      expect(nav.picBottomNavigationIndex, 0);
      expect(nav.voteBottomNavigationIndex, 0);
      expect(nav.communityBottomNavigationIndex, 0);
      expect(nav.novelBottomNavigationIndex, 0);
    });

    test('copyWith', () {
      const nav = Navigation();
      final updated = nav.copyWith(
        portalType: PortalType.pic,
        showPortal: false,
        showTopMenu: false,
        showMyPoint: false,
        showBottomNavigation: false,
        topRightMenu: TopRightType.board,
        pageTitle: 'Test Page',
        myPageTitle: 'My Title',
        picBottomNavigationIndex: 1,
        voteBottomNavigationIndex: 2,
        communityBottomNavigationIndex: 3,
        novelBottomNavigationIndex: 4,
      );
      expect(updated.portalType, PortalType.pic);
      expect(updated.showPortal, isFalse);
      expect(updated.showTopMenu, isFalse);
      expect(updated.showMyPoint, isFalse);
      expect(updated.showBottomNavigation, isFalse);
      expect(updated.topRightMenu, TopRightType.board);
      expect(updated.pageTitle, 'Test Page');
      expect(updated.myPageTitle, 'My Title');
      expect(updated.picBottomNavigationIndex, 1);
      expect(updated.voteBottomNavigationIndex, 2);
      expect(updated.communityBottomNavigationIndex, 3);
      expect(updated.novelBottomNavigationIndex, 4);
    });

    test('copyWith preserves unchanged values', () {
      const nav = Navigation(
        portalType: PortalType.community,
        pageTitle: 'Original',
      );
      final updated = nav.copyWith(showPortal: false);
      expect(updated.portalType, PortalType.community);
      expect(updated.pageTitle, 'Original');
      expect(updated.showPortal, isFalse);
    });

    test('initial factory', () {
      final nav = Navigation.initial();
      expect(nav.voteNavigationStack, isNotNull);
      expect(nav.voteNavigationStack!.length, 1);
      expect(nav.drawerNavigationStack, isNotNull);
      expect(nav.signUpNavigationStack, isNotNull);
    });

    test('getBottomNavigationIndex for vote', () {
      const nav = Navigation(
        portalType: PortalType.vote,
        voteBottomNavigationIndex: 3,
      );
      expect(nav.getBottomNavigationIndex(), 3);
    });

    test('getBottomNavigationIndex for pic', () {
      const nav = Navigation(
        portalType: PortalType.pic,
        picBottomNavigationIndex: 2,
      );
      expect(nav.getBottomNavigationIndex(), 2);
    });

    test('getBottomNavigationIndex for goongHap', () {
      const nav = Navigation(
        portalType: PortalType.goongHap,
        communityBottomNavigationIndex: 1,
      );
      expect(nav.getBottomNavigationIndex(), 1);
    });

    test('getBottomNavigationIndex for community', () {
      const nav = Navigation(
        portalType: PortalType.community,
        communityBottomNavigationIndex: 2,
      );
      expect(nav.getBottomNavigationIndex(), 2);
    });

    test('getBottomNavigationIndex for novel', () {
      const nav = Navigation(
        portalType: PortalType.novel,
        novelBottomNavigationIndex: 1,
      );
      expect(nav.getBottomNavigationIndex(), 1);
    });

    test('getBottomNavigationIndex for mypage returns 0', () {
      const nav = Navigation(portalType: PortalType.mypage);
      expect(nav.getBottomNavigationIndex(), 0);
    });
  });

  group('TopRightType', () {
    test('all values exist', () {
      expect(TopRightType.values.length, 5);
      expect(TopRightType.values, contains(TopRightType.none));
      expect(TopRightType.values, contains(TopRightType.common));
      expect(TopRightType.values, contains(TopRightType.board));
      expect(TopRightType.values, contains(TopRightType.postView));
      expect(TopRightType.values, contains(TopRightType.community));
    });
  });

  group('PortalType', () {
    test('all values exist', () {
      expect(PortalType.values.length, 6);
    });
  });

  group('PortalTypeExtension', () {
    test('stringValue', () {
      expect(PortalType.vote.stringValue, 'vote');
      expect(PortalType.goongHap.stringValue, 'goongHap');
      expect(PortalType.pic.stringValue, 'pic');
      expect(PortalType.community.stringValue, 'community');
      expect(PortalType.novel.stringValue, 'novel');
      expect(PortalType.mypage.stringValue, 'mypage');
    });

    test('fromString', () {
      expect(PortalTypeExtension.fromString('vote'), PortalType.vote);
      expect(PortalTypeExtension.fromString('goongHap'), PortalType.goongHap);
      expect(PortalTypeExtension.fromString('pic'), PortalType.pic);
      expect(PortalTypeExtension.fromString('community'), PortalType.community);
      expect(PortalTypeExtension.fromString('novel'), PortalType.novel);
      expect(PortalTypeExtension.fromString('mypage'), PortalType.mypage);
    });

    test('fromString unknown throws', () {
      expect(() => PortalTypeExtension.fromString('unknown'), throwsException);
    });
  });

  group('PolicyLanguage', () {
    test('text property', () {
      expect(PolicyLanguage.en.text, 'en');
      expect(PolicyLanguage.ko.text, 'ko');
    });
  });

  group('PolicyType', () {
    test('all values', () {
      expect(PolicyType.values.length, 3);
      expect(PolicyType.values, contains(PolicyType.privacy));
      expect(PolicyType.values, contains(PolicyType.terms));
      expect(PolicyType.values, contains(PolicyType.withdraw));
    });
  });

  group('Gender', () {
    test('all values', () {
      expect(Gender.values.length, 2);
      expect(Gender.values, contains(Gender.male));
      expect(Gender.values, contains(Gender.female));
    });
  });

  group('VoteStatus', () {
    test('all values', () {
      expect(VoteStatus.values.length, 6);
      expect(VoteStatus.values, contains(VoteStatus.all));
      expect(VoteStatus.values, contains(VoteStatus.active));
      expect(VoteStatus.values, contains(VoteStatus.end));
      expect(VoteStatus.values, contains(VoteStatus.upcoming));
      expect(VoteStatus.values, contains(VoteStatus.activeAndUpcoming));
      expect(VoteStatus.values, contains(VoteStatus.debug));
    });
  });

  group('VoteCategory', () {
    test('all values', () {
      expect(VoteCategory.values.length, 7);
      expect(VoteCategory.values, contains(VoteCategory.all));
      expect(VoteCategory.values, contains(VoteCategory.birthday));
      expect(VoteCategory.values, contains(VoteCategory.comeback));
      expect(VoteCategory.values, contains(VoteCategory.achieve));
    });
  });

  group('VotePortal', () {
    test('all values', () {
      expect(VotePortal.values.length, 2);
      expect(VotePortal.values, contains(VotePortal.vote));
      expect(VotePortal.values, contains(VotePortal.pic));
    });
  });

  group('NavigationConfigs', () {
    test('getScreenInfo for vote', () {
      final info = NavigationConfigs.getScreenInfo(PortalType.vote);
      expect(info, isNotNull);
      expect(info!.type, PortalType.vote);
    });

    test('getScreenInfo for pic', () {
      final info = NavigationConfigs.getScreenInfo(PortalType.pic);
      expect(info, isNotNull);
      expect(info!.type, PortalType.pic);
    });

    test('getScreenInfo for community', () {
      final info = NavigationConfigs.getScreenInfo(PortalType.community);
      expect(info, isNotNull);
    });

    test('getScreenInfo for goongHap', () {
      final info = NavigationConfigs.getScreenInfo(PortalType.goongHap);
      expect(info, isNotNull);
    });

    test('getScreenInfo for novel', () {
      final info = NavigationConfigs.getScreenInfo(PortalType.novel);
      expect(info, isNotNull);
    });

    test('getScreenInfo for mypage returns null', () {
      final info = NavigationConfigs.getScreenInfo(PortalType.mypage);
      expect(info, isNull);
    });

    test('getPages returns pages for vote', () {
      final pages = NavigationConfigs.getPages(PortalType.vote);
      expect(pages.length, 4);
      expect(pages[0].title, 'nav_vote');
    });

    test('getPages for unknown portal returns empty', () {
      final pages = NavigationConfigs.getPages(PortalType.mypage);
      expect(pages, isEmpty);
    });

    test('getPageWidget valid index', () {
      final widget = NavigationConfigs.getPageWidget(PortalType.vote, 0);
      expect(widget, isNotNull);
    });

    test('getPageWidget invalid index returns null', () {
      final widget = NavigationConfigs.getPageWidget(PortalType.vote, 99);
      expect(widget, isNull);
    });

    test('getPageWidget negative index returns null', () {
      final widget = NavigationConfigs.getPageWidget(PortalType.vote, -1);
      expect(widget, isNull);
    });

    test('screenInfoMap returns string-keyed map', () {
      final map = NavigationConfigs.screenInfoMap;
      expect(map.containsKey('vote'), isTrue);
      expect(map.containsKey('pic'), isTrue);
      expect(map.containsKey('community'), isTrue);
    });
  });
}
