import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/common/banner.dart';
import 'package:picnic_lib/data/models/community/post.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/presentation/common/avatar_container.dart';
import 'package:picnic_lib/presentation/pages/community/community_home_page.dart';
import 'package:picnic_lib/presentation/providers/banner_list_provider.dart';
import 'package:picnic_lib/presentation/providers/community/post_provider.dart';
import 'package:picnic_lib/presentation/providers/community_navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/my_page/bookmarked_artists_provider.dart';
import 'package:picnic_lib/presentation/widgets/community/common/post_list_item.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../helpers/factories/artist_factory.dart';
import '../../../helpers/factories/user_factory.dart';
import '../../../helpers/load_test_fonts.dart';
import '../../../helpers/mock_supabase.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

class _NoBanners extends AsyncBannerList {
  @override
  Future<List<BannerModel>> build({required String location}) async => [];
}

class _Bookmarks extends AsyncBookmarkedArtists {
  _Bookmarks(this.load);
  final Future<List<ArtistModel>> Function() load;
  @override
  Future<List<ArtistModel>> build() => load();
}

void main() {
  setUpAll(loadTestFonts);
  setUp(() async {
    initTestColors();
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    await setupMockSupabaseWithAuth({}, userId: 'community-ui-user');
  });
  tearDown(tearDownMockSupabase);

  void mobile(WidgetTester tester) {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('post metadata and menu fit long text at 320px and 200%', (
    tester,
  ) async {
    mobile(tester);
    var menuTaps = 0;
    final post = PostModel.fromJson({
      'post_id': 'post-ui',
      'user_id': 'writer',
      'board_id': 'board-ui',
      'title': '작은 화면에서도 게시글 제목을 읽을 수 있어야 합니다',
      'view_count': 123456,
      'reply_count': 1234,
      'is_anonymous': false,
      'created_at': DateTime.now()
          .subtract(const Duration(days: 3))
          .toIso8601String(),
      'boards': {
        'board_id': 'board-ui',
        'artist_id': 1,
        'name': {'ko': '아주 긴 이름의 아티스트 자유게시판'},
        'description': '',
      },
    }).copyWith(userProfiles: UserFactory.create(nickname: '아주 긴 닉네임의 작성자입니다'));
    await tester.pumpWidget(
      buildTestApp(
        Align(
          alignment: Alignment.topCenter,
          child: PostListItem(
            post: post,
            popupMenu: IconButton(
              onPressed: () => menuTaps++,
              icon: const Icon(Icons.more_vert),
            ),
          ),
        ),
        designSize: const Size(393, 892),
        splitScreenMode: true,
        textScaler: TextScaler.linear(2),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    for (final text in [
      post.title!,
      '아주 긴 이름의 아티스트 자유게시판',
      '아주 긴 닉네임의 작성자입니다',
    ]) {
      final rect = tester.getRect(find.text(text));
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(320));
    }
    final menu = find.byIcon(Icons.more_vert);
    expect(menu.hitTestable(), findsOneWidget);
    await tester.tap(menu);
    expect(menuTaps, 1);
  });

  testWidgets('bookmarked artist labels fit below unchanged avatars at 200%', (
    tester,
  ) async {
    mobile(tester);
    final artists = [
      ArtistFactory.create(id: 1, name: {'ko': '이름이 아주 긴 아티스트 하나'}, image: ''),
      ArtistFactory.create(id: 2, name: {'ko': '아티스트 둘'}, image: ''),
      ...List.generate(
        98,
        (index) => ArtistFactory.create(
          id: index + 3,
          name: {'ko': '다른 아티스트 $index'},
          image: '',
        ),
      ),
    ];
    await tester.pumpWidget(
      buildTestApp(
        const CommunityHomePage(),
        designSize: const Size(393, 892),
        splitScreenMode: true,
        textScaler: TextScaler.linear(2),
        extraOverrides: [
          asyncBannerListProvider.overrideWith(_NoBanners.new),
          asyncBookmarkedArtistsProvider.overrideWith(
            () => _Bookmarks(() async => artists),
          ),
          postsByArtistProvider(1, 3, 1).overrideWith((ref) async => []),
          postsByArtistProvider(2, 3, 1).overrideWith((ref) async => []),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final name = find.text('이름이 아주 긴 아티스트 하나');
    expect(name, findsOneWidget);
    final target = find
        .ancestor(of: name, matching: find.byType(GestureDetector))
        .first;
    expect(
      tester.getRect(name).bottom,
      lessThanOrEqualTo(tester.getRect(target).bottom),
    );
    final avatars = tester.widgetList<ProfileImageContainer>(
      find.byType(ProfileImageContainer),
    );
    expect(
      avatars.where((avatar) => avatar.width == 54 && avatar.height == 54),
      isNotEmpty,
    );
    expect(
      avatars.length,
      lessThan(10),
      reason: 'Offscreen bookmarks must remain lazily built',
    );
    await tester.tap(find.text('아티스트 둘'));
    await tester.pump();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(CommunityHomePage)),
    );
    expect(container.read(communityStateInfoProvider).currentArtist?.id, 2);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'bookmark failure hides raw errors and retries to a genuine empty state',
    (tester) async {
      mobile(tester);
      var fail = true;
      var attempts = 0;
      await tester.pumpWidget(
        buildTestApp(
          const CommunityHomePage(),
          extraOverrides: [
            asyncBannerListProvider.overrideWith(_NoBanners.new),
            asyncBookmarkedArtistsProvider.overrideWith(
              () => _Bookmarks(() async {
                attempts++;
                if (fail) throw StateError('private transport detail');
                return [];
              }),
            ),
          ],
          retry: (_, _) => null,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('private transport detail'), findsNothing);
      final retry = find.descendant(
        of: find.byKey(const ValueKey('community-bookmarks-retry')),
        matching: find.byWidgetPredicate(
          (widget) => widget is ButtonStyleButton,
        ),
      );
      expect(retry, findsOneWidget);
      final before = attempts;
      fail = false;
      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(attempts, greaterThan(before));
      expect(
        find.byKey(const ValueKey('community-bookmarks-empty')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
