import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/constatns/constants.dart';
import 'package:picnic_lib/data/models/common/navigation.dart';
import 'package:picnic_lib/data/storage/local_storage.dart';
import 'package:picnic_lib/enums.dart';
import 'package:picnic_lib/navigation_stack.dart';
import 'package:picnic_lib/presentation/pages/community/community_home_page.dart';
import 'package:picnic_lib/presentation/pages/community/goonghap_list_page.dart';
import 'package:picnic_lib/presentation/pages/my_page/my_page.dart';
import 'package:picnic_lib/presentation/pages/pic/pic_home_page.dart';
import 'package:picnic_lib/presentation/pages/signup/login_page.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_home_page.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/screens/community/community_home_screen.dart';
import 'package:picnic_lib/presentation/screens/goong_hap/goong_hap_home_screen.dart';
import 'package:picnic_lib/presentation/screens/novel/novel_home_screen.dart';
import 'package:picnic_lib/presentation/screens/pic/pic_home_screen.dart';
import 'package:picnic_lib/presentation/screens/vote/vote_home_screen.dart';

import '../../helpers/test_environment.dart';

// --------------------------------------------------------------------------
// Fake LocalStorage that records calls without touching SharedPreferences
// --------------------------------------------------------------------------
class FakeLocalStorage implements LocalStorage {
  final Map<String, String> _store = {};

  @override
  Future<void> saveData(String key, String value) async {
    _store[key] = value;
  }

  @override
  Future<String?> loadData(String key, dynamic defaultValue) async {
    return _store[key] ?? defaultValue?.toString();
  }

  @override
  Future<void> removeData(String key) async {
    _store.remove(key);
  }

  @override
  Future<void> clearStorage() async {
    _store.clear();
  }

  /// Retrieve what was stored (for assertions).
  String? operator [](String key) => _store[key];
}

