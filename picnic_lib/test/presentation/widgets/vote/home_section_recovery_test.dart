import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:picnic_lib/data/models/vote/video_info.dart';
import 'package:picnic_lib/data/models/reward.dart';
import 'package:picnic_lib/presentation/providers/active_featured_votes_provider.dart';
import 'package:picnic_lib/presentation/providers/home_view_state_provider.dart';
import 'package:picnic_lib/presentation/providers/latest_media_provider.dart';
import 'package:picnic_lib/presentation/providers/reward_list_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/home_featured_vote_carousel.dart';
import 'package:picnic_lib/presentation/widgets/vote/latest_media_section.dart';
import 'package:picnic_lib/presentation/widgets/vote/reward_list_section.dart';

import '../../../helpers/factories/artist_factory.dart';
import '../../../helpers/factories/vote_factory.dart';
import '../../../helpers/mock_supabase.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

class FailedFeaturedVotes extends AsyncActiveFeaturedVotes {
  @override
  Future<List<FeaturedVoteEntry>> build() async => throw StateError('failed');
}

class FailedLatestMedia extends AsyncLatestMedia {
  @override
  Future<List<VideoInfo>> build() async => throw StateError('failed');
}

class MutableFeaturedVotes extends AsyncActiveFeaturedVotes {
  MutableFeaturedVotes(this.initial);

  final List<FeaturedVoteEntry> initial;

  @override
  Future<List<FeaturedVoteEntry>> build() async => initial;

  void replace(List<FeaturedVoteEntry> entries) {
    state = AsyncData(entries);
  }
}

class RetryingLatestMedia extends AsyncLatestMedia {
  RetryingLatestMedia(this.load);

  final Future<List<VideoInfo>> Function() load;

  @override
  Future<List<VideoInfo>> build() => load();
}

class MutableRewards extends AsyncRewardList {
  @override
  Future<List<RewardModel>> build() async => const [
    RewardModel(id: 1, title: {'ko': '보존 리워드'}),
  ];

  void fail() =>
      state = AsyncError(StateError('refresh failed'), StackTrace.current);
}

List<FeaturedVoteEntry> _entries() => [
  for (var id = 1; id <= 2; id++)
    FeaturedVoteEntry(
      vote: VoteFactory.create(
        id: id,
        title: {'ko': '투표 $id'},
        voteItem: [
          VoteItemFactory.create(
            id: id,
            voteTotal: 10,
            artist: ArtistFactory.create(id: id),
          ),
        ],
      ),
      totalVotes: 20,
    ),
];

void main() {
  setUp(() {
    initTestColors();
    setupMockSupabase({});
    PicnicCachedNetworkImage.disableTimeoutForTest = true;
  });
  tearDown(() {
    PicnicCachedNetworkImage.disableTimeoutForTest = false;
    tearDownMockSupabase();
  });

  testWidgets('failed home sections expose scoped retry actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestApp(
        const Column(
          children: [HomeFeaturedVoteCarousel(), LatestMediaSection()],
        ),
        extraOverrides: [
          asyncActiveFeaturedVotesProvider.overrideWith(
            FailedFeaturedVotes.new,
          ),
          asyncLatestMediaProvider.overrideWith(FailedLatestMedia.new),
        ],
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const ValueKey('featured-votes-retry')), findsOneWidget);
    expect(find.byKey(const ValueKey('latest-media-retry')), findsOneWidget);
  });

  testWidgets('selected vote follows stable id through reorder and deletion', (
    tester,
  ) async {
    final entries = _entries();
    await tester.pumpWidget(
      buildTestApp(
        const HomeFeaturedVoteCarousel(),
        extraOverrides: [
          asyncActiveFeaturedVotesProvider.overrideWith(
            () => MutableFeaturedVotes(entries),
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.drag(find.byType(PageView), const Offset(-350, 0));
    await tester.pump(const Duration(milliseconds: 400));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(HomeFeaturedVoteCarousel)),
    );
    expect(container.read(homeViewStateProvider).selectedVoteId, 2);

    (container.read(asyncActiveFeaturedVotesProvider.notifier)
            as MutableFeaturedVotes)
        .replace([entries[1], entries[0]]);
    await tester.pump();
    await tester.pump();
    expect(container.read(homeViewStateProvider).selectedVoteId, 2);

    (container.read(asyncActiveFeaturedVotesProvider.notifier)
            as MutableFeaturedVotes)
        .replace([entries[0]]);
    await tester.pump();
    await tester.pump();
    expect(container.read(homeViewStateProvider).selectedVoteId, 1);
  });

  testWidgets('latest media retry replaces a first failure with real data', (
    tester,
  ) async {
    var attempts = 0;
    Future<List<VideoInfo>> load() async {
      attempts++;
      if (attempts == 1) throw StateError('first failure');
      return const [
        VideoInfo(
          id: 7,
          videoId: 'video',
          videoUrl: '',
          title: {'ko': '성공 미디어'},
          thumbnailUrl: '',
          channelTitle: '',
          channelId: '',
          channelThumbnail: '',
        ),
      ];
    }

    await tester.pumpWidget(
      buildTestApp(
        const LatestMediaSection(),
        extraOverrides: [
          asyncLatestMediaProvider.overrideWith(
            () => RetryingLatestMedia(load),
          ),
        ],
        retry: (_, _) => null,
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('latest-media-retry')),
        matching: find.byWidgetPredicate(
          (widget) => widget is ButtonStyleButton,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const ValueKey('latest_media_7')), findsOneWidget);
  });

  testWidgets('reward refresh failure keeps successful cards and adds retry', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestApp(
        const RewardListSection(),
        extraOverrides: [
          asyncRewardListProvider.overrideWith(MutableRewards.new),
        ],
        retry: (_, _) => null,
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('보존 리워드'), findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(RewardListSection)),
    );

    (container.read(asyncRewardListProvider.notifier) as MutableRewards).fail();
    await tester.pump();

    expect(find.text('보존 리워드'), findsOneWidget);
    expect(find.byKey(const ValueKey('reward-list-retry')), findsOneWidget);
  });
}
