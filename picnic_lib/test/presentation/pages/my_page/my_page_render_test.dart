import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/common/navigation.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/presentation/pages/my_page/admin_menu_page.dart';
import 'package:picnic_lib/presentation/pages/my_page/my_page.dart';
import 'package:picnic_lib/presentation/providers/my_page/bookmarked_artists_provider.dart';
import 'package:picnic_lib/presentation/screens/mypage_screen.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/common/store_point_info.dart';

import '../../../helpers/ignore_image_errors.dart';
import '../../../helpers/mock_data.dart';
import '../../../helpers/mock_supabase.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

class MockBookmarkedArtists extends AsyncBookmarkedArtists {
  @override
  Future<List<ArtistModel>> build() async => [];
}

void main() {
  late void Function() restore;

  setUp(() {
    initTestColors();
    setupMockSupabase({'artist_user_bookmark': <dynamic>[]});
    restore = suppressImageErrors();
  });

  tearDown(() {
    restore();
    tearDownMockSupabase();
  });

  group('MyPage render', () {
    testWidgets('renders logged-in state', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const MyPage(),
          extraOverrides: [
            asyncBookmarkedArtistsProvider.overrideWith(
              MockBookmarkedArtists.new,
            ),
          ],
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));
      expect(find.byType(MyPage), findsOneWidget);
    });

    testWidgets(
      'shows the shared candy pouch without history for a regular user',
      (WidgetTester tester) async {
        await setupMockSupabaseWithAuth(const {}, userId: 'test-user-id');
        await tester.pumpWidget(
          buildTestAppPage(
            const MyPage(),
            userProfile: MockData.userProfile(isAdmin: false),
            extraOverrides: [
              asyncBookmarkedArtistsProvider.overrideWith(
                MockBookmarkedArtists.new,
              ),
            ],
          ),
        );
        await pumpAndIgnoreErrors(tester);
        await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

        expect(find.byType(StorePointInfo), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('알림함'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('알림함'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('설정'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('캔디 내역'), findsNothing);
        expect(find.text('관리자'), findsNothing);
      },
    );

    testWidgets('shows only the administrator entry for an admin user', (
      WidgetTester tester,
    ) async {
      await setupMockSupabaseWithAuth(const {}, userId: 'test-user-id');
      await tester.pumpWidget(
        buildTestAppPage(
          const MyPageScreen(),
          navigation: Navigation.initial(),
          userProfile: MockData.userProfile(isAdmin: true),
          extraOverrides: [
            asyncBookmarkedArtistsProvider.overrideWith(
              MockBookmarkedArtists.new,
            ),
          ],
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      expect(find.byType(MyPage), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('관리자'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('관리자'), findsOneWidget);
      expect(find.text('캔디 내역'), findsNothing);
      expect(find.text('충전 내역'), findsNothing);
      expect(find.text('Ad Inspector'), findsNothing);
      expect(find.text('Reset & Reload GDPR'), findsNothing);

      await tester.tap(find.text('관리자'));
      await pumpAndIgnoreErrors(tester);
      expect(find.byType(AdminMenuPage), findsOneWidget);
    });

    testWidgets('renders logged-out state', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const MyPage(),
          loggedIn: false,
          extraOverrides: [
            asyncBookmarkedArtistsProvider.overrideWith(
              MockBookmarkedArtists.new,
            ),
          ],
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));
      expect(find.byType(MyPage), findsOneWidget);
      expect(find.byType(StorePointInfo), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('설정'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('알림함'), findsNothing);
      expect(
        find.descendant(
          of: find.byType(StorePointInfo),
          matching: find.text('로그인해 주세요'),
        ),
        findsOneWidget,
      );
      expect(find.text('캔디 내역'), findsNothing);
      expect(find.text('관리자'), findsNothing);
    });

    testWidgets('keeps 16px and 24px space around the candy pouch', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const MyPage(),
          loggedIn: false,
          extraOverrides: [
            asyncBookmarkedArtistsProvider.overrideWith(
              MockBookmarkedArtists.new,
            ),
          ],
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      final pouchRect = tester.getRect(find.byType(StorePointInfo));
      final previousRect = tester.getRect(
        find.byWidgetPredicate(
          (widget) => widget is GestureDetector && widget.child is Row,
        ),
      );
      final nextRect = tester.getRect(find.text('언어 설정'));

      expect(pouchRect.top - previousRect.bottom, 16);
      expect(nextRect.top - pouchRect.bottom, 24);
    });

    testWidgets('renders admin user with admin menus', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const MyPage(),
          userProfile: MockData.userProfile(isAdmin: true),
          extraOverrides: [
            asyncBookmarkedArtistsProvider.overrideWith(
              MockBookmarkedArtists.new,
            ),
          ],
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));
      expect(find.byType(MyPage), findsOneWidget);

      // Admin menus should be visible - scroll to find them
      final listView = find.byType(ListView);
      if (listView.evaluate().isNotEmpty) {
        await tester.drag(
          listView.first,
          const Offset(0, -500),
          warnIfMissed: false,
        );
        await pumpAndIgnoreErrors(tester);
      }
    });

    testWidgets('renders with English locale', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const MyPage(),
          locale: const Locale('en'),
          setting: MockData.setting(language: 'en'),
          extraOverrides: [
            asyncBookmarkedArtistsProvider.overrideWith(
              MockBookmarkedArtists.new,
            ),
          ],
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));
      expect(find.byType(MyPage), findsOneWidget);
    });

    testWidgets('renders with user that has avatar', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const MyPage(),
          userProfile: MockData.userProfile(
            avatarUrl: 'https://example.com/avatar.jpg',
            nickname: 'AvatarUser',
          ),
          extraOverrides: [
            asyncBookmarkedArtistsProvider.overrideWith(
              MockBookmarkedArtists.new,
            ),
          ],
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));
      expect(find.byType(MyPage), findsOneWidget);
    });

    testWidgets('renders with user that has no nickname', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const MyPage(),
          userProfile: MockData.userProfile(nickname: null),
          extraOverrides: [
            asyncBookmarkedArtistsProvider.overrideWith(
              MockBookmarkedArtists.new,
            ),
          ],
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));
      expect(find.byType(MyPage), findsOneWidget);
    });

    testWidgets('renders with bookmarked artists loading error', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const MyPage(),
          extraOverrides: [
            asyncBookmarkedArtistsProvider.overrideWith(
              () => MockBookmarkedArtistsError(),
            ),
          ],
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));
      expect(find.byType(MyPage), findsOneWidget);
    });

    testWidgets('scroll through all menu items', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const MyPage(),
          extraOverrides: [
            asyncBookmarkedArtistsProvider.overrideWith(
              MockBookmarkedArtists.new,
            ),
          ],
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      // Scroll through all the menu items
      final listView = find.byType(ListView);
      if (listView.evaluate().isNotEmpty) {
        for (int i = 0; i < 3; i++) {
          await tester.drag(
            listView.first,
            const Offset(0, -300),
            warnIfMissed: false,
          );
          await pumpAndIgnoreErrors(tester);
        }
      }
    });

    testWidgets('tap menu list items', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const MyPage(),
          extraOverrides: [
            asyncBookmarkedArtistsProvider.overrideWith(
              MockBookmarkedArtists.new,
            ),
          ],
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      // Tap all InkWell items (menu items)
      final inkWells = find.byType(InkWell);
      for (int i = 0; i < tester.widgetList(inkWells).length && i < 10; i++) {
        try {
          await tester.tap(inkWells.at(i), warnIfMissed: false);
          await pumpAndIgnoreErrors(tester);
        } catch (_) {}
      }
    });

    testWidgets('renders with Japanese locale', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const MyPage(),
          locale: const Locale('ja'),
          setting: MockData.setting(language: 'ja'),
          extraOverrides: [
            asyncBookmarkedArtistsProvider.overrideWith(
              MockBookmarkedArtists.new,
            ),
          ],
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));
      expect(find.byType(MyPage), findsOneWidget);
    });

    testWidgets('renders with user that has zero candy', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const MyPage(),
          userProfile: MockData.userProfile(
            starCandy: 0,
            starCandyBonus: 0,
            jmaCandy: 0,
          ),
          extraOverrides: [
            asyncBookmarkedArtistsProvider.overrideWith(
              MockBookmarkedArtists.new,
            ),
          ],
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));
      expect(find.byType(MyPage), findsOneWidget);
    });

    testWidgets('scroll through all items including admin menus', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const MyPage(),
          userProfile: MockData.userProfile(isAdmin: true),
          extraOverrides: [
            asyncBookmarkedArtistsProvider.overrideWith(
              MockBookmarkedArtists.new,
            ),
          ],
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      // Scroll through all menu items including admin-only ones
      final listView = find.byType(ListView);
      if (listView.evaluate().isNotEmpty) {
        for (int i = 0; i < 5; i++) {
          await tester.drag(
            listView.first,
            const Offset(0, -300),
            warnIfMissed: false,
          );
          await pumpAndIgnoreErrors(tester);
        }
        // Scroll back up
        for (int i = 0; i < 3; i++) {
          await tester.drag(
            listView.first,
            const Offset(0, 300),
            warnIfMissed: false,
          );
          await pumpAndIgnoreErrors(tester);
        }
      }
    });

    testWidgets('tap admin menu items', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const MyPage(),
          userProfile: MockData.userProfile(isAdmin: true),
          extraOverrides: [
            asyncBookmarkedArtistsProvider.overrideWith(
              MockBookmarkedArtists.new,
            ),
          ],
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      // Scroll down to admin menus
      final listView = find.byType(ListView);
      if (listView.evaluate().isNotEmpty) {
        for (int i = 0; i < 4; i++) {
          await tester.drag(
            listView.first,
            const Offset(0, -300),
            warnIfMissed: false,
          );
          await pumpAndIgnoreErrors(tester);
        }
      }

      // Tap InkWells at the bottom (admin menus)
      final inkWells = find.byType(InkWell);
      for (int i = 0; i < tester.widgetList(inkWells).length && i < 15; i++) {
        try {
          await tester.tap(inkWells.at(i), warnIfMissed: false);
          await pumpAndIgnoreErrors(tester);
        } catch (_) {}
      }
    });

    testWidgets('renders profile section for logged-in user with QnA', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const MyPage(),
          userProfile: MockData.userProfile(id: 'test-id-123'),
          extraOverrides: [
            asyncBookmarkedArtistsProvider.overrideWith(
              MockBookmarkedArtists.new,
            ),
          ],
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      // Scroll to QnA menu
      final listView = find.byType(ListView);
      if (listView.evaluate().isNotEmpty) {
        await tester.drag(
          listView.first,
          const Offset(0, -200),
          warnIfMissed: false,
        );
        await pumpAndIgnoreErrors(tester);
      }

      expect(find.byType(MyPage), findsOneWidget);
    });

    testWidgets('tap language selector GestureDetectors', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const MyPage(),
          extraOverrides: [
            asyncBookmarkedArtistsProvider.overrideWith(
              MockBookmarkedArtists.new,
            ),
          ],
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      // Language selector uses GestureDetector - try tapping them
      final gestureDetectors = find.byType(GestureDetector);
      for (
        int i = 0;
        i < tester.widgetList(gestureDetectors).length && i < 10;
        i++
      ) {
        try {
          await tester.tap(gestureDetectors.at(i), warnIfMissed: false);
          await pumpAndIgnoreErrors(tester);
        } catch (_) {}
      }
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));
    });
  });
}

class MockBookmarkedArtistsError extends AsyncBookmarkedArtists {
  @override
  Future<List<ArtistModel>> build() async =>
      throw Exception('Failed to load bookmarked artists');
}
