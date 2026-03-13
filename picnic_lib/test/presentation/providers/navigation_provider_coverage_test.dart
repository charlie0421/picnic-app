import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/constatns/constants.dart';
import 'package:picnic_lib/data/models/common/navigation.dart';
import 'package:picnic_lib/data/storage/local_storage.dart';
import 'package:picnic_lib/enums.dart';
import 'package:picnic_lib/navigation_stack.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/screens/vote/vote_home_screen.dart';

import '../../helpers/test_environment.dart';

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
    globalStorage = fakeStorage;
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  NavigationInfo notifier() => container.read(navigationInfoProvider.notifier);
  Navigation state() => container.read(navigationInfoProvider);

  group('setPortal - default/mypage case', () {
    test('setPortal with PortalType.mypage falls back to VoteHomeScreen', () {
      notifier().setPortal(PortalType.mypage);

      final nav = state();
      expect(nav.portalType, PortalType.mypage);
      expect(nav.currentScreen, isA<VoteHomeScreen>());
      expect(fakeStorage['portalString'], 'mypage');
    });
  });

  group('getScreen - default case', () {
    test('getScreen returns VoteHomeScreen for mypage portal type', () {
      notifier().replaceState(const Navigation(portalType: PortalType.mypage));
      expect(notifier().getScreen(), isA<VoteHomeScreen>());
    });
  });

  group('setBottomNavigationIndex - novel portal', () {
    test('delegates to setNovelBottomNavigationIndex for novel portal', () {
      notifier().setPortal(PortalType.novel);
      notifier().setBottomNavigationIndex(0);
      expect(state().novelBottomNavigationIndex, 0);
    });
  });

  group('setBottomNavigationIndex - mypage does nothing', () {
    test('setBottomNavigationIndex does nothing for mypage portal', () {
      notifier().replaceState(const Navigation(portalType: PortalType.mypage));
      final stateBefore = state();
      notifier().setBottomNavigationIndex(1);
      // Nothing should change for unknown portal type
      expect(state().voteBottomNavigationIndex,
          stateBefore.voteBottomNavigationIndex);
    });
  });

  group('goBackNovel - null stack', () {
    test('goBackNovel does nothing when stack is null', () async {
      notifier().replaceState(const Navigation());
      expect(state().voteNavigationStack, isNull);
      await notifier().goBackNovel();
      // No exception thrown
    });
  });

  group('goBackPic - null stack', () {
    test('goBackPic does nothing when stack is null', () async {
      notifier().replaceState(const Navigation());
      expect(state().voteNavigationStack, isNull);
      await notifier().goBackPic();
    });
  });

  group('goBackCommunity - null stack', () {
    test('goBackCommunity does nothing when stack is null', () async {
      notifier().replaceState(const Navigation());
      expect(state().voteNavigationStack, isNull);
      await notifier().goBackCommunity();
    });
  });

  group('goBack non-root preserves flags', () {
    test('goBack at non-root keeps existing flag values', () async {
      // Push 3 pages so after going back we are still NOT at root
      notifier().setCurrentPage(const Text('Page 2'));
      notifier().setCurrentPage(const Text('Page 3'));
      expect(state().voteNavigationStack!.length, 3);

      // Hide navigation
      notifier().settingNavigation(
        showPortal: false,
        showBottomNavigation: false,
        showTopMenu: false,
      );

      await notifier().goBack();
      // Still at depth 2, not root
      expect(state().voteNavigationStack!.length, 2);
      expect(state().showPortal, isFalse);
    });
  });

  group('setPicCurrentPage - null stack creates new one', () {
    test('setPicCurrentPage creates stack when null', () {
      notifier().replaceState(const Navigation());
      expect(state().voteNavigationStack, isNull);

      notifier().setPicCurrentPage(const Text('PIC Page'));
      expect(state().voteNavigationStack, isNotNull);
      expect(state().voteNavigationStack!.length, 1);
    });
  });

  group('setNovelCurrentPage - null stack creates new one', () {
    test('setNovelCurrentPage creates stack when null', () {
      notifier().replaceState(const Navigation());
      expect(state().voteNavigationStack, isNull);

      notifier().setNovelCurrentPage(const Text('Novel Page'));
      expect(state().voteNavigationStack, isNotNull);
      expect(state().voteNavigationStack!.length, 1);
    });
  });

  group('setCommunityCurrentPage - null stack creates new one', () {
    test('setCommunityCurrentPage creates stack when null', () {
      notifier().replaceState(const Navigation());
      expect(state().voteNavigationStack, isNull);

      notifier().setCommunityCurrentPage(const Text('Community Page'));
      expect(state().voteNavigationStack, isNotNull);
      expect(state().voteNavigationStack!.length, 1);
    });

    test('setCommunityCurrentPage skips when empty stack has same type on top',
        () {
      // Set up with a page already on top
      notifier().setPortal(PortalType.community);
      notifier().setCommunityCurrentPage(const SizedBox());
      final len = state().voteNavigationStack!.length;

      // Same type on top -- should be skipped
      notifier().setCommunityCurrentPage(const SizedBox());
      expect(state().voteNavigationStack!.length, len);
    });
  });
}
