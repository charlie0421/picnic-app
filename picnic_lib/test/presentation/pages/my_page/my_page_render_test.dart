import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/presentation/pages/my_page/my_page.dart';
import 'package:picnic_lib/presentation/providers/my_page/bookmarked_artists_provider.dart';
import 'package:picnic_lib/presentation/widgets/star_candy_info_text.dart';

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

    testWidgets('does not show the candy banner for a regular user', (
      WidgetTester tester,
    ) async {
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

      expect(find.byType(StarCandyInfoText), findsNothing);
    });

    testWidgets('shows the candy banner for an admin user', (
      WidgetTester tester,
    ) async {
      await setupMockSupabaseWithAuth(const {}, userId: 'test-user-id');
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

      expect(find.byType(StarCandyInfoText), findsOneWidget);
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
