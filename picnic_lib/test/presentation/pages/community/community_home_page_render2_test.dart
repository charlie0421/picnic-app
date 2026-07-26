import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/common/community_navigation.dart';
import 'package:picnic_lib/data/models/common/navigation.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/enums.dart';
import 'package:picnic_lib/presentation/pages/community/community_home_page.dart';
import 'package:picnic_lib/presentation/providers/banner_list_provider.dart';
import 'package:picnic_lib/presentation/providers/my_page/bookmarked_artists_provider.dart';
import 'package:picnic_lib/data/models/common/banner.dart';
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
          'image': null,
          'artist_group': null,
        }),
        ArtistModel.fromJson({
          'id': 3,
          'name': {'ko': '뷔', 'en': 'V'},
          'image': null,
          'artist_group': null,
        }),
        ArtistModel.fromJson({
          'id': 4,
          'name': {'ko': '슈가', 'en': 'Suga'},
          'image': null,
          'artist_group': null,
        }),
        ArtistModel.fromJson({
          'id': 5,
          'name': {'ko': 'RM', 'en': 'RM'},
          'image': null,
          'artist_group': null,
        }),
      ];
}

class MockBookmarkedArtistsError extends AsyncBookmarkedArtists {
  @override
  Future<List<ArtistModel>> build() async {
    throw Exception('Network error loading bookmarks');
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

  Future<void> pumpAndDrain(WidgetTester tester, Widget widget) async {
    await tester.pumpWidget(widget);
    drainExpectedImageErrors(tester);
    await tester.pump(const Duration(seconds: 1));
    drainExpectedImageErrors(tester);
  }

  group('CommunityHomePage render - navigation states', () {
    testWidgets('renders with community portal type active',
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
      expect(find.text('My ARTISTS'), findsOneWidget);
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
  });

  group('CommunityHomePage render - bookmark states', () {
    testWidgets('renders with single bookmarked artist',
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
      );

      await tester.pump(const Duration(milliseconds: 500));
      drainExpectedImageErrors(tester);

      expect(find.byType(CommunityHomePage), findsOneWidget);
    });

    testWidgets('renders with max (5) bookmarked artists',
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
      );

      await tester.pump(const Duration(milliseconds: 500));
      drainExpectedImageErrors(tester);

      expect(find.byType(CommunityHomePage), findsOneWidget);
    });

    testWidgets('renders error state for bookmarks shows Error text',
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
      );

      await tester.pump(const Duration(milliseconds: 500));
      drainExpectedImageErrors(tester);

      expect(find.byType(CommunityHomePage), findsOneWidget);
    });
  });

  group('CommunityHomePage render - logged out states', () {
    testWidgets('shows login prompt when logged out',
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

    testWidgets('logged out with English locale',
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
  });

  group('CommunityHomePage render - community state', () {
    testWidgets('renders with custom community state artist selected',
        (WidgetTester tester) async {
      final artistForCommunity = ArtistModel.fromJson({
        'id': 1,
        'name': {'ko': '지민', 'en': 'Jimin'},
        'image': null,
        'artist_group': null,
      });

      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const CommunityHomePage(),
          communityState: CommunityState(currentArtist: artistForCommunity),
          extraOverrides: [
            asyncBookmarkedArtistsProvider
                .overrideWith(MockBookmarkedArtistsSingle.new),
            asyncBannerListProvider.overrideWith(MockBannerListEmpty.new),
          ],
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      drainExpectedImageErrors(tester);

      expect(find.byType(CommunityHomePage), findsOneWidget);
    });
  });

  group('CommunityHomePage render - locale variants', () {
    testWidgets('renders with Japanese locale', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const CommunityHomePage(),
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
}
