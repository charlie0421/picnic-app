import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/presentation/common/common_banner.dart';
import 'package:picnic_lib/presentation/pages/community/community_home_page.dart';
import 'package:picnic_lib/presentation/providers/banner_list_provider.dart';
import 'package:picnic_lib/presentation/providers/my_page/bookmarked_artists_provider.dart';
import 'package:picnic_lib/data/models/common/banner.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../helpers/ignore_image_errors.dart';
import '../../../helpers/mock_supabase.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

class MockBookmarkedArtistsEmpty extends AsyncBookmarkedArtists {
  @override
  Future<List<ArtistModel>> build() async => [];
}

class MockBookmarkedArtistsWithData extends AsyncBookmarkedArtists {
  @override
  Future<List<ArtistModel>> build() async => [
        ArtistModel.fromJson({
          'id': 1,
          'name': {'ko': '아티스트1', 'en': 'Artist1'},
          'image': 'https://example.com/artist1.jpg',
          'artist_group': null,
        }),
        ArtistModel.fromJson({
          'id': 2,
          'name': {'ko': '아티스트2', 'en': 'Artist2'},
          'image': 'https://example.com/artist2.jpg',
          'artist_group': null,
        }),
      ];
}

class MockBookmarkedArtistsError extends AsyncBookmarkedArtists {
  @override
  Future<List<ArtistModel>> build() async {
    throw Exception('Bookmark load error');
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
    });
    restore = suppressImageErrors();
  });

  tearDown(() {
    restore();
    tearDownMockSupabase();
  });

  Future<void> pumpAndDrain(WidgetTester tester, Widget widget) async {
    // 첫 프레임부터 필터가 걸려 있어야 한다 — 그래야 그 프레임의 에러가
    // FlutterErrorDetails 째로 잡혀서, 진짜 결함일 때 "어느 위젯이 원인인지"까지
    // 보고된다. raw pumpWidget 으로 먼저 그리면 그 정보가 사라진다.
    await pumpWidgetAndIgnoreErrors(tester, widget);
    await tester.pump(const Duration(seconds: 1));
    drainExpectedImageErrors(tester);
  }

  group('CommunityHomePage render', () {
    testWidgets('renders logged-out state with login prompt',
        (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const CommunityHomePage(),
          loggedIn: false,
          extraOverrides: [
            asyncBookmarkedArtistsProvider
                .overrideWith(MockBookmarkedArtistsEmpty.new),
            asyncBannerListProvider
                .overrideWith(MockBannerListEmpty.new),
          ],
        ),
      );

      expect(find.byType(CommunityHomePage), findsOneWidget);
      // Logged out should show login text
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('renders logged-out with empty bookmarks',
        (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const CommunityHomePage(),
          extraOverrides: [
            asyncBookmarkedArtistsProvider
                .overrideWith(MockBookmarkedArtistsEmpty.new),
            asyncBannerListProvider
                .overrideWith(MockBannerListEmpty.new),
          ],
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      drainExpectedImageErrors(tester);

      expect(find.byType(CommunityHomePage), findsOneWidget);
      // Not logged in, shows login prompt instead of bookmarks
      expect(find.text('My ARTISTS'), findsOneWidget);
    });

    testWidgets('renders with bookmarked artists provider override',
        (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const CommunityHomePage(),
          extraOverrides: [
            asyncBookmarkedArtistsProvider
                .overrideWith(MockBookmarkedArtistsWithData.new),
            asyncBannerListProvider
                .overrideWith(MockBannerListEmpty.new),
          ],
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      drainExpectedImageErrors(tester);

      expect(find.byType(CommunityHomePage), findsOneWidget);
    });

    testWidgets('renders error state for bookmarks',
        (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const CommunityHomePage(),
          extraOverrides: [
            asyncBookmarkedArtistsProvider
                .overrideWith(MockBookmarkedArtistsError.new),
            asyncBannerListProvider
                .overrideWith(MockBannerListEmpty.new),
          ],
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      drainExpectedImageErrors(tester);

      expect(find.byType(CommunityHomePage), findsOneWidget);
    });

    testWidgets('renders with Korean locale', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const CommunityHomePage(),
          locale: const Locale('ko'),
          extraOverrides: [
            asyncBookmarkedArtistsProvider
                .overrideWith(MockBookmarkedArtistsEmpty.new),
            asyncBannerListProvider
                .overrideWith(MockBannerListEmpty.new),
          ],
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      drainExpectedImageErrors(tester);

      expect(find.byType(CommunityHomePage), findsOneWidget);
    });

    testWidgets('renders with English locale', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const CommunityHomePage(),
          locale: const Locale('en'),
          extraOverrides: [
            asyncBookmarkedArtistsProvider
                .overrideWith(MockBookmarkedArtistsEmpty.new),
            asyncBannerListProvider
                .overrideWith(MockBannerListEmpty.new),
          ],
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      drainExpectedImageErrors(tester);

      expect(find.byType(CommunityHomePage), findsOneWidget);
    });
  });
}
