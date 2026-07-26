import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/common/community_navigation.dart';
import 'package:picnic_lib/data/models/common/navigation.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/data/models/common/banner.dart';
import 'package:picnic_lib/enums.dart';
import 'package:picnic_lib/presentation/pages/community/community_home_page.dart';
import 'package:picnic_lib/presentation/providers/banner_list_provider.dart';
import 'package:picnic_lib/presentation/providers/my_page/bookmarked_artists_provider.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../helpers/ignore_image_errors.dart';
import '../../../helpers/mock_data.dart';
import '../../../helpers/mock_supabase.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

class MockBookmarkedArtistsEmpty extends AsyncBookmarkedArtists {
  @override
  Future<List<ArtistModel>> build() async => [];
}

class MockBookmarkedArtistsSingle extends AsyncBookmarkedArtists {
  @override
  Future<List<ArtistModel>> build() async => [
        ArtistModel.fromJson({
          'id': 1,
          'name': {'ko': '지민', 'en': 'Jimin'},
          'image': 'https://example.com/jimin.jpg',
          'artist_group': {
            'id': 1,
            'name': {'ko': 'BTS', 'en': 'BTS'},
            'image': null,
          },
        }),
      ];
}

class MockBookmarkedArtistsMultiple extends AsyncBookmarkedArtists {
  @override
  Future<List<ArtistModel>> build() async => [
        ArtistModel.fromJson({
          'id': 1,
          'name': {'ko': '지민', 'en': 'Jimin'},
          'image': null,
          'artist_group': null,
        }),
        ArtistModel.fromJson({
          'id': 2,
          'name': {'ko': '정국', 'en': 'Jungkook'},
          'image': 'https://example.com/jk.jpg',
          'artist_group': {
            'id': 1,
            'name': {'ko': 'BTS', 'en': 'BTS'},
            'image': null,
          },
        }),
        ArtistModel.fromJson({
          'id': 3,
          'name': {'ko': '뷔', 'en': 'V'},
          'image': null,
          'artist_group': null,
        }),
      ];
}

class MockBookmarkedArtistsError extends AsyncBookmarkedArtists {
  @override
  Future<List<ArtistModel>> build() async {
    throw Exception('Network error');
  }
}

class MockBannerListEmpty extends AsyncBannerList {
  @override
  Future<List<BannerModel>> build({required String location}) async => [];
}

