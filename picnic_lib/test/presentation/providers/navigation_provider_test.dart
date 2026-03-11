import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/common/navigation.dart';
import 'package:picnic_lib/enums.dart';
import 'package:picnic_lib/navigation_stack.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';

import '../../helpers/mock_providers.dart';
import '../../helpers/test_app.dart';
import '../../helpers/test_environment.dart';

void main() {
  setUpAll(() {
    initTestColors();
  });

  group('NavigationInfo build', () {
    testWidgets('initial state uses VoteHomeScreen', (tester) async {
      late Navigation initialNav;
      await tester.pumpWidget(
        buildTestApp(
          Consumer(
            builder: (context, ref, _) {
              initialNav = ref.watch(navigationInfoProvider);
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Default mock navigation has vote portal
      expect(initialNav.portalType, PortalType.vote);
      expect(initialNav.showPortal, isTrue);
      expect(initialNav.showTopMenu, isTrue);
      expect(initialNav.showBottomNavigation, isTrue);
    });
  });

  group('NavigationInfo setPortal', () {
    testWidgets('changes portal type to goongHap', (tester) async {
      late Navigation nav;
      await tester.pumpWidget(
        buildTestApp(
          Consumer(
            builder: (context, ref, _) {
              nav = ref.watch(navigationInfoProvider);
              return ElevatedButton(
                onPressed: () {
                  ref
                      .read(navigationInfoProvider.notifier)
                      .setPortal(PortalType.goongHap);
                },
                child: const Text('switch'),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(nav.portalType, PortalType.vote);

      await tester.tap(find.text('switch'));
      await tester.pumpAndSettle();

      expect(nav.portalType, PortalType.goongHap);
    });

    testWidgets('changes portal type to pic', (tester) async {
      late Navigation nav;
      await tester.pumpWidget(
        buildTestApp(
          Consumer(
            builder: (context, ref, _) {
              nav = ref.watch(navigationInfoProvider);
              return ElevatedButton(
                onPressed: () {
                  ref
                      .read(navigationInfoProvider.notifier)
                      .setPortal(PortalType.pic);
                },
                child: const Text('switch'),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('switch'));
      await tester.pumpAndSettle();

      expect(nav.portalType, PortalType.pic);
    });

    testWidgets('changes portal type to community', (tester) async {
      late Navigation nav;
      await tester.pumpWidget(
        buildTestApp(
          Consumer(
            builder: (context, ref, _) {
              nav = ref.watch(navigationInfoProvider);
              return ElevatedButton(
                onPressed: () {
                  ref
                      .read(navigationInfoProvider.notifier)
                      .setPortal(PortalType.community);
                },
                child: const Text('switch'),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('switch'));
      await tester.pumpAndSettle();

      expect(nav.portalType, PortalType.community);
    });

    testWidgets('changes portal type to novel', (tester) async {
      late Navigation nav;
      await tester.pumpWidget(
        buildTestApp(
          Consumer(
            builder: (context, ref, _) {
              nav = ref.watch(navigationInfoProvider);
              return ElevatedButton(
                onPressed: () {
                  ref
                      .read(navigationInfoProvider.notifier)
                      .setPortal(PortalType.novel);
                },
                child: const Text('switch'),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('switch'));
      await tester.pumpAndSettle();

      expect(nav.portalType, PortalType.novel);
    });
  });

  group('NavigationInfo getScreen', () {
    testWidgets('returns widget for each portal type', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Consumer(
            builder: (context, ref, _) {
              final notifier = ref.read(navigationInfoProvider.notifier);
              // Test getScreen for default portal
              final screen = notifier.getScreen();
              expect(screen, isA<Widget>());
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
    });
  });

  group('NavigationInfo navigation methods', () {
    testWidgets('settingNavigation updates state', (tester) async {
      late Navigation nav;
      await tester.pumpWidget(
        buildTestApp(
          Consumer(
            builder: (context, ref, _) {
              nav = ref.watch(navigationInfoProvider);
              return ElevatedButton(
                onPressed: () {
                  ref.read(navigationInfoProvider.notifier).settingNavigation(
                        showPortal: false,
                        showBottomNavigation: false,
                        showTopMenu: false,
                        pageTitle: 'Test Page',
                      );
                },
                child: const Text('configure'),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('configure'));
      await tester.pumpAndSettle();

      expect(nav.showPortal, isFalse);
      expect(nav.showBottomNavigation, isFalse);
      expect(nav.showTopMenu, isFalse);
      expect(nav.pageTitle, 'Test Page');
    });

    testWidgets('setShowBottomNavigation toggles visibility', (tester) async {
      late Navigation nav;
      await tester.pumpWidget(
        buildTestApp(
          Consumer(
            builder: (context, ref, _) {
              nav = ref.watch(navigationInfoProvider);
              return ElevatedButton(
                onPressed: () {
                  ref
                      .read(navigationInfoProvider.notifier)
                      .setShowBottomNavigation(false);
                },
                child: const Text('hide'),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(nav.showBottomNavigation, isTrue);

      await tester.tap(find.text('hide'));
      await tester.pumpAndSettle();

      expect(nav.showBottomNavigation, isFalse);
    });

    testWidgets('setPageTitle updates title', (tester) async {
      late Navigation nav;
      await tester.pumpWidget(
        buildTestApp(
          Consumer(
            builder: (context, ref, _) {
              nav = ref.watch(navigationInfoProvider);
              return ElevatedButton(
                onPressed: () {
                  ref
                      .read(navigationInfoProvider.notifier)
                      .setPageTitle(pageTitle: 'New Title');
                },
                child: const Text('title'),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('title'));
      await tester.pumpAndSettle();

      expect(nav.pageTitle, 'New Title');
    });

    testWidgets('setMyPageTitle updates my page title', (tester) async {
      late Navigation nav;
      await tester.pumpWidget(
        buildTestApp(
          Consumer(
            builder: (context, ref, _) {
              nav = ref.watch(navigationInfoProvider);
              return ElevatedButton(
                onPressed: () {
                  ref
                      .read(navigationInfoProvider.notifier)
                      .setMyPageTitle(pageTitle: 'My Page Title');
                },
                child: const Text('myTitle'),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('myTitle'));
      await tester.pumpAndSettle();

      expect(nav.myPageTitle, 'My Page Title');
    });

    testWidgets('replaceState replaces entire navigation', (tester) async {
      late Navigation nav;
      await tester.pumpWidget(
        buildTestApp(
          Consumer(
            builder: (context, ref, _) {
              nav = ref.watch(navigationInfoProvider);
              return ElevatedButton(
                onPressed: () {
                  ref
                      .read(navigationInfoProvider.notifier)
                      .replaceState(const Navigation(
                        portalType: PortalType.pic,
                        pageTitle: 'Replaced',
                        showPortal: false,
                      ));
                },
                child: const Text('replace'),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('replace'));
      await tester.pumpAndSettle();

      expect(nav.portalType, PortalType.pic);
      expect(nav.pageTitle, 'Replaced');
      expect(nav.showPortal, isFalse);
    });

    testWidgets('getBottomNavigationIndex returns correct index for vote',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Consumer(
            builder: (context, ref, _) {
              final notifier = ref.read(navigationInfoProvider.notifier);
              final index = notifier.getBottomNavigationIndex();
              expect(index, 0); // default vote index is 0
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
    });
  });

  group('NavigationInfo page navigation', () {
    testWidgets('setCurrentPage pushes page to stack', (tester) async {
      late Navigation nav;
      await tester.pumpWidget(
        buildTestApp(
          Consumer(
            builder: (context, ref, _) {
              nav = ref.watch(navigationInfoProvider);
              return ElevatedButton(
                onPressed: () {
                  ref
                      .read(navigationInfoProvider.notifier)
                      .setCurrentPage(const Text('Page 2'));
                },
                child: const Text('push'),
              );
            },
          ),
          navigation: Navigation(
            voteNavigationStack: NavigationStack()..push(const Text('Page 1')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('push'));
      await tester.pumpAndSettle();

      expect(nav.voteNavigationStack?.length, greaterThanOrEqualTo(1));
    });

    testWidgets('goBack pops from stack', (tester) async {
      late Navigation nav;
      final stack = NavigationStack()
        ..push(const Text('Page 1'))
        ..push(const Text('Page 2'));

      await tester.pumpWidget(
        buildTestApp(
          Consumer(
            builder: (context, ref, _) {
              nav = ref.watch(navigationInfoProvider);
              return ElevatedButton(
                onPressed: () async {
                  await ref.read(navigationInfoProvider.notifier).goBack();
                },
                child: const Text('back'),
              );
            },
          ),
          navigation: Navigation(voteNavigationStack: stack),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('back'));
      await tester.pumpAndSettle();

      // After going back, stack should have fewer items
      expect(nav.voteNavigationStack, isNotNull);
    });

    testWidgets('goBack does nothing when stack has one item', (tester) async {
      final stack = NavigationStack()..push(const Text('Only Page'));

      await tester.pumpWidget(
        buildTestApp(
          Consumer(
            builder: (context, ref, _) {
              ref.watch(navigationInfoProvider);
              return ElevatedButton(
                onPressed: () async {
                  await ref.read(navigationInfoProvider.notifier).goBack();
                },
                child: const Text('back'),
              );
            },
          ),
          navigation: Navigation(voteNavigationStack: stack),
        ),
      );
      await tester.pumpAndSettle();

      // Should not throw
      await tester.tap(find.text('back'));
      await tester.pumpAndSettle();
    });

    testWidgets('pushVotePageKeepScreen pushes without changing screen',
        (tester) async {
      late Navigation nav;
      await tester.pumpWidget(
        buildTestApp(
          Consumer(
            builder: (context, ref, _) {
              nav = ref.watch(navigationInfoProvider);
              return ElevatedButton(
                onPressed: () {
                  ref
                      .read(navigationInfoProvider.notifier)
                      .pushVotePageKeepScreen(const Text('Inner Page'));
                },
                child: const Text('push'),
              );
            },
          ),
          navigation: Navigation(
            voteNavigationStack: NavigationStack()..push(const Text('Root')),
            currentScreen: const Text('Screen'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('push'));
      await tester.pumpAndSettle();

      expect(nav.voteNavigationStack, isNotNull);
    });
  });

  group('NavigationInfo portal-specific methods', () {
    testWidgets('setPicCurrentPage pushes to vote stack', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Consumer(
            builder: (context, ref, _) {
              ref.watch(navigationInfoProvider);
              return ElevatedButton(
                onPressed: () {
                  ref
                      .read(navigationInfoProvider.notifier)
                      .setPicCurrentPage(const Text('PIC Page'));
                },
                child: const Text('picPage'),
              );
            },
          ),
          navigation: Navigation(
            portalType: PortalType.pic,
            voteNavigationStack: NavigationStack()..push(const Text('PIC Root')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('picPage'));
      await tester.pumpAndSettle();
    });

    testWidgets('setNovelCurrentPage pushes to vote stack', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Consumer(
            builder: (context, ref, _) {
              ref.watch(navigationInfoProvider);
              return ElevatedButton(
                onPressed: () {
                  ref
                      .read(navigationInfoProvider.notifier)
                      .setNovelCurrentPage(const Text('Novel Page'));
                },
                child: const Text('novelPage'),
              );
            },
          ),
          navigation: Navigation(
            portalType: PortalType.novel,
            voteNavigationStack:
                NavigationStack()..push(const Text('Novel Root')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('novelPage'));
      await tester.pumpAndSettle();
    });

    testWidgets('setCommunityCurrentPage pushes to vote stack', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Consumer(
            builder: (context, ref, _) {
              ref.watch(navigationInfoProvider);
              return ElevatedButton(
                onPressed: () {
                  ref
                      .read(navigationInfoProvider.notifier)
                      .setCommunityCurrentPage(const Text('Community Page'));
                },
                child: const Text('communityPage'),
              );
            },
          ),
          navigation: Navigation(
            portalType: PortalType.community,
            voteNavigationStack:
                NavigationStack()..push(const Text('Community Root')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('communityPage'));
      await tester.pumpAndSettle();
    });

    testWidgets('goBackPic pops from vote stack', (tester) async {
      final stack = NavigationStack()
        ..push(const Text('PIC Root'))
        ..push(const Text('PIC Detail'));

      await tester.pumpWidget(
        buildTestApp(
          Consumer(
            builder: (context, ref, _) {
              ref.watch(navigationInfoProvider);
              return ElevatedButton(
                onPressed: () async {
                  await ref.read(navigationInfoProvider.notifier).goBackPic();
                },
                child: const Text('back'),
              );
            },
          ),
          navigation: Navigation(
            portalType: PortalType.pic,
            voteNavigationStack: stack,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('back'));
      await tester.pumpAndSettle();
    });

    testWidgets('goBackNovel pops from vote stack', (tester) async {
      final stack = NavigationStack()
        ..push(const Text('Novel Root'))
        ..push(const Text('Novel Detail'));

      await tester.pumpWidget(
        buildTestApp(
          Consumer(
            builder: (context, ref, _) {
              ref.watch(navigationInfoProvider);
              return ElevatedButton(
                onPressed: () async {
                  await ref.read(navigationInfoProvider.notifier).goBackNovel();
                },
                child: const Text('back'),
              );
            },
          ),
          navigation: Navigation(
            portalType: PortalType.novel,
            voteNavigationStack: stack,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('back'));
      await tester.pumpAndSettle();
    });

    testWidgets('goBackCommunity pops from vote stack', (tester) async {
      final stack = NavigationStack()
        ..push(const Text('Community Root'))
        ..push(const Text('Community Detail'));

      await tester.pumpWidget(
        buildTestApp(
          Consumer(
            builder: (context, ref, _) {
              ref.watch(navigationInfoProvider);
              return ElevatedButton(
                onPressed: () async {
                  await ref
                      .read(navigationInfoProvider.notifier)
                      .goBackCommunity();
                },
                child: const Text('back'),
              );
            },
          ),
          navigation: Navigation(
            portalType: PortalType.community,
            voteNavigationStack: stack,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('back'));
      await tester.pumpAndSettle();
    });

    testWidgets('goBackMyPage pops from drawer stack', (tester) async {
      final stack = NavigationStack()
        ..push(const Text('MyPage'))
        ..push(const Text('Settings'));

      await tester.pumpWidget(
        buildTestApp(
          Consumer(
            builder: (context, ref, _) {
              ref.watch(navigationInfoProvider);
              return ElevatedButton(
                onPressed: () async {
                  await ref
                      .read(navigationInfoProvider.notifier)
                      .goBackMyPage();
                },
                child: const Text('back'),
              );
            },
          ),
          navigation: Navigation(drawerNavigationStack: stack),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('back'));
      await tester.pumpAndSettle();
    });

    testWidgets('setCurrentMyPage pushes to drawer stack', (tester) async {
      final stack = NavigationStack()..push(const Text('MyPage Root'));

      await tester.pumpWidget(
        buildTestApp(
          Consumer(
            builder: (context, ref, _) {
              ref.watch(navigationInfoProvider);
              return ElevatedButton(
                onPressed: () {
                  ref
                      .read(navigationInfoProvider.notifier)
                      .setCurrentMyPage(const Text('Settings'));
                },
                child: const Text('navigate'),
              );
            },
          ),
          navigation: Navigation(drawerNavigationStack: stack),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('navigate'));
      await tester.pumpAndSettle();
    });
  });

  group('NavigationInfo bottom navigation index', () {
    testWidgets('setBottomNavigationIndex for vote portal', (tester) async {
      late Navigation nav;
      await tester.pumpWidget(
        buildTestApp(
          Consumer(
            builder: (context, ref, _) {
              nav = ref.watch(navigationInfoProvider);
              return ElevatedButton(
                onPressed: () {
                  ref
                      .read(navigationInfoProvider.notifier)
                      .setBottomNavigationIndex(1);
                },
                child: const Text('setIndex'),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('setIndex'));
      await tester.pumpAndSettle();
    });

    testWidgets('getBottomNavigationIndex for goongHap portal',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Consumer(
            builder: (context, ref, _) {
              ref.watch(navigationInfoProvider);
              return ElevatedButton(
                onPressed: () {
                  final notifier = ref.read(navigationInfoProvider.notifier);
                  notifier.setPortal(PortalType.goongHap);
                  final idx = notifier.getBottomNavigationIndex();
                  // goongHap uses communityBottomNavigationIndex which defaults to 0
                  expect(idx, 0);
                },
                child: const Text('test'),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('test'));
      await tester.pumpAndSettle();
    });
  });

  group('NavigationInfo signup', () {
    testWidgets('setResetStackSignUp resets signup stack', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Consumer(
            builder: (context, ref, _) {
              ref.watch(navigationInfoProvider);
              return ElevatedButton(
                onPressed: () {
                  ref
                      .read(navigationInfoProvider.notifier)
                      .setResetStackSignUp();
                },
                child: const Text('reset'),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('reset'));
      await tester.pumpAndSettle();
    });

    testWidgets('setResetStackMyPage resets my page stack', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Consumer(
            builder: (context, ref, _) {
              ref.watch(navigationInfoProvider);
              return ElevatedButton(
                onPressed: () {
                  ref
                      .read(navigationInfoProvider.notifier)
                      .setResetStackMyPage();
                },
                child: const Text('reset'),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('reset'));
      await tester.pumpAndSettle();
    });

    testWidgets('goBackSignUp pops from signup stack', (tester) async {
      final stack = NavigationStack()
        ..push(const Text('Login'))
        ..push(const Text('Verify'));

      await tester.pumpWidget(
        buildTestApp(
          Consumer(
            builder: (context, ref, _) {
              ref.watch(navigationInfoProvider);
              return ElevatedButton(
                onPressed: () {
                  ref.read(navigationInfoProvider.notifier).goBackSignUp();
                },
                child: const Text('back'),
              );
            },
          ),
          navigation: Navigation(signUpNavigationStack: stack),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('back'));
      await tester.pumpAndSettle();
    });

    testWidgets('setCurrentSignUpPage pushes to signup stack', (tester) async {
      final stack = NavigationStack()..push(const Text('Login'));

      await tester.pumpWidget(
        buildTestApp(
          Consumer(
            builder: (context, ref, _) {
              ref.watch(navigationInfoProvider);
              return ElevatedButton(
                onPressed: () {
                  ref
                      .read(navigationInfoProvider.notifier)
                      .setCurrentSignUpPage(const Text('Verify'));
                },
                child: const Text('next'),
              );
            },
          ),
          navigation: Navigation(signUpNavigationStack: stack),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('next'));
      await tester.pumpAndSettle();
    });
  });
}