void main() {
  late ProviderContainer container;
  late FakeLocalStorage fakeStorage;

  setUpAll(() {
    initTestColors();
  });

  setUp(() {
    fakeStorage = FakeLocalStorage();
    // Replace the global storage with our fake so calls to saveData
    // don't hit SharedPreferences.
    globalStorage = fakeStorage;

    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  // --------------- helpers ------------------------------------------------

  NavigationInfo notifier() => container.read(navigationInfoProvider.notifier);

  Navigation state() => container.read(navigationInfoProvider);

  // ========================================================================
  // build()
  // ========================================================================
  group('build()', () {
    test('initial state has VoteHomeScreen as currentScreen', () {
      final nav = state();
      expect(nav.currentScreen, isA<VoteHomeScreen>());
    });

    test('initial portalType is vote', () {
      expect(state().portalType, PortalType.vote);
    });

    test('initial navigation flags are all true', () {
      final nav = state();
      expect(nav.showPortal, isTrue);
      expect(nav.showTopMenu, isTrue);
      expect(nav.showBottomNavigation, isTrue);
      expect(nav.showMyPoint, isTrue);
    });

    test('initial voteNavigationStack is not null and has 1 page', () {
      final nav = state();
      expect(nav.voteNavigationStack, isNotNull);
      expect(nav.voteNavigationStack!.length, 1);
    });

    test('initial drawerNavigationStack has MyPage', () {
      final nav = state();
      expect(nav.drawerNavigationStack, isNotNull);
      expect(nav.drawerNavigationStack!.length, 1);
      expect(nav.drawerNavigationStack!.peek(), isA<MyPage>());
    });

    test('initial signUpNavigationStack has LoginPage', () {
      final nav = state();
      expect(nav.signUpNavigationStack, isNotNull);
      expect(nav.signUpNavigationStack!.length, 1);
      expect(nav.signUpNavigationStack!.peek(), isA<LoginPage>());
    });

    test('initial bottom navigation indices are all 0', () {
      final nav = state();
      expect(nav.voteBottomNavigationIndex, 0);
      expect(nav.picBottomNavigationIndex, 0);
      expect(nav.communityBottomNavigationIndex, 0);
      expect(nav.novelBottomNavigationIndex, 0);
    });
  });

  // ========================================================================
  // goBack()
  // ========================================================================
  group('goBack()', () {
    test('pops from voteNavigationStack when length > 1', () async {
      // Push a second page so we can go back
      notifier().setCurrentPage(const Text('Page 2'));
      expect(state().voteNavigationStack!.length, 2);

      await notifier().goBack();

      expect(state().voteNavigationStack!.length, 1);
    });

    test('restores portal/topMenu/bottomNav when returning to root', () async {
      // Hide navigation, push a page, then go back
      notifier().settingNavigation(
        showPortal: false,
        showBottomNavigation: false,
        showTopMenu: false,
      );
      notifier().setCurrentPage(const Text('Deep Page'));
      expect(state().voteNavigationStack!.length, 2);

      await notifier().goBack();

      // At root now (length 1), so flags should be restored to true
      expect(state().showPortal, isTrue);
      expect(state().showTopMenu, isTrue);
      expect(state().showBottomNavigation, isTrue);
    });

    test('currentScreen is updated to the page below', () async {
      final page1 = const SizedBox(key: Key('p1'));
      final page2 = const SizedBox(key: Key('p2'));

      // Replace state with a known stack
      notifier().replaceState(Navigation(
        voteNavigationStack: NavigationStack()
          ..push(page1)
          ..push(page2),
        currentScreen: page2,
      ));

      await notifier().goBack();

      expect(state().currentScreen, same(page1));
    });

    test('does nothing when stack has only 1 page', () async {
      // Initial state already has 1 page
      final lengthBefore = state().voteNavigationStack!.length;
      expect(lengthBefore, 1);

      await notifier().goBack();

      expect(state().voteNavigationStack!.length, lengthBefore);
    });

    test('does nothing when stack is null', () async {
      notifier().replaceState(const Navigation());
      expect(state().voteNavigationStack, isNull);

      // Should not throw
      await notifier().goBack();
    });
  });

  // ========================================================================
  // goBackPic()
  // ========================================================================
  group('goBackPic()', () {
    test('pops from voteNavigationStack when length > 1', () async {
      notifier().setPortal(PortalType.pic);
      notifier().setPicCurrentPage(const Text('PIC Detail'));
      final lengthBefore = state().voteNavigationStack!.length;

      await notifier().goBackPic();

      expect(state().voteNavigationStack!.length, lengthBefore - 1);
    });

    test('does nothing when stack has only 1 page', () async {
      notifier().setPortal(PortalType.pic);
      // setPortal resets stack to 1 page
      expect(state().voteNavigationStack!.length, 1);

      await notifier().goBackPic();

      expect(state().voteNavigationStack!.length, 1);
    });

    test('restores flags when returning to root', () async {
      notifier().setPortal(PortalType.pic);
      notifier().setPicCurrentPage(const Text('PIC Detail'));
      // Flags might have been changed by setPicCurrentPage

      await notifier().goBackPic();

      final isAtRoot = state().voteNavigationStack!.length <= 1;
      if (isAtRoot) {
        expect(state().showPortal, isTrue);
        expect(state().showTopMenu, isTrue);
        expect(state().showBottomNavigation, isTrue);
      }
    });
  });

  // ========================================================================
  // goBackNovel()
  // ========================================================================
  group('goBackNovel()', () {
    test('pops from voteNavigationStack when length > 1', () async {
      notifier().setPortal(PortalType.novel);
      notifier().setNovelCurrentPage(const Text('Novel Detail'));
      final lengthBefore = state().voteNavigationStack!.length;

      await notifier().goBackNovel();

      expect(state().voteNavigationStack!.length, lengthBefore - 1);
    });

    test('does nothing when stack has only 1 page', () async {
      notifier().setPortal(PortalType.novel);
      expect(state().voteNavigationStack!.length, 1);

      await notifier().goBackNovel();

      expect(state().voteNavigationStack!.length, 1);
    });
  });

  // ========================================================================
  // goBackCommunity()
  // ========================================================================
  group('goBackCommunity()', () {
    test('pops from voteNavigationStack when length > 1', () async {
      notifier().setPortal(PortalType.community);
      notifier().setCommunityCurrentPage(const Text('Community Detail'));
      final lengthBefore = state().voteNavigationStack!.length;

      await notifier().goBackCommunity();

      expect(state().voteNavigationStack!.length, lengthBefore - 1);
    });

    test('does nothing when stack has only 1 page', () async {
      notifier().setPortal(PortalType.community);
      expect(state().voteNavigationStack!.length, 1);

      await notifier().goBackCommunity();

      expect(state().voteNavigationStack!.length, 1);
    });
  });

  // ========================================================================
  // goBackMyPage()
  // ========================================================================
  group('goBackMyPage()', () {
    test('pops from drawerNavigationStack when length > 1', () async {
      notifier().setCurrentMyPage(const Text('Settings'));
      expect(state().drawerNavigationStack!.length, 2);

      await notifier().goBackMyPage();

      expect(state().drawerNavigationStack!.length, 1);
    });

    test('does nothing when stack has only 1 page', () async {
      expect(state().drawerNavigationStack!.length, 1);

      await notifier().goBackMyPage();

      expect(state().drawerNavigationStack!.length, 1);
    });

    test('does nothing when stack is null', () async {
      notifier().replaceState(const Navigation());
      expect(state().drawerNavigationStack, isNull);

      // Should not throw
      await notifier().goBackMyPage();
    });
  });

  // ========================================================================
  // goBackSignUp()
  // ========================================================================
  group('goBackSignUp()', () {
    test('pops from signUpNavigationStack when length > 1', () {
      notifier().setCurrentSignUpPage(const Text('Verify'));
      expect(state().signUpNavigationStack!.length, 2);

      notifier().goBackSignUp();

      expect(state().signUpNavigationStack!.length, 1);
    });

    test('does nothing when stack has only 1 page', () {
      expect(state().signUpNavigationStack!.length, 1);

      notifier().goBackSignUp();

      expect(state().signUpNavigationStack!.length, 1);
    });

    test('does nothing when stack is null', () {
      notifier().replaceState(const Navigation());
      expect(state().signUpNavigationStack, isNull);

      // Should not throw
      notifier().goBackSignUp();
    });
  });

  // ========================================================================
  // getScreen()
  // ========================================================================
  group('getScreen()', () {
    test('returns VoteHomeScreen for PortalType.vote', () {
      expect(notifier().getScreen(), isA<VoteHomeScreen>());
    });

    test('returns GoongHapHomeScreen for PortalType.goongHap', () {
      notifier().setPortal(PortalType.goongHap);
      expect(notifier().getScreen(), isA<GoongHapHomeScreen>());
    });

    test('returns PicHomeScreen for PortalType.pic', () {
      notifier().setPortal(PortalType.pic);
      expect(notifier().getScreen(), isA<PicHomeScreen>());
    });

    test('returns CommunityHomeScreen for PortalType.community', () {
      notifier().setPortal(PortalType.community);
      expect(notifier().getScreen(), isA<CommunityHomeScreen>());
    });

    test('returns NovelHomeScreen for PortalType.novel', () {
      notifier().setPortal(PortalType.novel);
      expect(notifier().getScreen(), isA<NovelHomeScreen>());
    });
  });

  // ========================================================================
  // setPortal()
  // ========================================================================
  group('setPortal()', () {
    test('sets portalType to vote and resets stack', () {
      notifier().setPortal(PortalType.pic); // first switch away
      notifier().setPortal(PortalType.vote);

      final nav = state();
      expect(nav.portalType, PortalType.vote);
      expect(nav.currentScreen, isA<VoteHomeScreen>());
      expect(nav.voteBottomNavigationIndex, 0);
      expect(nav.voteNavigationStack, isNotNull);
      expect(nav.voteNavigationStack!.length, 1);
      expect(nav.voteNavigationStack!.peek(), isA<VoteHomePage>());
    });

    test('sets portalType to goongHap', () {
      notifier().setPortal(PortalType.goongHap);

      final nav = state();
      expect(nav.portalType, PortalType.goongHap);
      expect(nav.currentScreen, isA<GoongHapHomeScreen>());
      expect(nav.communityBottomNavigationIndex, 0);
      expect(nav.voteNavigationStack!.peek(), isA<GoonghapListPage>());
    });

    test('sets portalType to pic', () {
      notifier().setPortal(PortalType.pic);

      final nav = state();
      expect(nav.portalType, PortalType.pic);
      expect(nav.currentScreen, isA<PicHomeScreen>());
      expect(nav.picBottomNavigationIndex, 0);
      expect(nav.voteNavigationStack!.peek(), isA<PicHomePage>());
    });

    test('sets portalType to community', () {
      notifier().setPortal(PortalType.community);

      final nav = state();
      expect(nav.portalType, PortalType.community);
      expect(nav.currentScreen, isA<CommunityHomeScreen>());
      expect(nav.communityBottomNavigationIndex, 0);
      expect(nav.voteNavigationStack!.peek(), isA<CommunityHomePage>());
    });

    test('sets portalType to novel', () {
      notifier().setPortal(PortalType.novel);

      final nav = state();
      expect(nav.portalType, PortalType.novel);
      expect(nav.currentScreen, isA<NovelHomeScreen>());
      expect(nav.novelBottomNavigationIndex, 0);
      expect(nav.voteNavigationStack!.length, 1);
    });

    test('saves portal string to globalStorage', () {
      notifier().setPortal(PortalType.pic);
      expect(fakeStorage['portalString'], 'pic');

      notifier().setPortal(PortalType.community);
      expect(fakeStorage['portalString'], 'community');
    });

    test('resets voteNavigationStack to fresh 1-element stack', () {
      // Push extra pages
      notifier().setCurrentPage(const Text('Extra'));
      expect(state().voteNavigationStack!.length, 2);

      // Switch portal -- stack should reset
      notifier().setPortal(PortalType.community);
      expect(state().voteNavigationStack!.length, 1);
    });
  });

  // ========================================================================
  // setShowBottomNavigation()
  // ========================================================================
  group('setShowBottomNavigation()', () {
    test('sets showBottomNavigation to false', () {
      notifier().setShowBottomNavigation(false);
      expect(state().showBottomNavigation, isFalse);
    });

    test('sets showBottomNavigation to true', () {
      notifier().setShowBottomNavigation(false);
      notifier().setShowBottomNavigation(true);
      expect(state().showBottomNavigation, isTrue);
    });
  });

  // ========================================================================
  // getBottomNavigationIndex()
  // ========================================================================
  group('getBottomNavigationIndex()', () {
    test('returns voteBottomNavigationIndex for vote portal', () {
      expect(state().portalType, PortalType.vote);
      expect(notifier().getBottomNavigationIndex(), 0);
    });

    test('returns communityBottomNavigationIndex for goongHap portal', () {
      notifier().setPortal(PortalType.goongHap);
      expect(notifier().getBottomNavigationIndex(), 0);
    });

    test('returns picBottomNavigationIndex for pic portal', () {
      notifier().setPortal(PortalType.pic);
      expect(notifier().getBottomNavigationIndex(), 0);
    });

    test('returns communityBottomNavigationIndex for community portal', () {
      notifier().setPortal(PortalType.community);
      expect(notifier().getBottomNavigationIndex(), 0);
    });

    test('returns novelBottomNavigationIndex for novel portal', () {
      notifier().setPortal(PortalType.novel);
      expect(notifier().getBottomNavigationIndex(), 0);
    });

    test('returns 0 for unknown portal type', () {
      notifier().replaceState(
          const Navigation(portalType: PortalType.mypage));
      expect(notifier().getBottomNavigationIndex(), 0);
    });
  });

  // ========================================================================
  // setBottomNavigationIndex()
  // ========================================================================
  group('setBottomNavigationIndex()', () {
    test('delegates to setVoteBottomNavigationIndex for vote portal', () {
      notifier().setBottomNavigationIndex(1);

      expect(state().voteBottomNavigationIndex, 1);
      expect(fakeStorage['voteBottomNavigationIndex'], '1');
    });

    test('delegates to setCommunityBottomNavigationIndex for goongHap', () {
      notifier().setPortal(PortalType.goongHap);
      // goongHap has only 1 page (index 0), so setting 0 should work
      notifier().setBottomNavigationIndex(0);
      expect(state().communityBottomNavigationIndex, 0);
    });

    test('delegates to setPicBottomNavigationIndex for pic portal', () {
      notifier().setPortal(PortalType.pic);
      notifier().setBottomNavigationIndex(1);

      expect(state().picBottomNavigationIndex, 1);
      expect(fakeStorage['picBottomNavigationIndex'], '1');
    });

    test('delegates to setCommunityBottomNavigationIndex for community', () {
      notifier().setPortal(PortalType.community);
      notifier().setBottomNavigationIndex(1);

      expect(state().communityBottomNavigationIndex, 1);
      expect(fakeStorage['communityBottomNavigationIndex'], '1');
    });

    test('delegates to setNovelBottomNavigationIndex for novel portal', () {
      notifier().setPortal(PortalType.novel);
      notifier().setBottomNavigationIndex(0);

      expect(state().novelBottomNavigationIndex, 0);
      expect(fakeStorage['novelBottomNavigationIndex'], '0');
    });

    test('does nothing for invalid index (out of range)', () {
      final before = state().voteBottomNavigationIndex;
      notifier().setBottomNavigationIndex(99); // No page at index 99
      // NavigationConfigs.getPageWidget returns null, so the setter returns early
      expect(state().voteBottomNavigationIndex, before);
    });
  });

  // ========================================================================
  // settingNavigation()
  // ========================================================================
  group('settingNavigation()', () {
    test('updates all navigation flags', () {
      notifier().settingNavigation(
        showPortal: false,
        showBottomNavigation: false,
        showTopMenu: false,
        showMyPoint: false,
        topRightMenu: TopRightType.board,
        pageTitle: 'Test Title',
      );

      final nav = state();
      expect(nav.showPortal, isFalse);
      expect(nav.showBottomNavigation, isFalse);
      expect(nav.showTopMenu, isFalse);
      expect(nav.showMyPoint, isFalse);
      expect(nav.topRightMenu, TopRightType.board);
      expect(nav.pageTitle, 'Test Title');
    });

    test('uses defaults for optional parameters', () {
      notifier().settingNavigation(
        showPortal: true,
        showBottomNavigation: true,
        showTopMenu: true,
      );

      final nav = state();
      expect(nav.showMyPoint, isTrue);
      expect(nav.topRightMenu, TopRightType.common);
      expect(nav.pageTitle, '');
    });
  });

  // ========================================================================
  // setPageTitle() / setMyPageTitle()
  // ========================================================================
  group('setPageTitle() / setMyPageTitle()', () {
    test('setPageTitle updates pageTitle', () {
      notifier().setPageTitle(pageTitle: 'Hello');
      expect(state().pageTitle, 'Hello');
    });

    test('setMyPageTitle updates myPageTitle', () {
      notifier().setMyPageTitle(pageTitle: 'My Title');
      expect(state().myPageTitle, 'My Title');
    });

    test('setPageTitle does not affect myPageTitle and vice versa', () {
      notifier().setPageTitle(pageTitle: 'Page');
      notifier().setMyPageTitle(pageTitle: 'MyPage');
      expect(state().pageTitle, 'Page');
      expect(state().myPageTitle, 'MyPage');
    });
  });

  // ========================================================================
  // setCurrentPage()
  // ========================================================================
  group('setCurrentPage()', () {
    test('pushes page to voteNavigationStack', () {
      final initialLength = state().voteNavigationStack!.length;
      notifier().setCurrentPage(const Text('New Page'));

      expect(state().voteNavigationStack!.length, initialLength + 1);
    });

    test('updates currentScreen to the pushed page', () {
      const page = Text('New Page');
      notifier().setCurrentPage(page);

      expect(state().currentScreen, same(page));
    });

    test('default showBottomNavigation is true', () {
      notifier().setCurrentPage(const Text('Page'));
      expect(state().showBottomNavigation, isTrue);
    });

    test('can hide bottom navigation', () {
      notifier().setCurrentPage(const Text('Page'), showBottomNavigation: false);
      expect(state().showBottomNavigation, isFalse);
    });

    test('creates new stack if voteNavigationStack is null', () {
      notifier().replaceState(const Navigation());
      expect(state().voteNavigationStack, isNull);

      notifier().setCurrentPage(const Text('Page'));
      expect(state().voteNavigationStack, isNotNull);
      expect(state().voteNavigationStack!.length, 1);
    });
  });

  // ========================================================================
  // pushVotePageKeepScreen()
  // ========================================================================
  group('pushVotePageKeepScreen()', () {
    test('pushes page to stack but does not change currentScreen', () {
      final originalScreen = state().currentScreen;
      notifier().pushVotePageKeepScreen(const Text('Hidden Page'));

      expect(state().voteNavigationStack!.length, 2);
      expect(state().currentScreen, same(originalScreen));
    });

    test('creates new stack if voteNavigationStack is null', () {
      notifier().replaceState(const Navigation(currentScreen: SizedBox()));
      notifier().pushVotePageKeepScreen(const Text('Page'));

      expect(state().voteNavigationStack, isNotNull);
      expect(state().voteNavigationStack!.length, 1);
    });
  });

  // ========================================================================
  // setCommunityCurrentPage()
  // ========================================================================
  group('setCommunityCurrentPage()', () {
    test('pushes page to voteNavigationStack', () {
      notifier().setPortal(PortalType.community);
      final initialLength = state().voteNavigationStack!.length;

      notifier().setCommunityCurrentPage(const Text('Community Detail'));

      expect(state().voteNavigationStack!.length, initialLength + 1);
    });

    test('prevents duplicate push when same type is on top', () {
      notifier().setPortal(PortalType.community);
      notifier().setCommunityCurrentPage(const Text('Detail A'));
      final lengthAfterFirst = state().voteNavigationStack!.length;

      // Same type (Text) is already on top, should skip
      notifier().setCommunityCurrentPage(const Text('Detail B'));
      expect(state().voteNavigationStack!.length, lengthAfterFirst);
    });

    test('allows push of different widget type', () {
      notifier().setPortal(PortalType.community);
      notifier().setCommunityCurrentPage(const Text('Detail'));
      final lengthAfterFirst = state().voteNavigationStack!.length;

      // Different type -- should push
      notifier().setCommunityCurrentPage(const SizedBox());
      expect(state().voteNavigationStack!.length, lengthAfterFirst + 1);
    });

    test('updates currentScreen to the pushed page', () {
      notifier().setPortal(PortalType.community);
      const page = SizedBox(key: Key('comm'));
      notifier().setCommunityCurrentPage(page);
      expect(state().currentScreen, same(page));
    });
  });

  // ========================================================================
  // setPicCurrentPage() / setNovelCurrentPage()
  // ========================================================================
  group('setPicCurrentPage()', () {
    test('pushes page to voteNavigationStack', () {
      notifier().setPortal(PortalType.pic);
      final initialLength = state().voteNavigationStack!.length;

      notifier().setPicCurrentPage(const Text('PIC Detail'));

      expect(state().voteNavigationStack!.length, initialLength + 1);
      expect(state().currentScreen, isA<Text>());
    });
  });

  group('setNovelCurrentPage()', () {
    test('pushes page to voteNavigationStack', () {
      notifier().setPortal(PortalType.novel);
      final initialLength = state().voteNavigationStack!.length;

      notifier().setNovelCurrentPage(const Text('Novel Detail'));

      expect(state().voteNavigationStack!.length, initialLength + 1);
      expect(state().currentScreen, isA<Text>());
    });
  });

  // ========================================================================
  // replaceState()
  // ========================================================================
  group('replaceState()', () {
    test('replaces entire navigation state', () {
      const replacement = Navigation(
        portalType: PortalType.pic,
        pageTitle: 'Replaced',
        showPortal: false,
        showBottomNavigation: false,
      );

      notifier().replaceState(replacement);

      final nav = state();
      expect(nav.portalType, PortalType.pic);
      expect(nav.pageTitle, 'Replaced');
      expect(nav.showPortal, isFalse);
      expect(nav.showBottomNavigation, isFalse);
    });
  });

  // ========================================================================
  // setResetStackMyPage()
  // ========================================================================
  group('setResetStackMyPage()', () {
    test('resets drawerNavigationStack with MyPage', () {
      // First push extra pages
      notifier().setCurrentMyPage(const Text('Settings'));
      notifier().setCurrentMyPage(const Text('About'));
      expect(state().drawerNavigationStack!.length, 3);

      notifier().setResetStackMyPage();

      expect(state().drawerNavigationStack!.length, 1);
      expect(state().drawerNavigationStack!.peek(), isA<MyPage>());
    });
  });

  // ========================================================================
  // setResetStackSignUp()
  // ========================================================================
  group('setResetStackSignUp()', () {
    test('resets signUpNavigationStack with LoginPage', () {
      notifier().setCurrentSignUpPage(const Text('Verify'));
      notifier().setCurrentSignUpPage(const Text('Profile'));
      expect(state().signUpNavigationStack!.length, 3);

      notifier().setResetStackSignUp();

      expect(state().signUpNavigationStack!.length, 1);
      expect(state().signUpNavigationStack!.peek(), isA<LoginPage>());
    });
  });

  // ========================================================================
  // setCurrentMyPage()
  // ========================================================================
  group('setCurrentMyPage()', () {
    test('pushes page to drawerNavigationStack', () {
      notifier().setCurrentMyPage(const Text('Settings'));
      expect(state().drawerNavigationStack!.length, 2);
    });

    test('sets showTopMenu and showBottomNavigation to true', () {
      notifier().settingNavigation(
        showPortal: false,
        showBottomNavigation: false,
        showTopMenu: false,
      );

      notifier().setCurrentMyPage(const Text('Settings'));

      expect(state().showTopMenu, isTrue);
      expect(state().showBottomNavigation, isTrue);
    });

    test('skips push if same page instance is already on top', () {
      // Push a widget, then try pushing the same instance
      final page = const SizedBox(key: Key('same'));
      notifier().setCurrentMyPage(page);
      final lengthAfter = state().drawerNavigationStack!.length;

      // peek() == page uses Widget equality. Const widgets with same key are equal.
      notifier().setCurrentMyPage(page);
      expect(state().drawerNavigationStack!.length, lengthAfter);
    });

    test('does nothing when drawerNavigationStack is null', () {
      notifier().replaceState(const Navigation());
      expect(state().drawerNavigationStack, isNull);

      // Should not throw; push on null stack is a no-op
      notifier().setCurrentMyPage(const Text('Page'));
    });
  });

  // ========================================================================
  // setCurrentSignUpPage()
  // ========================================================================
  group('setCurrentSignUpPage()', () {
    test('pushes page to signUpNavigationStack', () {
      notifier().setCurrentSignUpPage(const Text('Verify'));
      expect(state().signUpNavigationStack!.length, 2);
    });

    test('skips push if same page instance is already on top', () {
      final page = const SizedBox(key: Key('same'));
      notifier().setCurrentSignUpPage(page);
      final lengthAfter = state().signUpNavigationStack!.length;

      notifier().setCurrentSignUpPage(page);
      expect(state().signUpNavigationStack!.length, lengthAfter);
    });

    test('sets showTopMenu and showBottomNavigation to true', () {
      notifier().settingNavigation(
        showPortal: false,
        showBottomNavigation: false,
        showTopMenu: false,
      );

      notifier().setCurrentSignUpPage(const Text('Verify'));

      expect(state().showTopMenu, isTrue);
      expect(state().showBottomNavigation, isTrue);
    });

    test('does nothing when signUpNavigationStack is null', () {
      notifier().replaceState(const Navigation());
      expect(state().signUpNavigationStack, isNull);

      // Should not throw
      notifier().setCurrentSignUpPage(const Text('Page'));
    });
  });

  // ========================================================================
  // Portal-specific bottom navigation index setters
  // ========================================================================
  group('setVoteBottomNavigationIndex()', () {
    test('updates index and resets stack with page widget', () {
      notifier().setPortal(PortalType.vote);
      notifier().setCurrentPage(const Text('Extra'));
      expect(state().voteNavigationStack!.length, 2);

      // Index 1 = CommunityHomePage for vote portal
      notifier().setPortal(PortalType.vote); // reset to known state
      notifier().setBottomNavigationIndex(1);

      expect(state().voteBottomNavigationIndex, 1);
      expect(state().voteNavigationStack!.length, 1);
      expect(fakeStorage['voteBottomNavigationIndex'], '1');
    });

    test('does nothing for invalid index', () {
      notifier().setPortal(PortalType.vote);
      final indexBefore = state().voteBottomNavigationIndex;

      notifier().setBottomNavigationIndex(99);
      expect(state().voteBottomNavigationIndex, indexBefore);
    });
  });

  group('setPicBottomNavigationIndex()', () {
    test('updates index and sets PicHomeScreen as currentScreen', () {
      notifier().setPortal(PortalType.pic);
      notifier().setBottomNavigationIndex(1); // GalleryPage

      expect(state().picBottomNavigationIndex, 1);
      expect(state().currentScreen, isA<PicHomeScreen>());
      expect(fakeStorage['picBottomNavigationIndex'], '1');
    });
  });

  group('setCommunityBottomNavigationIndex()', () {
    test('updates index for community portal', () {
      notifier().setPortal(PortalType.community);
      notifier().setBottomNavigationIndex(1); // BoardListPage

      expect(state().communityBottomNavigationIndex, 1);
      expect(fakeStorage['communityBottomNavigationIndex'], '1');
    });
  });

  group('setNovelBottomNavigationIndex()', () {
    test('updates index and sets NovelHomeScreen as currentScreen', () {
      notifier().setPortal(PortalType.novel);
      notifier().setBottomNavigationIndex(0);

      expect(state().novelBottomNavigationIndex, 0);
      expect(state().currentScreen, isA<NovelHomeScreen>());
      expect(fakeStorage['novelBottomNavigationIndex'], '0');
    });
  });

  // ========================================================================
  // Integration / multi-step scenarios
  // ========================================================================
  group('integration scenarios', () {
    test('push multiple pages then go back through entire stack', () async {
      notifier().setCurrentPage(const Text('Page 2'));
      notifier().setCurrentPage(const Text('Page 3'));
      notifier().setCurrentPage(const Text('Page 4'));
      expect(state().voteNavigationStack!.length, 4);

      await notifier().goBack();
      expect(state().voteNavigationStack!.length, 3);

      await notifier().goBack();
      expect(state().voteNavigationStack!.length, 2);

      await notifier().goBack();
      expect(state().voteNavigationStack!.length, 1);

      // At root -- cannot go further
      await notifier().goBack();
      expect(state().voteNavigationStack!.length, 1);
    });

    test('switching portals resets vote stack', () {
      notifier().setCurrentPage(const Text('Extra Page'));
      expect(state().voteNavigationStack!.length, 2);

      notifier().setPortal(PortalType.pic);
      expect(state().voteNavigationStack!.length, 1);
      expect(state().portalType, PortalType.pic);

      notifier().setPortal(PortalType.vote);
      expect(state().voteNavigationStack!.length, 1);
      expect(state().portalType, PortalType.vote);
    });

    test('goBack after settingNavigation restores flags at root', () async {
      notifier().setCurrentPage(const Text('Detail'));
      notifier().settingNavigation(
        showPortal: false,
        showBottomNavigation: false,
        showTopMenu: false,
      );

      await notifier().goBack();

      // Back at root (length 1), flags restored
      expect(state().showPortal, isTrue);
      expect(state().showTopMenu, isTrue);
      expect(state().showBottomNavigation, isTrue);
    });

    test('drawer and signup stacks are independent of vote stack', () {
      notifier().setCurrentPage(const Text('Vote Detail'));
      notifier().setCurrentMyPage(const Text('MyPage Detail'));
      notifier().setCurrentSignUpPage(const Text('SignUp Step'));

      expect(state().voteNavigationStack!.length, 2);
      expect(state().drawerNavigationStack!.length, 2);
      expect(state().signUpNavigationStack!.length, 2);
    });
  });
}
