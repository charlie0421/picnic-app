import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/utils/app_builder.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/navigator_key.dart';
import 'package:picnic_lib/ui/fixed_width_layout.dart';

import 'package:picnic_lib/presentation/providers/active_featured_votes_provider.dart';
import 'factories/vote_factory.dart';
import 'factories/artist_factory.dart';
import 'host_app_asset_bundle.dart';
import 'mock_providers.dart';
import 'mock_data.dart';

/// Production app scaling and navigation, with local providers and no startup.
/// Device tests use the host app's real asset bundle.
Widget buildFoldableTestApp(
  Widget page, {
  double textScale = 1,
  Locale locale = const Locale('ko'),
  List<dynamic> overrides = const [],
  bool deviceAssets = false,
}) => ProviderScope(
  retry: (_, _) => null,
  overrides: [
    ...defaultProviderOverrides(
      setting: MockData.setting(language: locale.languageCode),
    ),
    ...overrides,
  ],
  child: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: AppBuilder.buildApp(
        navigatorKey: navigatorKey,
        scaffoldKey: GlobalKey<ScaffoldMessengerState>(),
        routes: const {},
        title: 'Picnic foldable screen test',
        theme: ThemeData(),
        home: FixedWidthLayout(
          child: Scaffold(
            appBar: AppBar(title: const Text('PICNIC')),
            body: deviceAssets
                ? page
                : DefaultAssetBundle(bundle: hostAppAssetBundle, child: page),
          ),
        ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
      ),
    ),
  ),
);

Map<String, dynamic> foldablePostFixture() => {
  'post_id': 'foldable-post',
  'user_id': 'test-user-id',
  'board_id': 'board-1',
  'title': '폴더블 화면에서 읽는 게시물',
  'content': [
    {'insert': '접기 전환 후에도 게시물과 댓글 입력을 확인합니다.\n'},
  ],
  'view_count': 12345,
  'reply_count': 0,
  'is_hidden': false,
  'is_anonymous': false,
  'is_scraped': false,
  'created_at': '2026-10-28T10:00:00.000Z',
  'updated_at': '2026-10-28T10:00:00.000Z',
  'deleted_at': null,
  'board': {
    'board_id': 'board-1',
    'name': {'ko': '자유게시판'},
    'artist_id': 1,
  },
  'user_profiles': {
    'nickname': '테스트 사용자',
    'avatar_url': null,
    'created_at': '2026-01-01T00:00:00.000Z',
    'updated_at': '2026-01-01T00:00:00.000Z',
  },
  'post_reports': null,
  'post_scraps': null,
};

class FoldableFeaturedVotes extends AsyncActiveFeaturedVotes {
  @override
  Future<List<FeaturedVoteEntry>> build() async => [
    for (var i = 1; i <= 2; i++)
      FeaturedVoteEntry(
        vote: VoteFactory.create(
          id: i,
          title: {'ko': '폴더블 테스트 투표 $i'},
          voteItem: [
            VoteItemFactory.create(
              id: i,
              artist: ArtistFactory.create(id: i),
            ),
          ],
        ),
        totalVotes: 2000,
      ),
  ];
}

class FoldableLoadingVotes extends AsyncActiveFeaturedVotes {
  @override
  Future<List<FeaturedVoteEntry>> build() =>
      Completer<List<FeaturedVoteEntry>>().future;
}

Map<String, dynamic> foldableScreenFixtures({
  String imageUrl = 'https://fixture.invalid/banner.png',
}) => {
  'banner': [
    {
      'id': 9029,
      'title': {'ko': '폴더블 검증 배너'},
      'thumbnail': imageUrl,
      'image': {'ko': imageUrl, 'en': imageUrl},
      'duration': 30000,
      'link': null,
    },
  ],
  'reward': [],
  'vote': [],
  'media': [],
  'posts': [foldablePostFixture()],
  'comments': [],
  'user_blocks': [],
};

void resetFoldableTestPlugins() {
  SharedPreferences.setMockInitialValues({});
  VisibilityDetectorController.instance.updateInterval = Duration.zero;
}