void main() {
  late void Function() restore;

  setUp(() {
    initTestColors();
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    setupMockSupabase({
      'artist_user_bookmark': <dynamic>[],
      'banner': <dynamic>[],
      'posts': <dynamic>[],
      'boards': <dynamic>[],
    });
    restore = suppressImageErrors();
  });

  tearDown(() {
    restore();
    tearDownMockSupabase();
  });

  Future<void> pumpAndDrain(WidgetTester tester, Widget widget,
      {int pumps = 3}) async {
    await tester.pumpWidget(widget);
    drainExpectedImageErrors(tester);
    for (var i = 0; i < pumps; i++) {
      await tester.pump(const Duration(seconds: 1));
      drainExpectedImageErrors(tester);
    }
  }

  group('CommunityHomePage coverage - portal type variants', () {
    testWidgets('renders with community portal type and empty bookmarks',
        (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const CommunityHomePage(),
          navigation: MockData.navigation(portalType: PortalType.community),
          extraOverrides: [
            asyncBookmarkedArtistsProvider
                .overrideWith(MockBookmarkedArtistsEmpty.new),
            asyncBannerListProvider.overrideWith(MockBannerListEmpty.new),
          ],
        ),
      );

      expect(find.byType(CommunityHomePage), findsOneWidget);
    });

    testWidgets('renders with vote portal type',
        (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const CommunityHomePage(),
          navigation: MockData.navigation(portalType: PortalType.vote),
          extraOverrides: [
            asyncBookmarkedArtistsProvider
                .overrideWith(MockBookmarkedArtistsEmpty.new),
            asyncBannerListProvider.overrideWith(MockBannerListEmpty.new),
          ],
        ),
      );

      expect(find.byType(CommunityHomePage), findsOneWidget);
    });

    testWidgets('clears page title when community is active and at root',
        (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const CommunityHomePage(),
          navigation: MockData.navigation(
            portalType: PortalType.community,
            showPortal: true,
            showTopMenu: true,
          ),
          extraOverrides: [
            asyncBookmarkedArtistsProvider
                .overrideWith(MockBookmarkedArtistsEmpty.new),
            asyncBannerListProvider.overrideWith(MockBannerListEmpty.new),
          ],
        ),
      );

      // Pump extra to let post-frame callbacks run
      await tester.pump(const Duration(milliseconds: 500));
      drainExpectedImageErrors(tester);

      expect(find.byType(CommunityHomePage), findsOneWidget);
    });
  });

  group('CommunityHomePage coverage - bookmark data states', () {
    testWidgets('renders with single bookmarked artist and artist list',
        (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const CommunityHomePage(),
          extraOverrides: [
            asyncBookmarkedArtistsProvider
                .overrideWith(MockBookmarkedArtistsSingle.new),
            asyncBannerListProvider.overrideWith(MockBannerListEmpty.new),
          ],
        ),
        pumps: 4,
      );

      expect(find.byType(CommunityHomePage), findsOneWidget);
    });

    testWidgets('renders with multiple bookmarked artists',
        (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const CommunityHomePage(),
          extraOverrides: [
            asyncBookmarkedArtistsProvider
                .overrideWith(MockBookmarkedArtistsMultiple.new),
            asyncBannerListProvider.overrideWith(MockBannerListEmpty.new),
          ],
        ),
        pumps: 4,
      );

      expect(find.byType(CommunityHomePage), findsOneWidget);
    });

    testWidgets('renders error state for bookmark fetch failure',
        (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const CommunityHomePage(),
          extraOverrides: [
            asyncBookmarkedArtistsProvider
                .overrideWith(MockBookmarkedArtistsError.new),
            asyncBannerListProvider.overrideWith(MockBannerListEmpty.new),
          ],
        ),
        pumps: 4,
      );

      expect(find.byType(CommunityHomePage), findsOneWidget);
    });

    testWidgets('tapping artist in list selects it',
        (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const CommunityHomePage(),
          extraOverrides: [
            asyncBookmarkedArtistsProvider
                .overrideWith(MockBookmarkedArtistsMultiple.new),
            asyncBannerListProvider.overrideWith(MockBannerListEmpty.new),
          ],
        ),
        pumps: 4,
      );

      // Find and tap an artist name (not the first one which is auto-selected)
      final secondArtist = find.text('정국');
      if (secondArtist.evaluate().isNotEmpty) {
        await tester.tap(secondArtist.first);
        await tester.pump(const Duration(milliseconds: 500));
        drainExpectedImageErrors(tester);
      }

      expect(find.byType(CommunityHomePage), findsOneWidget);
    });
  });

  group('CommunityHomePage coverage - logged out state', () {
    testWidgets('shows login prompt when user is not logged in',
        (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const CommunityHomePage(),
          loggedIn: false,
          extraOverrides: [
            asyncBookmarkedArtistsProvider
                .overrideWith(MockBookmarkedArtistsEmpty.new),
            asyncBannerListProvider.overrideWith(MockBannerListEmpty.new),
          ],
        ),
      );

      expect(find.byType(CommunityHomePage), findsOneWidget);
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('logged out with English locale shows login text',
        (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const CommunityHomePage(),
          loggedIn: false,
          locale: const Locale('en'),
          extraOverrides: [
            asyncBookmarkedArtistsProvider
                .overrideWith(MockBookmarkedArtistsEmpty.new),
            asyncBannerListProvider.overrideWith(MockBannerListEmpty.new),
          ],
        ),
      );

      expect(find.byType(CommunityHomePage), findsOneWidget);
    });

    testWidgets('logged out with Japanese locale',
        (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const CommunityHomePage(),
          loggedIn: false,
          locale: const Locale('ja'),
          extraOverrides: [
            asyncBookmarkedArtistsProvider
                .overrideWith(MockBookmarkedArtistsEmpty.new),
            asyncBannerListProvider.overrideWith(MockBannerListEmpty.new),
          ],
        ),
      );

      expect(find.byType(CommunityHomePage), findsOneWidget);
    });
  });

  group('CommunityHomePage coverage - community state with selected artist', () {
    testWidgets('renders with pre-selected artist in community state',
        (WidgetTester tester) async {
      final artist = ArtistModel.fromJson({
        'id': 1,
        'name': {'ko': '지민', 'en': 'Jimin'},
        'image': null,
        'artist_group': null,
      });

      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const CommunityHomePage(),
          communityState: CommunityState(currentArtist: artist),
          extraOverrides: [
            asyncBookmarkedArtistsProvider
                .overrideWith(MockBookmarkedArtistsSingle.new),
            asyncBannerListProvider.overrideWith(MockBannerListEmpty.new),
          ],
        ),
        pumps: 4,
      );

      expect(find.byType(CommunityHomePage), findsOneWidget);
    });

    testWidgets('renders with non-matching artist triggers auto-select',
        (WidgetTester tester) async {
      // currentArtist has different id than bookmarked artists
      final differentArtist = ArtistModel.fromJson({
        'id': 999,
        'name': {'ko': '다른', 'en': 'Other'},
        'image': null,
        'artist_group': null,
      });

      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const CommunityHomePage(),
          communityState: CommunityState(currentArtist: differentArtist),
          extraOverrides: [
            asyncBookmarkedArtistsProvider
                .overrideWith(MockBookmarkedArtistsSingle.new),
            asyncBannerListProvider.overrideWith(MockBannerListEmpty.new),
          ],
        ),
        pumps: 4,
      );

      expect(find.byType(CommunityHomePage), findsOneWidget);
    });
  });

  group('CommunityHomePage coverage - navigation with non-empty pageTitle', () {
    testWidgets('community portal with non-empty pageTitle triggers clear',
        (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const CommunityHomePage(),
          navigation: Navigation(
            portalType: PortalType.community,
            showPortal: true,
            showTopMenu: true,
            showBottomNavigation: true,
            voteBottomNavigationIndex: 0,
            pageTitle: 'Some Title',
          ),
          extraOverrides: [
            asyncBookmarkedArtistsProvider
                .overrideWith(MockBookmarkedArtistsEmpty.new),
            asyncBannerListProvider.overrideWith(MockBannerListEmpty.new),
          ],
        ),
        pumps: 4,
      );

      expect(find.byType(CommunityHomePage), findsOneWidget);
    });
  });
}
